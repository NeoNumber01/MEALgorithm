'use client'

import { useEffect, useState } from 'react'
import { getDailyStats, getWeeklyStats, getUserProfile } from '@/lib/dashboard/actions'
import { generateGoalFeedback } from '@/lib/dashboard/ai-feedback'
import { updateCachedFeedback } from '@/lib/profile/actions'
import { getNutritionalTargets } from '@/lib/nutrition/calculator'
import { deleteMeal } from '@/lib/meals/actions'
import CalorieGauge from './CalorieGauge'
import Link from 'next/link'
import MealDetailModal from './MealDetailModal'
import StatisticsView from './StatisticsView'
import ConfirmModal from '@/components/ui/ConfirmModal'
import { notifyDataUpdated, getLastDataUpdateTime, getLastGoalUpdateTime, generateDataHash, shouldRegenerateAIFeedback, CACHE_KEYS } from '@/lib/cache-utils'

type ViewMode = 'today' | 'week'

interface NutritionTargets {
    calories: number
    protein: number
    carbs: number
    fat: number
}

export default function DashboardContent() {
    const [viewMode, setViewMode] = useState<ViewMode>('today')
    const [loading, setLoading] = useState(true)
    const [todayData, setTodayData] = useState<{
        totals: { calories: number; protein: number; carbs: number; fat: number }
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        meals: any[]
    } | null>(null)
    const [feedback, setFeedback] = useState<string>('')
    const [targets, setTargets] = useState<NutritionTargets>({
        calories: 2000,
        protein: 150,
        carbs: 200,
        fat: 65,
    })
    const [deletingId, setDeletingId] = useState<string | null>(null)
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const [selectedMeal, setSelectedMeal] = useState<any>(null)
    const [mealToDelete, setMealToDelete] = useState<string | null>(null)
    const [feedbackLoading, setFeedbackLoading] = useState(false)
    const [lastUpdateTimestamp, setLastUpdateTimestamp] = useState<number>(() => {
        if (typeof window !== 'undefined') return getLastDataUpdateTime()
        return Date.now()
    })

    useEffect(() => {
        loadData()
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [])

    const loadData = async () => {
        setLoading(true)

        const today = new Date().toLocaleDateString('en-CA')
        const lastDbUpdate = getLastDataUpdateTime()
        let cachedTime = 0

        // Check cache
        try {
            cachedTime = parseInt(localStorage.getItem(CACHE_KEYS.DASHBOARD_TIMESTAMP) || '0')
            const cachedToday = localStorage.getItem(CACHE_KEYS.DASHBOARD_TODAY)
            const cachedTargets = localStorage.getItem(CACHE_KEYS.DASHBOARD_TARGETS)
            const cachedFeedback = localStorage.getItem(CACHE_KEYS.DASHBOARD_FEEDBACK)

            if (cachedToday) {
                const parsedToday = JSON.parse(cachedToday)
                const cachedDate = parsedToday.date // Check stored date

                // If cache exists, isn't from another day, and is fresh relative to db updates
                if (cachedDate === today && cachedTime > lastDbUpdate) {
                    setTodayData(parsedToday)
                    if (cachedTargets) setTargets(JSON.parse(cachedTargets))
                    if (cachedFeedback) setFeedback(cachedFeedback)
                    setLoading(false)
                    // Background refresh if cache is old (> 1 hour) but valid
                    if (Date.now() - cachedTime < 3600000) return
                }
            }
        } catch (e) {
            console.error('Cache read error', e)
        }

        const timezoneOffset = new Date().getTimezoneOffset()
        const now = new Date()

        const startOfDay = new Date(now)
        startOfDay.setHours(0, 0, 0, 0)

        const endOfDay = new Date(now)
        endOfDay.setHours(23, 59, 59, 999)

        const startOfWeek = new Date(startOfDay)
        startOfWeek.setDate(startOfWeek.getDate() - 6)

        const [dailyResult, weeklyResult, profileResult] = await Promise.all([
            getDailyStats(startOfDay.toISOString(), endOfDay.toISOString()),
            getWeeklyStats(startOfWeek.toISOString(), endOfDay.toISOString(), timezoneOffset),
            getUserProfile(),
        ])

        console.log('Dashboard Data Load:', {
            start: startOfDay.toISOString(),
            end: endOfDay.toISOString(),
            localDate: today,
            cachedTime,
            lastDbUpdate,
            dailyMeals: 'error' in dailyResult ? 'error' : dailyResult.meals.length
        })

        if (!('error' in dailyResult)) {
            setTodayData({
                totals: dailyResult.totals,
                meals: dailyResult.meals,
            })
            setLastUpdateTimestamp(Date.now())

            // Cache today's data with date
            localStorage.setItem(CACHE_KEYS.DASHBOARD_TODAY, JSON.stringify({
                date: today,
                totals: dailyResult.totals,
                meals: dailyResult.meals,
            }))
            localStorage.setItem(CACHE_KEYS.DASHBOARD_TIMESTAMP, Date.now().toString())
        }

        // Calculate targets from profile
        let calculatedTargets = targets
        if (!('error' in profileResult) && profileResult.profile) {
            calculatedTargets = getNutritionalTargets(profileResult.profile)
            setTargets(calculatedTargets)
            localStorage.setItem(CACHE_KEYS.DASHBOARD_TARGETS, JSON.stringify(calculatedTargets))
        }

        // Smart AI feedback generation - only call AI when data actually changed
        if (!('error' in dailyResult) && !('error' in weeklyResult)) {
            // Create hash of current data used for feedback
            const feedbackDataHash = generateDataHash({
                todayCalories: dailyResult.totals.calories,
                weeklyAvgCalories: weeklyResult.averages.calories,
                targetCalories: calculatedTargets.calories,
                goalDescription: profileResult.profile?.goal_description,
            })
            
            // Get cached hash and feedback
            const cachedHash = localStorage.getItem(CACHE_KEYS.DASHBOARD_FEEDBACK_HASH)
            const cachedFeedback = localStorage.getItem(CACHE_KEYS.DASHBOARD_FEEDBACK)
            const lastFeedbackTime = parseInt(localStorage.getItem(CACHE_KEYS.DASHBOARD_TIMESTAMP) || '0')
            
            // Check if we need to regenerate AI feedback
            if (shouldRegenerateAIFeedback(feedbackDataHash, cachedHash, lastFeedbackTime)) {
                console.log('AI Feedback: Data changed, regenerating...', { cachedHash, feedbackDataHash })
                setFeedbackLoading(true)
                const feedbackResult = await generateGoalFeedback({
                    todayCalories: dailyResult.totals.calories,
                    weeklyAvgCalories: weeklyResult.averages.calories,
                    targetCalories: calculatedTargets.calories,
                    goalDescription: profileResult.profile?.goal_description,
                })
                setFeedback(feedbackResult.feedback)
                setFeedbackLoading(false)

                // Cache the new feedback and hash
                await updateCachedFeedback(feedbackResult.feedback)
                localStorage.setItem(CACHE_KEYS.DASHBOARD_FEEDBACK, feedbackResult.feedback)
                localStorage.setItem(CACHE_KEYS.DASHBOARD_FEEDBACK_HASH, feedbackDataHash)
            } else if (cachedFeedback) {
                // Use cached feedback - no AI call needed
                console.log('AI Feedback: Using cached feedback (no data change)')
                setFeedback(cachedFeedback)
            }
        }

        setLoading(false)
    }

    const handleDeleteClick = (mealId: string) => {
        setMealToDelete(mealId)
    }

    const handleDeleteConfirm = async () => {
        if (!mealToDelete) return

        setDeletingId(mealToDelete)
        const result = await deleteMeal(mealToDelete)

        if (result?.success) {
            notifyDataUpdated()
            // Reload data to reflect changes
            const startOfDay = new Date()
            startOfDay.setHours(0, 0, 0, 0)
            const endOfDay = new Date()
            endOfDay.setHours(23, 59, 59, 999)

            const dailyResult = await getDailyStats(startOfDay.toISOString(), endOfDay.toISOString())
            if (!('error' in dailyResult)) {
                const newData = {
                    totals: dailyResult.totals,
                    meals: dailyResult.meals,
                }
                setTodayData(newData)
                setLastUpdateTimestamp(Date.now())

                // Update cache
                localStorage.setItem(CACHE_KEYS.DASHBOARD_TODAY, JSON.stringify(newData))
                localStorage.setItem(CACHE_KEYS.DASHBOARD_TIMESTAMP, Date.now().toString())
            }
            // If the deleted meal was selected, close the modal
            if (selectedMeal?.id === mealToDelete) {
                setSelectedMeal(null)
            }
        }
        setDeletingId(null)
        setMealToDelete(null)
    }

    if (loading) {
        return (
            <div className="flex flex-col items-center justify-center py-20">
                <div className="relative">
                    <div className="w-16 h-16 border-4 border-purple-200 rounded-full animate-spin border-t-purple-600" />
                </div>
                <p className="mt-4 text-gray-500">Loading your nutrition data...</p>
            </div>
        )
    }

    return (
        <div className="space-y-6">
            {/* Header with Toggle */}
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">
                        {viewMode === 'today' ? "Today's Overview" : 'Statistics & History'}
                    </h1>
                    <p className="text-gray-500 text-sm">
                        {viewMode === 'today'
                            ? new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })
                            : 'Analyze your eating habits'
                        }
                    </p>
                </div>

                <div className="flex items-center gap-3">
                    <button
                        onClick={() => {
                            localStorage.removeItem('dashboard_today_data')
                            localStorage.removeItem('dashboard_timestamp')
                            loadData()
                        }}
                        className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition"
                        title="Refresh Data"
                    >
                        🔄
                    </button>
                    <div className="flex bg-gray-100 p-1 rounded-xl">
                        <button
                            onClick={() => setViewMode('today')}
                            className={`px-4 py-2 rounded-lg font-medium text-sm transition-all ${viewMode === 'today'
                                ? 'bg-white shadow-sm text-gray-900'
                                : 'text-gray-500 hover:text-gray-700'
                                }`}
                        >
                            📅 Today
                        </button>
                        <button
                            onClick={() => setViewMode('week')}
                            className={`px-4 py-2 rounded-lg font-medium text-sm transition-all ${viewMode === 'week'
                                ? 'bg-white shadow-sm text-gray-900'
                                : 'text-gray-500 hover:text-gray-700'
                                }`}
                        >
                            📊 Statistics
                        </button>
                    </div>
                    <Link
                        href="/settings"
                        className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition"
                        title="Settings"
                    >
                        ⚙️
                    </Link>
                </div>
            </div>

            {/* Today View Content */}
            {viewMode === 'today' && (
                <>
                    {/* Calorie Gauge Card */}
                    <div className="bg-white/15 backdrop-blur-3xl rounded-3xl border border-white/20 shadow-2xl p-8 transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20">
                        <CalorieGauge
                            current={todayData?.totals?.calories || 0}
                            target={targets.calories}
                            label="Today's Calories"
                        />
                    </div>

                    {/* Macro Cards */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        {/* Protein */}
                        <div className="relative overflow-hidden bg-gradient-to-br from-red-500 to-rose-600 rounded-2xl p-6 text-white shadow-lg transition-all duration-300 hover:-translate-y-2 hover:shadow-xl">
                            <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/2" />
                            <div className="relative">
                                <div className="flex items-center gap-2 mb-2">
                                    <span className="text-2xl">🥩</span>
                                    <span className="text-sm font-medium opacity-90">Protein</span>
                                </div>
                                <div className="text-4xl font-bold mb-1">
                                    {todayData?.totals?.protein || 0}g
                                </div>
                                <div className="text-sm opacity-75 mb-3">of {targets.protein}g target</div>
                                <div className="bg-white/20 rounded-full h-2">
                                    <div
                                        className="bg-white rounded-full h-2 transition-all duration-500"
                                        style={{ width: `${Math.min(100, ((todayData?.totals?.protein || 0) / targets.protein) * 100)}%` }}
                                    />
                                </div>
                                <div className="text-xs mt-2 opacity-75">
                                    {Math.round(((todayData?.totals?.protein || 0) / targets.protein) * 100)}% complete
                                </div>
                            </div>
                        </div>

                        {/* Carbs */}
                        <div className="relative overflow-hidden bg-gradient-to-br from-amber-500 to-orange-500 rounded-2xl p-6 text-white shadow-lg transition-all duration-300 hover:-translate-y-2 hover:shadow-xl">
                            <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/2" />
                            <div className="relative">
                                <div className="flex items-center gap-2 mb-2">
                                    <span className="text-2xl">🍞</span>
                                    <span className="text-sm font-medium opacity-90">Carbs</span>
                                </div>
                                <div className="text-4xl font-bold mb-1">
                                    {todayData?.totals?.carbs || 0}g
                                </div>
                                <div className="text-sm opacity-75 mb-3">of {targets.carbs}g target</div>
                                <div className="bg-white/20 rounded-full h-2">
                                    <div
                                        className="bg-white rounded-full h-2 transition-all duration-500"
                                        style={{ width: `${Math.min(100, ((todayData?.totals?.carbs || 0) / targets.carbs) * 100)}%` }}
                                    />
                                </div>
                                <div className="text-xs mt-2 opacity-75">
                                    {Math.round(((todayData?.totals?.carbs || 0) / targets.carbs) * 100)}% complete
                                </div>
                            </div>
                        </div>

                        {/* Fat */}
                        <div className="relative overflow-hidden bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl p-6 text-white shadow-lg transition-all duration-300 hover:-translate-y-2 hover:shadow-xl">
                            <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/2" />
                            <div className="relative">
                                <div className="flex items-center gap-2 mb-2">
                                    <span className="text-2xl">🧈</span>
                                    <span className="text-sm font-medium opacity-90">Fat</span>
                                </div>
                                <div className="text-4xl font-bold mb-1">
                                    {todayData?.totals?.fat || 0}g
                                </div>
                                <div className="text-sm opacity-75 mb-3">of {targets.fat}g target</div>
                                <div className="bg-white/20 rounded-full h-2">
                                    <div
                                        className="bg-white rounded-full h-2 transition-all duration-500"
                                        style={{ width: `${Math.min(100, ((todayData?.totals?.fat || 0) / targets.fat) * 100)}%` }}
                                    />
                                </div>
                                <div className="text-xs mt-2 opacity-75">
                                    {Math.round(((todayData?.totals?.fat || 0) / targets.fat) * 100)}% complete
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* AI Feedback */}
                    {(feedback || feedbackLoading) && (
                        <div className="relative overflow-hidden bg-gradient-to-r from-emerald-50 to-teal-50 border border-emerald-200 rounded-2xl p-6 transition-all duration-300 hover:-translate-y-2 hover:shadow-lg">
                            <div className="absolute -right-4 -bottom-4 text-8xl opacity-10">🤖</div>
                            <div className="relative flex gap-4">
                                <div className="flex-shrink-0 w-12 h-12 bg-gradient-to-br from-emerald-400 to-teal-500 rounded-xl flex items-center justify-center text-2xl shadow-lg">
                                    🤖
                                </div>
                                <div className="flex-1">
                                    <h3 className="font-bold text-emerald-800 mb-1">AI Coach Insight</h3>
                                    {feedbackLoading ? (
                                        <div className="flex items-center gap-2 text-emerald-600">
                                            <div className="w-4 h-4 border-2 border-emerald-300 border-t-emerald-600 rounded-full animate-spin" />
                                            <span className="animate-pulse">Analyzing your progress...</span>
                                        </div>
                                    ) : (
                                        <p className="text-emerald-700 leading-relaxed">{feedback}</p>
                                    )}
                                </div>
                            </div>
                        </div>
                    )}
                </>
            )}

            {/* Statistics View (if statistics view) */}
            {viewMode === 'week' && (
                <StatisticsView
                    targetCalories={targets.calories}
                    lastUpdateTimestamp={lastUpdateTimestamp}
                />
            )}

            {/* Today's Meals */}
            {viewMode === 'today' && todayData && todayData.meals.length > 0 && (
                <div className="bg-white/15 backdrop-blur-2xl border border-white/20 rounded-3xl p-6 shadow-xl transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20">
                    <div className="flex justify-between items-center mb-4">
                        <h3 className="font-bold text-gray-900">🍽️ Today&apos;s Meals</h3>
                        <Link href="/log" className="text-sm text-purple-600 hover:text-purple-800 font-medium">
                            + Add meal
                        </Link>
                    </div>
                    <div className="space-y-3">
                        {todayData.meals.map((meal, index) => (
                            <div
                                key={meal.id}
                                onClick={() => setSelectedMeal(meal)}
                                className="flex justify-between items-center p-4 bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl hover:bg-white/10 hover:-translate-y-1 hover:shadow-lg transition-all group cursor-pointer"
                            >
                                <div className="flex items-center gap-4">
                                    <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-orange-100 to-red-100 flex items-center justify-center text-lg">
                                        {meal.mealType === 'breakfast' ? '🌅' : 
                                         meal.mealType === 'lunch' ? '☀️' : 
                                         meal.mealType === 'dinner' ? '🌙' : 
                                         meal.mealType === 'snack' ? '🍿' : '🍽️'}
                                    </div>
                                    <div>
                                        <span className="capitalize font-semibold text-gray-900">
                                            {meal.mealType || 'Meal'}
                                        </span>
                                        <div className="text-gray-400 text-xs">
                                            {new Date(meal.createdAt).toLocaleTimeString('en-US', {
                                                hour: '2-digit',
                                                minute: '2-digit'
                                            })}
                                        </div>
                                    </div>
                                </div>
                                <div className="flex items-center gap-4">
                                    <div className="text-right">
                                        <span className="font-bold text-lg text-orange-600">
                                            {meal.analysis?.summary?.calories || 0}
                                        </span>
                                        <span className="text-gray-400 text-sm ml-1">kcal</span>
                                    </div>
                                    <button
                                        onClick={(e) => {
                                            e.stopPropagation()
                                            handleDeleteClick(meal.id)
                                        }}
                                        disabled={deletingId === meal.id}
                                        className="opacity-0 group-hover:opacity-100 p-2 text-gray-400 hover:text-red-500 transition-all disabled:opacity-50"
                                        title="Delete meal"
                                    >
                                        {deletingId === meal.id ? '...' : '🗑️'}
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {/* Empty State */}
            {viewMode === 'today' && todayData && todayData.meals.length === 0 && (
                <div className="bg-gradient-to-br from-purple-50 to-pink-50 border border-purple-100 rounded-2xl p-12 text-center transition-all duration-300 hover:-translate-y-2 hover:shadow-xl">
                    <div className="text-6xl mb-4">🍽️</div>
                    <h3 className="text-xl font-bold text-gray-900 mb-2">No meals logged yet</h3>
                    <p className="text-gray-500 mb-6">Start tracking your nutrition today!</p>
                    <Link
                        href="/log"
                        className="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-purple-600 to-pink-600 text-white font-semibold rounded-xl hover:shadow-lg hover:shadow-purple-500/25 transition-all hover:-translate-y-0.5"
                    >
                        📝 Log your meal
                    </Link>
                </div>
            )}

            {/* Meal Detail Modal */}
            {selectedMeal && (
                <MealDetailModal
                    meal={selectedMeal}
                    onClose={() => setSelectedMeal(null)}
                />
            )}

            {/* Delete Confirmation Modal */}
            <ConfirmModal
                isOpen={mealToDelete !== null}
                title="Delete Meal?"
                message="This action cannot be undone. The meal record and its nutritional data will be permanently removed."
                confirmText="Delete"
                cancelText="Keep It"
                onConfirm={handleDeleteConfirm}
                onCancel={() => setMealToDelete(null)}
                isLoading={deletingId !== null}
            />
        </div>
    )
}
