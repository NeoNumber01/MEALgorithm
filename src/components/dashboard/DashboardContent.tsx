'use client'

import { useEffect, useState } from 'react'
import { getDailyStats, getWeeklyStats, getUserProfile } from '@/lib/dashboard/actions'
import { generateGoalFeedback } from '@/lib/dashboard/ai-feedback'

type ViewMode = 'today' | 'week'

interface DailyData {
    date: string
    label: string
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
    const [weeklyData, setWeeklyData] = useState<{
        days: DailyData[]
        totals: { calories: number; protein: number; carbs: number; fat: number }
        averages: { calories: number; protein: number; carbs: number; fat: number }
    } | null>(null)
    const [feedback, setFeedback] = useState<string>('')
    const [targetCalories, setTargetCalories] = useState(2000)

    useEffect(() => {
        loadData()
    }, [])

    const loadData = async () => {
        setLoading(true)

        const today = new Date().toISOString().split('T')[0]
        const [dailyResult, weeklyResult, profileResult] = await Promise.all([
            getDailyStats(today),
            getWeeklyStats(),
            getUserProfile(),
        ])

        if (!('error' in dailyResult)) {
            setTodayData({
                totals: dailyResult.totals,
                meals: dailyResult.meals,
            })
        }

        if (!('error' in weeklyResult)) {
            setWeeklyData({
                days: weeklyResult.days,
                totals: weeklyResult.totals,
                averages: weeklyResult.averages,
            })
        }

        if (!('error' in profileResult) && profileResult.profile) {
            setTargetCalories(profileResult.profile.calorie_target || 2000)
        }

        // Generate AI feedback
        if (!('error' in dailyResult) && !('error' in weeklyResult)) {
            const feedbackResult = await generateGoalFeedback({
                todayCalories: dailyResult.totals.calories,
                weeklyAvgCalories: weeklyResult.averages.calories,
                targetCalories: profileResult.profile?.calorie_target || 2000,
                goalDescription: profileResult.profile?.goal_description,
            })
            setFeedback(feedbackResult.feedback)
        }

        setLoading(false)
    }

    const currentData = viewMode === 'today' ? todayData?.totals : weeklyData?.averages
    const caloriePercent = currentData ? Math.min(100, (currentData.calories / targetCalories) * 100) : 0

    if (loading) {
        return (
            <div className="flex items-center justify-center py-20">
                <div className="animate-spin text-4xl">⏳</div>
            </div>
        )
    }

    return (
        <div className="space-y-6">
            {/* View Toggle */}
            <div className="flex gap-2 bg-gray-100 p-1 rounded-lg w-fit">
                <button
                    onClick={() => setViewMode('today')}
                    className={`px-4 py-2 rounded-md font-medium transition ${viewMode === 'today' ? 'bg-white shadow' : 'text-gray-600'
                        }`}
                >
                    Today
                </button>
                <button
                    onClick={() => setViewMode('week')}
                    className={`px-4 py-2 rounded-md font-medium transition ${viewMode === 'week' ? 'bg-white shadow' : 'text-gray-600'
                        }`}
                >
                    This Week
                </button>
            </div>

            {/* Calorie Progress */}
            <div className="bg-gradient-to-r from-orange-500 to-red-500 rounded-xl p-6 text-white">
                <div className="flex justify-between items-start mb-4">
                    <div>
                        <p className="text-sm opacity-80">{viewMode === 'today' ? "Today's" : 'Daily Avg'} Calories</p>
                        <p className="text-4xl font-bold">{currentData?.calories || 0}</p>
                        <p className="text-sm opacity-80">/ {targetCalories} kcal target</p>
                    </div>
                    <div className="text-right">
                        <p className="text-3xl font-bold">{Math.round(caloriePercent)}%</p>
                    </div>
                </div>
                <div className="bg-white/30 rounded-full h-3">
                    <div
                        className="bg-white rounded-full h-3 transition-all duration-500"
                        style={{ width: `${caloriePercent}%` }}
                    />
                </div>
            </div>

            {/* Macros Grid */}
            <div className="grid grid-cols-3 gap-4">
                <div className="bg-red-50 border border-red-100 rounded-xl p-4 text-center">
                    <div className="text-3xl font-bold text-red-600">
                        {currentData?.protein || 0}g
                    </div>
                    <div className="text-sm text-gray-600">Protein</div>
                </div>
                <div className="bg-yellow-50 border border-yellow-100 rounded-xl p-4 text-center">
                    <div className="text-3xl font-bold text-yellow-600">
                        {currentData?.carbs || 0}g
                    </div>
                    <div className="text-sm text-gray-600">Carbs</div>
                </div>
                <div className="bg-blue-50 border border-blue-100 rounded-xl p-4 text-center">
                    <div className="text-3xl font-bold text-blue-600">
                        {currentData?.fat || 0}g
                    </div>
                    <div className="text-sm text-gray-600">Fat</div>
                </div>
            </div>

            {/* AI Feedback */}
            {feedback && (
                <div className="bg-green-50 border border-green-200 rounded-xl p-4">
                    <h3 className="font-semibold text-green-800 mb-2">🤖 AI Coach Says:</h3>
                    <p className="text-green-700">{feedback}</p>
                </div>
            )}

            {/* Weekly Chart (if week view) */}
            {viewMode === 'week' && weeklyData && (
                <div className="bg-white border rounded-xl p-6">
                    <h3 className="font-semibold mb-4">Weekly Overview</h3>
                    <div className="flex items-end justify-between h-32 gap-2">
                        {weeklyData.days.map((day) => {
                            const height = targetCalories > 0
                                ? Math.min(100, (day.calories / targetCalories) * 100)
                                : 0
                            return (
                                <div key={day.date} className="flex-1 flex flex-col items-center">
                                    <div className="w-full bg-gray-100 rounded-t relative" style={{ height: '100px' }}>
                                        <div
                                            className="absolute bottom-0 w-full bg-gradient-to-t from-blue-500 to-blue-400 rounded-t transition-all"
                                            style={{ height: `${height}%` }}
                                        />
                                    </div>
                                    <p className="text-xs text-gray-500 mt-2">{day.label}</p>
                                    <p className="text-xs font-medium">{day.calories}</p>
                                </div>
                            )
                        })}
                    </div>
                </div>
            )}

            {/* Today's Meals (if today view) */}
            {viewMode === 'today' && todayData && todayData.meals.length > 0 && (
                <div className="bg-white border rounded-xl p-6">
                    <h3 className="font-semibold mb-4">Today&apos;s Meals</h3>
                    <div className="space-y-3">
                        {todayData.meals.map((meal) => (
                            <div key={meal.id} className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                                <div>
                                    <span className="capitalize font-medium">{meal.mealType || 'Meal'}</span>
                                    <span className="text-gray-500 text-sm ml-2">
                                        {new Date(meal.createdAt).toLocaleTimeString('en-US', {
                                            hour: '2-digit',
                                            minute: '2-digit'
                                        })}
                                    </span>
                                </div>
                                <span className="font-semibold text-orange-600">
                                    {meal.analysis?.summary?.calories || 0} kcal
                                </span>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {/* Empty State */}
            {viewMode === 'today' && todayData && todayData.meals.length === 0 && (
                <div className="text-center py-8 text-gray-500">
                    <p className="text-4xl mb-2">🍽️</p>
                    <p>No meals logged today yet.</p>
                    <a href="/log" className="text-blue-600 hover:underline">Log your first meal →</a>
                </div>
            )}
        </div>
    )
}
