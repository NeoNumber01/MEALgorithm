'use client'

import { useEffect, useState } from 'react'
import { getStatsForRange, getDailyStats, getUserProfile } from '@/lib/dashboard/actions'
import { generateStatisticsInsight } from '@/lib/dashboard/ai-feedback'
import { getLastDataUpdateTime } from '@/lib/cache-utils'
import DayDetailModal from './DayDetailModal'
import MealDetailModal from './MealDetailModal'

type TimeRange = '3d' | '7d' | '14d' | '30d' | '90d' | '365d' | 'custom'

interface DayData {
    date: string
    label: string
    calories: number
    protein: number
    carbs: number
    fat: number
    mealCount: number
}

interface MealTypeStats {
    breakfast: number
    lunch: number
    dinner: number
    snack: number
}

interface StatsData {
    days: DayData[]
    totals: { calories: number; protein: number; carbs: number; fat: number }
    averages: { calories: number; protein: number; carbs: number; fat: number }
    mealTypes: MealTypeStats
    summary: {
        totalDays: number
        daysWithMeals: number
        totalMeals: number
        avgMealsPerDay: string
    }
}

interface StatisticsViewProps {
    targetCalories: number
    lastUpdateTimestamp: number
}

export default function StatisticsView({ targetCalories, lastUpdateTimestamp }: StatisticsViewProps) {
    const [timeRange, setTimeRange] = useState<TimeRange>('7d')
    const [customStart, setCustomStart] = useState('')
    const [customEnd, setCustomEnd] = useState('')
    const [loading, setLoading] = useState(true)
    const [stats, setStats] = useState<StatsData | null>(null)
    const [selectedDay, setSelectedDay] = useState<{
        date: string
        label: string
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        meals: any[]
        totals: { calories: number; protein: number; carbs: number; fat: number }
    } | null>(null)
    const [dayLoading, setDayLoading] = useState(false)
    const [aiInsight, setAiInsight] = useState<string>('')
    const [insightLoading, setInsightLoading] = useState(false)
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const [selectedMeal, setSelectedMeal] = useState<any>(null)

    const timeRangeOptions: { value: TimeRange; label: string; days?: number }[] = [
        { value: '3d', label: '3 Days', days: 3 },
        { value: '7d', label: '1 Week', days: 7 },
        { value: '14d', label: '2 Weeks', days: 14 },
        { value: '30d', label: '1 Month', days: 30 },
        { value: '90d', label: '3 Months', days: 90 },
        { value: '365d', label: '1 Year', days: 365 },
        { value: 'custom', label: 'Custom' },
    ]

    useEffect(() => {
        loadStats()
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [timeRange, lastUpdateTimestamp])

    const getDateRange = () => {
        const endDt = new Date()
        endDt.setHours(23, 59, 59, 999)

        const startDt = new Date()
        startDt.setHours(0, 0, 0, 0)

        if (timeRange === 'custom') {
            if (!customStart || !customEnd) return { start: '', end: '' }
            const s = new Date(customStart)
            // Fix: Date parser treats YYYY-MM-DD as UTC, but we want local start of day
            // Or simpler: append T00:00 to force local parsing if supported, or use component parts
            // Reliable way: create date from parts
            const [sY, sM, sD] = customStart.split('-').map(Number)
            s.setFullYear(sY, sM - 1, sD)
            s.setHours(0, 0, 0, 0)

            const e = new Date(customEnd)
            const [eY, eM, eD] = customEnd.split('-').map(Number)
            e.setFullYear(eY, eM - 1, eD)
            e.setHours(23, 59, 59, 999)

            return { start: s.toISOString(), end: e.toISOString() }
        }

        const option = timeRangeOptions.find(o => o.value === timeRange)
        if (option?.days) {
            // Set start date relative to today
            startDt.setDate(endDt.getDate() - option.days + 1)
        }

        return {
            start: startDt.toISOString(),
            end: endDt.toISOString(),
        }
    }

    const loadStats = async () => {
        const { start, end } = getDateRange()
        if (!start || !end) return

        // Cache key based on range and timestamps
        const cacheKeyData = `stats_data_${timeRange}_${start}_${end}`
        const cacheKeyInsight = `stats_insight_${timeRange}_${start}_${end}`

        // Check cache validity against global last update
        const lastDbUpdate = getLastDataUpdateTime()

        try {
            const cachedDataStr = localStorage.getItem(cacheKeyData)
            const cachedInsight = localStorage.getItem(cacheKeyInsight)

            if (cachedDataStr) {
                const { data, timestamp } = JSON.parse(cachedDataStr)

                // Check if cache is newer than last DB update AND not too old (e.g. 24h)
                if (timestamp > lastDbUpdate && (Date.now() - timestamp < 86400000)) {
                    setStats(data)
                    if (cachedInsight) {
                        setAiInsight(cachedInsight)
                    }
                    setLoading(false)
                    return
                }
            }
        } catch (e) {
            console.error('Cache read error:', e)
        }

        setLoading(true)
        setAiInsight('')

        const timezoneOffset = new Date().getTimezoneOffset()

        const [result, profileResult] = await Promise.all([
            getStatsForRange(start, end, timezoneOffset),
            getUserProfile(),
        ])

        if (!('error' in result)) {
            setStats(result)

            // Save to cache with timestamp
            localStorage.setItem(cacheKeyData, JSON.stringify({
                data: result,
                timestamp: Date.now()
            }))

            // Generate AI insight after stats are loaded
            if (result.days.length > 0) {
                setInsightLoading(true)
                const currentOption = timeRangeOptions.find(o => o.value === timeRange)
                const periodLabel = currentOption?.label || 'Selected Period'

                // Calculate consistency score and streak
                const daysOnTarget = result.days.filter(d =>
                    d.calories >= targetCalories * 0.9 && d.calories <= targetCalories * 1.1
                )
                const consistencyScore = Math.round((daysOnTarget.length / result.days.length) * 100)

                let currentStreak = 0
                for (let i = result.days.length - 1; i >= 0; i--) {
                    const day = result.days[i]
                    if (day.calories >= targetCalories * 0.9 && day.calories <= targetCalories * 1.1) {
                        currentStreak++
                    } else {
                        break
                    }
                }

                const insightResult = await generateStatisticsInsight({
                    periodLabel,
                    totalDays: result.summary.totalDays,
                    daysWithMeals: result.summary.daysWithMeals,
                    totalMeals: result.summary.totalMeals,
                    avgCalories: result.averages.calories,
                    avgProtein: result.averages.protein,
                    avgCarbs: result.averages.carbs,
                    avgFat: result.averages.fat,
                    targetCalories,
                    consistencyScore,
                    currentStreak,
                    goalDescription: !('error' in profileResult) ? profileResult.profile?.goal_description : undefined,
                })

                setAiInsight(insightResult.insight)
                localStorage.setItem(cacheKeyInsight, insightResult.insight)
                setInsightLoading(false)
            }
        }
        setLoading(false)
    }

    const handleCustomApply = () => {
        if (customStart && customEnd) {
            loadStats()
        }
    }

    const handleDayClick = async (day: DayData) => {
        setDayLoading(true)
        // Construct local date range from the day key (YYYY-MM-DD)
        const [year, month, d] = day.date.split('-').map(Number)

        const startDt = new Date()
        startDt.setFullYear(year, month - 1, d)
        startDt.setHours(0, 0, 0, 0)

        const endDt = new Date()
        endDt.setFullYear(year, month - 1, d)
        endDt.setHours(23, 59, 59, 999)

        const result = await getDailyStats(startDt.toISOString(), endDt.toISOString())
        if (!('error' in result)) {
            setSelectedDay({
                date: day.date,
                label: day.label,
                meals: result.meals,
                totals: result.totals,
            })
        }
        setDayLoading(false)
    }

    const getMealTypeEmoji = (type: string) => {
        switch (type) {
            case 'breakfast': return '🌅'
            case 'lunch': return '☀️'
            case 'dinner': return '🌙'
            case 'snack': return '🍿'
            default: return '🍽️'
        }
    }

    const getMaxCalories = () => {
        if (!stats) return targetCalories
        const maxDay = Math.max(...stats.days.map(d => d.calories), 0)
        return Math.max(maxDay, targetCalories) * 1.1
    }

    // Calculate insights
    const getInsights = () => {
        if (!stats || stats.days.length === 0) return null

        const daysOnTarget = stats.days.filter(d => d.calories >= targetCalories * 0.9 && d.calories <= targetCalories * 1.1)
        const consistencyScore = Math.round((daysOnTarget.length / stats.days.length) * 100)

        // Calculate streak
        let currentStreak = 0
        for (let i = stats.days.length - 1; i >= 0; i--) {
            const day = stats.days[i]
            if (day.calories >= targetCalories * 0.9 && day.calories <= targetCalories * 1.1) {
                currentStreak++
            } else {
                break
            }
        }

        // Best and worst days
        const sortedByCalories = [...stats.days].sort((a, b) => Math.abs(a.calories - targetCalories) - Math.abs(b.calories - targetCalories))
        const bestDay = sortedByCalories[0]
        const worstDay = sortedByCalories[sortedByCalories.length - 1]

        // Most common meal type
        const mealTypeEntries = Object.entries(stats.mealTypes) as [string, number][]
        const mostCommonMeal = mealTypeEntries.reduce((a, b) => a[1] > b[1] ? a : b)

        // Average protein per meal
        const avgProteinPerMeal = stats.summary.totalMeals > 0
            ? Math.round(stats.totals.protein / stats.summary.totalMeals)
            : 0

        return {
            consistencyScore,
            currentStreak,
            bestDay,
            worstDay,
            mostCommonMeal: mostCommonMeal[0],
            mostCommonMealCount: mostCommonMeal[1],
            avgProteinPerMeal,
        }
    }

    // Get macro balance percentages
    const getMacroBalance = () => {
        if (!stats) return null
        const total = stats.totals.protein * 4 + stats.totals.carbs * 4 + stats.totals.fat * 9
        if (total === 0) return null

        return {
            protein: Math.round((stats.totals.protein * 4 / total) * 100),
            carbs: Math.round((stats.totals.carbs * 4 / total) * 100),
            fat: Math.round((stats.totals.fat * 9 / total) * 100),
        }
    }

    if (loading) {
        return (
            <div className="flex flex-col items-center justify-center py-20">
                <div className="relative mb-4">
                    <div className="w-16 h-16 border-4 border-purple-200 rounded-full animate-spin border-t-purple-600" />
                    <div className="absolute inset-0 flex items-center justify-center text-2xl animate-pulse">📊</div>
                </div>
                <p className="text-gray-500">Loading statistics...</p>
            </div>
        )
    }

    if (!stats) {
        return (
            <div className="text-center py-12 text-gray-500">
                <p className="text-4xl mb-4">📊</p>
                <p>No data available for this period</p>
            </div>
        )
    }

    const totalMealTypes = stats.mealTypes.breakfast + stats.mealTypes.lunch + stats.mealTypes.dinner + stats.mealTypes.snack
    const insights = getInsights()
    const macroBalance = getMacroBalance()

    return (
        <div className="space-y-6">
            {/* Time Range Selector */}
            <div className="bg-white/15 backdrop-blur-2xl border border-white/20 rounded-3xl p-6 shadow-xl transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20">
                <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
                    <span>📅</span> Select Time Range
                </h3>
                <div className="flex flex-wrap gap-2 mb-4">
                    {timeRangeOptions.map((option) => (
                        <button
                            key={option.value}
                            onClick={() => setTimeRange(option.value)}
                            className={`px-4 py-2 rounded-xl font-medium text-sm transition-all ${timeRange === option.value
                                ? 'bg-gradient-to-r from-purple-500 to-pink-500 text-white shadow-lg'
                                : 'bg-white/50 text-gray-600 hover:bg-white/80 border border-gray-200'
                                }`}
                        >
                            {option.label}
                        </button>
                    ))}
                </div>

                {/* Custom Date Range */}
                {timeRange === 'custom' && (
                    <div className="flex flex-wrap items-center gap-3 p-4 bg-gray-50 rounded-xl">
                        <div className="flex items-center gap-2">
                            <label className="text-sm text-gray-600">From:</label>
                            <input
                                type="date"
                                value={customStart}
                                onChange={(e) => setCustomStart(e.target.value)}
                                max={customEnd || new Date().toISOString().split('T')[0]}
                                className="px-3 py-2 rounded-lg border border-gray-200 text-sm"
                            />
                        </div>
                        <div className="flex items-center gap-2">
                            <label className="text-sm text-gray-600">To:</label>
                            <input
                                type="date"
                                value={customEnd}
                                onChange={(e) => setCustomEnd(e.target.value)}
                                min={customStart}
                                max={new Date().toISOString().split('T')[0]}
                                className="px-3 py-2 rounded-lg border border-gray-200 text-sm"
                            />
                        </div>
                        <button
                            onClick={handleCustomApply}
                            disabled={!customStart || !customEnd}
                            className="px-4 py-2 bg-purple-600 text-white rounded-lg font-medium text-sm hover:bg-purple-700 transition disabled:opacity-50"
                        >
                            Apply
                        </button>
                    </div>
                )}
            </div>

            {/* Insights Row */}
            {insights && stats.days.length > 0 && (
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    {/* Consistency Score */}
                    <div className="bg-white/15 backdrop-blur-2xl border border-white/20 rounded-2xl p-5 shadow-lg hover:shadow-xl transition-shadow">
                        <div className="flex items-center justify-between mb-3">
                            <span className="text-3xl">🎯</span>
                            <div className="relative w-14 h-14">
                                <svg className="w-14 h-14 transform -rotate-90">
                                    <circle cx="28" cy="28" r="24" stroke="#e5e7eb" strokeWidth="4" fill="none" />
                                    <circle
                                        cx="28" cy="28" r="24"
                                        stroke="url(#consistencyGradient)"
                                        strokeWidth="4"
                                        fill="none"
                                        strokeLinecap="round"
                                        strokeDasharray={`${insights.consistencyScore * 1.5} 150`}
                                    />
                                    <defs>
                                        <linearGradient id="consistencyGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                                            <stop offset="0%" stopColor="#8b5cf6" />
                                            <stop offset="100%" stopColor="#ec4899" />
                                        </linearGradient>
                                    </defs>
                                </svg>
                                <div className="absolute inset-0 flex items-center justify-center text-sm font-bold text-gray-700">
                                    {insights.consistencyScore}%
                                </div>
                            </div>
                        </div>
                        <div className="text-sm font-semibold text-gray-900">Consistency</div>
                        <div className="text-xs text-gray-500">Days within ±10% of target</div>
                    </div>

                    {/* Current Streak */}
                    <div className="bg-white/15 backdrop-blur-2xl border border-white/20 rounded-2xl p-5 shadow-lg hover:shadow-xl transition-shadow">
                        <div className="flex items-center justify-between mb-3">
                            <span className="text-3xl">🔥</span>
                            <div className="text-3xl font-bold bg-gradient-to-r from-orange-500 to-red-500 bg-clip-text text-transparent">
                                {insights.currentStreak}
                            </div>
                        </div>
                        <div className="text-sm font-semibold text-gray-900">Current Streak</div>
                        <div className="text-xs text-gray-500">Days on target in a row</div>
                    </div>

                    {/* Best Day */}
                    <div className="bg-white/15 backdrop-blur-2xl border border-white/20 rounded-2xl p-5 shadow-lg hover:shadow-xl transition-shadow">
                        <div className="flex items-center justify-between mb-3">
                            <span className="text-3xl">⭐</span>
                            <div className="text-right">
                                <div className="text-lg font-bold text-green-600">{insights.bestDay?.calories}</div>
                                <div className="text-xs text-gray-400">kcal</div>
                            </div>
                        </div>
                        <div className="text-sm font-semibold text-gray-900">Best Day</div>
                        <div className="text-xs text-gray-500">{insights.bestDay?.label} - Closest to target</div>
                    </div>

                    {/* Avg Protein/Meal */}
                    <div className="bg-white/15 backdrop-blur-2xl border border-white/20 rounded-2xl p-5 shadow-lg hover:shadow-xl transition-shadow">
                        <div className="flex items-center justify-between mb-3">
                            <span className="text-3xl">💪</span>
                            <div className="text-3xl font-bold text-red-500">{insights.avgProteinPerMeal}g</div>
                        </div>
                        <div className="text-sm font-semibold text-gray-900">Protein/Meal</div>
                        <div className="text-xs text-gray-500">Average per meal</div>
                    </div>
                </div>
            )}

            {/* Summary Cards */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="bg-gradient-to-br from-orange-400 to-red-500 rounded-2xl p-5 text-white shadow-lg hover:-translate-y-1 transition-transform">
                    <div className="text-sm opacity-90 mb-1">Total Calories</div>
                    <div className="text-3xl font-bold">{stats.totals.calories.toLocaleString()}</div>
                    <div className="text-xs opacity-75 mt-1">kcal consumed</div>
                </div>
                <div className="bg-gradient-to-br from-blue-400 to-indigo-500 rounded-2xl p-5 text-white shadow-lg hover:-translate-y-1 transition-transform">
                    <div className="text-sm opacity-90 mb-1">Daily Average</div>
                    <div className="text-3xl font-bold">{stats.averages.calories}</div>
                    <div className="text-xs opacity-75 mt-1">kcal/day</div>
                </div>
                <div className="bg-gradient-to-br from-green-400 to-emerald-500 rounded-2xl p-5 text-white shadow-lg hover:-translate-y-1 transition-transform">
                    <div className="text-sm opacity-90 mb-1">Total Meals</div>
                    <div className="text-3xl font-bold">{stats.summary.totalMeals}</div>
                    <div className="text-xs opacity-75 mt-1">{stats.summary.avgMealsPerDay} meals/day</div>
                </div>
                <div className="bg-gradient-to-br from-purple-400 to-pink-500 rounded-2xl p-5 text-white shadow-lg hover:-translate-y-1 transition-transform">
                    <div className="text-sm opacity-90 mb-1">Days Tracked</div>
                    <div className="text-3xl font-bold">{stats.summary.daysWithMeals}</div>
                    <div className="text-xs opacity-75 mt-1">of {stats.summary.totalDays} days</div>
                </div>
            </div>

            {/* AI Coach Insight */}
            {(aiInsight || insightLoading) && (
                <div className="relative overflow-hidden bg-gradient-to-r from-emerald-50 to-teal-50 border border-emerald-200 rounded-2xl p-6 transition-all duration-300 hover:-translate-y-2 hover:shadow-lg">
                    <div className="absolute -right-4 -bottom-4 text-8xl opacity-10">🤖</div>
                    <div className="relative flex gap-4">
                        <div className="flex-shrink-0 w-12 h-12 bg-gradient-to-br from-emerald-400 to-teal-500 rounded-xl flex items-center justify-center text-2xl shadow-lg">
                            🤖
                        </div>
                        <div className="flex-1">
                            <h3 className="font-bold text-emerald-800 mb-1">AI Coach Insight</h3>
                            {insightLoading ? (
                                <div className="flex items-center gap-2 text-emerald-600">
                                    <div className="w-4 h-4 border-2 border-emerald-300 border-t-emerald-600 rounded-full animate-spin" />
                                    <span className="animate-pulse">Analyzing your eating patterns...</span>
                                </div>
                            ) : (
                                <p className="text-emerald-700 leading-relaxed">{aiInsight}</p>
                            )}
                        </div>
                    </div>
                </div>
            )}

            {/* Macro Balance Visual */}
            {macroBalance && (
                <div className="bg-white/15 backdrop-blur-2xl border border-white/20 rounded-3xl p-6 shadow-xl transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20">
                    <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
                        <span>⚖️</span> Macro Balance (by calories)
                    </h3>

                    {/* Stacked Bar */}
                    <div className="h-8 rounded-full overflow-hidden flex shadow-inner mb-4">
                        <div
                            className="bg-gradient-to-r from-red-400 to-red-500 flex items-center justify-center text-white text-xs font-bold transition-all duration-500"
                            style={{ width: `${macroBalance.protein}%` }}
                        >
                            {macroBalance.protein > 10 && `${macroBalance.protein}%`}
                        </div>
                        <div
                            className="bg-gradient-to-r from-amber-400 to-amber-500 flex items-center justify-center text-white text-xs font-bold transition-all duration-500"
                            style={{ width: `${macroBalance.carbs}%` }}
                        >
                            {macroBalance.carbs > 10 && `${macroBalance.carbs}%`}
                        </div>
                        <div
                            className="bg-gradient-to-r from-blue-400 to-blue-500 flex items-center justify-center text-white text-xs font-bold transition-all duration-500"
                            style={{ width: `${macroBalance.fat}%` }}
                        >
                            {macroBalance.fat > 10 && `${macroBalance.fat}%`}
                        </div>
                    </div>

                    {/* Legend and Details */}
                    <div className="grid grid-cols-3 gap-4">
                        <div className="flex items-center gap-3 p-3 bg-red-50 rounded-xl">
                            <div className="w-4 h-4 rounded-full bg-gradient-to-r from-red-400 to-red-500" />
                            <div>
                                <div className="text-sm font-semibold text-gray-900">Protein</div>
                                <div className="text-xs text-gray-500">{stats.totals.protein}g • {macroBalance.protein}%</div>
                            </div>
                        </div>
                        <div className="flex items-center gap-3 p-3 bg-amber-50 rounded-xl">
                            <div className="w-4 h-4 rounded-full bg-gradient-to-r from-amber-400 to-amber-500" />
                            <div>
                                <div className="text-sm font-semibold text-gray-900">Carbs</div>
                                <div className="text-xs text-gray-500">{stats.totals.carbs}g • {macroBalance.carbs}%</div>
                            </div>
                        </div>
                        <div className="flex items-center gap-3 p-3 bg-blue-50 rounded-xl">
                            <div className="w-4 h-4 rounded-full bg-gradient-to-r from-blue-400 to-blue-500" />
                            <div>
                                <div className="text-sm font-semibold text-gray-900">Fat</div>
                                <div className="text-xs text-gray-500">{stats.totals.fat}g • {macroBalance.fat}%</div>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Calorie Heat Map Calendar (for longer ranges) */}
            {stats.days.length > 7 && (
                <div className="bg-white/15 backdrop-blur-2xl border border-white/20 rounded-3xl p-6 shadow-xl transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20">
                    <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
                        <span>🗓️</span> Daily Intake Heatmap
                        <span className="text-sm font-normal text-gray-500 ml-2">(Click to view details)</span>
                    </h3>

                    <div className="flex flex-wrap gap-1.5">
                        {stats.days.map((day) => {
                            const ratio = day.calories / targetCalories
                            let colorClass = 'bg-gray-100'

                            if (day.calories === 0) {
                                colorClass = 'bg-gray-50'
                            } else if (ratio < 0.5) {
                                colorClass = 'bg-red-100'
                            } else if (ratio < 0.8) {
                                colorClass = 'bg-amber-200'
                            } else if (ratio <= 1.1) {
                                colorClass = 'bg-green-400'
                            } else if (ratio <= 1.3) {
                                colorClass = 'bg-amber-400'
                            } else {
                                colorClass = 'bg-red-400'
                            }

                            return (
                                <div
                                    key={day.date}
                                    onClick={() => handleDayClick(day)}
                                    className={`w-7 h-7 rounded-md ${colorClass} cursor-pointer hover:ring-2 hover:ring-purple-400 transition-all flex items-center justify-center group relative`}
                                    title={`${day.label}: ${day.calories} kcal`}
                                >
                                    {/* Tooltip */}
                                    <div className="absolute bottom-full mb-2 px-2 py-1 bg-gray-900 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap z-20 pointer-events-none">
                                        {day.label}: {day.calories} kcal
                                    </div>
                                </div>
                            )
                        })}
                    </div>

                    {/* Legend */}
                    <div className="flex items-center gap-4 mt-4 text-xs text-gray-500">
                        <span>Less</span>
                        <div className="flex gap-1">
                            <div className="w-4 h-4 rounded bg-gray-100" />
                            <div className="w-4 h-4 rounded bg-red-100" />
                            <div className="w-4 h-4 rounded bg-amber-200" />
                            <div className="w-4 h-4 rounded bg-green-400" />
                            <div className="w-4 h-4 rounded bg-amber-400" />
                            <div className="w-4 h-4 rounded bg-red-400" />
                        </div>
                        <span>More</span>
                        <span className="ml-4 text-green-600">🟢 On Target (90-110%)</span>
                    </div>
                </div>
            )}

            {/* Calorie Trend Chart */}
            {stats.days.length > 0 && (
                <div className="bg-white/15 backdrop-blur-2xl border border-white/20 rounded-3xl p-6 shadow-xl transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20">
                    <h3 className="font-bold text-gray-900 mb-6 flex items-center gap-2">
                        <span>📈</span> Calorie Trend
                        <span className="text-sm font-normal text-gray-500 ml-2">
                            (Click bars for details)
                        </span>
                    </h3>

                    {/* Target Line Legend */}
                    <div className="flex items-center gap-4 mb-4 text-sm">
                        <div className="flex items-center gap-2">
                            <div className="w-4 h-0.5 bg-red-400" />
                            <span className="text-gray-500">Target: {targetCalories} kcal</span>
                        </div>
                        <div className="flex items-center gap-2">
                            <div className="w-4 h-4 bg-gradient-to-t from-cyan-500 to-blue-400 rounded" />
                            <span className="text-gray-500">Daily intake</span>
                        </div>
                    </div>

                    <div className="relative">
                        {/* Target Line */}
                        <div
                            className="absolute left-0 right-0 border-t-2 border-dashed border-red-300 z-10"
                            style={{
                                bottom: `${(targetCalories / getMaxCalories()) * 100}%`,
                            }}
                        />

                        {/* Chart */}
                        <div className="flex items-end gap-1 h-48 overflow-x-auto pb-6">
                            {stats.days.map((day, idx) => {
                                const heightPercent = (day.calories / getMaxCalories()) * 100
                                const isOverTarget = day.calories > targetCalories

                                return (
                                    <div
                                        key={day.date}
                                        className="flex-shrink-0 flex flex-col items-center group cursor-pointer"
                                        style={{ minWidth: stats.days.length > 14 ? '24px' : '40px' }}
                                        onClick={() => handleDayClick(day)}
                                    >
                                        {/* Tooltip */}
                                        <div className="absolute bottom-full mb-2 px-2 py-1 bg-gray-900 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap z-20 pointer-events-none">
                                            {day.label}: {day.calories} kcal
                                        </div>

                                        {/* Bar */}
                                        <div
                                            className="w-full relative group-hover:ring-2 group-hover:ring-purple-400 transition-all"
                                            style={{ height: '160px' }}
                                        >
                                            <div
                                                className={`absolute bottom-0 w-full rounded-t-lg transition-all duration-300 ${isOverTarget
                                                    ? 'bg-gradient-to-t from-red-500 to-orange-400'
                                                    : 'bg-gradient-to-t from-cyan-500 to-blue-400'
                                                    }`}
                                                style={{
                                                    height: `${Math.max(heightPercent, 2)}%`,
                                                }}
                                            />
                                        </div>

                                        {/* Label */}
                                        <p className="text-[10px] text-gray-500 mt-1 rotate-45 origin-left whitespace-nowrap">
                                            {stats.days.length > 14
                                                ? (idx % Math.ceil(stats.days.length / 14) === 0 ? day.label : '')
                                                : day.label
                                            }
                                        </p>
                                    </div>
                                )
                            })}
                        </div>
                    </div>

                    <div className="mt-4 pt-4 border-t flex justify-between text-sm text-gray-500">
                        <span>Avg: {stats.averages.calories} kcal/day</span>
                        <span>
                            {stats.days.filter(d => d.calories >= targetCalories * 0.9 && d.calories <= targetCalories * 1.1).length} of {stats.days.length} days on target
                        </span>
                    </div>
                </div>
            )}

            {/* Meal Type Distribution */}
            {totalMealTypes > 0 && (
                <div className="bg-white/15 backdrop-blur-2xl border border-white/20 rounded-3xl p-6 shadow-xl transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20">
                    <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
                        <span>🍽️</span> Meal Type Distribution
                    </h3>
                    <div className="grid grid-cols-4 gap-4">
                        {Object.entries(stats.mealTypes).map(([type, count]) => {
                            const percentage = totalMealTypes > 0 ? Math.round((count / totalMealTypes) * 100) : 0
                            return (
                                <div key={type} className="text-center p-4 bg-white/50 rounded-2xl hover:bg-white/80 transition-colors">
                                    <div className="text-4xl mb-2">{getMealTypeEmoji(type)}</div>
                                    <div className="text-2xl font-bold text-gray-900">{count}</div>
                                    <div className="text-sm text-gray-500 capitalize">{type}</div>
                                    <div className="mt-3 h-2 bg-gray-100 rounded-full overflow-hidden">
                                        <div
                                            className="h-full bg-gradient-to-r from-purple-500 to-pink-500 rounded-full transition-all duration-500"
                                            style={{ width: `${percentage}%` }}
                                        />
                                    </div>
                                    <div className="text-xs text-gray-400 mt-1">{percentage}%</div>
                                </div>
                            )
                        })}
                    </div>
                </div>
            )}

            {/* Empty State */}
            {stats.days.length === 0 && (
                <div className="bg-gray-50 rounded-2xl p-12 text-center">
                    <div className="text-6xl mb-4">📭</div>
                    <h3 className="text-xl font-bold text-gray-900 mb-2">No data for this period</h3>
                    <p className="text-gray-500">Try selecting a different time range or log some meals first!</p>
                </div>
            )}

            {/* Day Detail Modal */}
            {selectedDay && (
                <DayDetailModal
                    date={selectedDay.date}
                    label={selectedDay.label}
                    meals={selectedDay.meals}
                    totals={selectedDay.totals}
                    onClose={() => setSelectedDay(null)}
                    onMealClick={setSelectedMeal}
                />
            )}

            {/* Meal Detail Modal (Drill down from Day Detail) */}
            {selectedMeal && (
                <MealDetailModal
                    meal={selectedMeal}
                    onClose={() => setSelectedMeal(null)}
                />
            )}

            {/* Day Loading Overlay */}
            {dayLoading && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 backdrop-blur-sm">
                    <div className="bg-white/90 backdrop-blur-xl rounded-2xl p-6 shadow-2xl flex items-center gap-4">
                        <div className="w-8 h-8 border-4 border-purple-200 border-t-purple-600 rounded-full animate-spin" />
                        <span className="text-gray-700 font-medium">Loading day details...</span>
                    </div>
                </div>
            )}
        </div>
    )
}
