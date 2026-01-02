'use client'

import { useEffect, useState } from 'react'
import { getDailyStats, getWeeklyStats, getUserProfile } from '@/lib/dashboard/actions'
import { generateGoalFeedback } from '@/lib/dashboard/ai-feedback'
import { getCachedFeedback, updateCachedFeedback } from '@/lib/profile/actions'
import { getNutritionalTargets } from '@/lib/nutrition/calculator'
import { deleteMeal } from '@/lib/meals/actions'
import CalorieGauge from './CalorieGauge'
import Link from 'next/link'
import MealDetailModal from './MealDetailModal'
import ConfirmModal from '@/components/ui/ConfirmModal'

type ViewMode = 'today' | 'week'

interface DailyData {
    date: string
    label: string
    calories: number
    protein: number
    carbs: number
    fat: number
}

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
    const [weeklyData, setWeeklyData] = useState<{
        days: DailyData[]
        totals: { calories: number; protein: number; carbs: number; fat: number }
        averages: { calories: number; protein: number; carbs: number; fat: number }
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

    useEffect(() => {
        loadData()
    }, [])

    const loadData = async () => {
        setLoading(true)

        const today = new Date().toISOString().split('T')[0]
        const [dailyResult, weeklyResult, profileResult, cachedResult] = await Promise.all([
            getDailyStats(today),
            getWeeklyStats(),
            getUserProfile(),
            getCachedFeedback(),
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

        // Calculate targets from profile
        if (!('error' in profileResult) && profileResult.profile) {
            const calculatedTargets = getNutritionalTargets(profileResult.profile)
            setTargets(calculatedTargets)
        }

        // Check if we should use cached feedback or generate new
        let shouldGenerateFeedback = true

        if (!('error' in cachedResult) && cachedResult.feedback) {
            const lastMealTime = cachedResult.lastMealAt ? new Date(cachedResult.lastMealAt).getTime() : 0
            const feedbackTime = cachedResult.updatedAt ? new Date(cachedResult.updatedAt).getTime() : 0

            // Use cached feedback if it's newer than the last meal
            if (feedbackTime > lastMealTime) {
                setFeedback(cachedResult.feedback)
                shouldGenerateFeedback = false
            }
        }

        // Generate new AI feedback only if needed
        if (shouldGenerateFeedback && !('error' in dailyResult) && !('error' in weeklyResult)) {
            const feedbackResult = await generateGoalFeedback({
                todayCalories: dailyResult.totals.calories,
                weeklyAvgCalories: weeklyResult.averages.calories,
                targetCalories: targets.calories,
                goalDescription: profileResult.profile?.goal_description,
            })
            setFeedback(feedbackResult.feedback)

            // Cache the new feedback
            await updateCachedFeedback(feedbackResult.feedback)
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
            // Reload data to reflect changes
            const today = new Date().toISOString().split('T')[0]
            const dailyResult = await getDailyStats(today)
            if (!('error' in dailyResult)) {
                setTodayData({
                    totals: dailyResult.totals,
                    meals: dailyResult.meals,
                })
            }
            // If the deleted meal was selected, close the modal
            if (selectedMeal?.id === mealToDelete) {
                setSelectedMeal(null)
            }
        }
        setDeletingId(null)
        setMealToDelete(null)
    }

    const currentData = viewMode === 'today' ? todayData?.totals : weeklyData?.averages

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
                        {viewMode === 'today' ? "Today's Overview" : 'Weekly Summary'}
                    </h1>
                    <p className="text-gray-500 text-sm">
                        {viewMode === 'today'
                            ? new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })
                            : 'Your last 7 days'
                        }
                    </p>
                </div>

                <div className="flex items-center gap-3">
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
                            📊 Week
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

            {/* Calorie Gauge Card */}
            <div className="bg-white/15 backdrop-blur-3xl rounded-3xl border border-white/20 shadow-2xl p-8 transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20">
                <CalorieGauge
                    current={currentData?.calories || 0}
                    target={targets.calories}
                    label={viewMode === 'today' ? "Today's Calories" : 'Daily Average'}
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
                            {currentData?.protein || 0}g
                        </div>
                        <div className="text-sm opacity-75 mb-3">of {targets.protein}g target</div>
                        <div className="bg-white/20 rounded-full h-2">
                            <div
                                className="bg-white rounded-full h-2 transition-all duration-500"
                                style={{ width: `${Math.min(100, ((currentData?.protein || 0) / targets.protein) * 100)}%` }}
                            />
                        </div>
                        <div className="text-xs mt-2 opacity-75">
                            {Math.round(((currentData?.protein || 0) / targets.protein) * 100)}% complete
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
                            {currentData?.carbs || 0}g
                        </div>
                        <div className="text-sm opacity-75 mb-3">of {targets.carbs}g target</div>
                        <div className="bg-white/20 rounded-full h-2">
                            <div
                                className="bg-white rounded-full h-2 transition-all duration-500"
                                style={{ width: `${Math.min(100, ((currentData?.carbs || 0) / targets.carbs) * 100)}%` }}
                            />
                        </div>
                        <div className="text-xs mt-2 opacity-75">
                            {Math.round(((currentData?.carbs || 0) / targets.carbs) * 100)}% complete
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
                            {currentData?.fat || 0}g
                        </div>
                        <div className="text-sm opacity-75 mb-3">of {targets.fat}g target</div>
                        <div className="bg-white/20 rounded-full h-2">
                            <div
                                className="bg-white rounded-full h-2 transition-all duration-500"
                                style={{ width: `${Math.min(100, ((currentData?.fat || 0) / targets.fat) * 100)}%` }}
                            />
                        </div>
                        <div className="text-xs mt-2 opacity-75">
                            {Math.round(((currentData?.fat || 0) / targets.fat) * 100)}% complete
                        </div>
                    </div>
                </div>
            </div>

            {/* AI Feedback */}
            {feedback && (
                <div className="relative overflow-hidden bg-gradient-to-r from-emerald-50 to-teal-50 border border-emerald-200 rounded-2xl p-6 transition-all duration-300 hover:-translate-y-2 hover:shadow-lg">
                    <div className="absolute -right-4 -bottom-4 text-8xl opacity-10">🤖</div>
                    <div className="relative flex gap-4">
                        <div className="flex-shrink-0 w-12 h-12 bg-gradient-to-br from-emerald-400 to-teal-500 rounded-xl flex items-center justify-center text-2xl shadow-lg">
                            🤖
                        </div>
                        <div>
                            <h3 className="font-bold text-emerald-800 mb-1">AI Coach Insight</h3>
                            <p className="text-emerald-700 leading-relaxed">{feedback}</p>
                        </div>
                    </div>
                </div>
            )}

            {/* Weekly Chart (if week view) */}
            {viewMode === 'week' && weeklyData && (
                <div className="bg-white/15 backdrop-blur-2xl border border-white/20 rounded-3xl p-6 shadow-xl transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20">
                    <h3 className="font-bold text-gray-900 mb-6">📈 Weekly Calorie Intake</h3>
                    <div className="flex items-end justify-between h-40 gap-3">
                        {weeklyData.days.map((day) => {
                            const percentage = targets.calories > 0
                                ? Math.min(100, (day.calories / targets.calories) * 100)
                                : 0
                            const isToday = day.date === new Date().toISOString().split('T')[0]

                            return (
                                <div key={day.date} className="flex-1 flex flex-col items-center group">
                                    <div className="text-xs font-medium text-gray-500 mb-1 opacity-0 group-hover:opacity-100 transition">
                                        {day.calories} kcal
                                    </div>
                                    <div className="w-full bg-gray-100 rounded-xl relative" style={{ height: '120px' }}>
                                        <div
                                            className={`absolute bottom-0 w-full rounded-xl transition-all duration-500 ${isToday
                                                ? 'bg-gradient-to-t from-purple-500 to-pink-400'
                                                : 'bg-gradient-to-t from-blue-500 to-cyan-400'
                                                }`}
                                            style={{ height: `${percentage}%` }}
                                        />
                                        {percentage >= 100 && (
                                            <div className="absolute -top-2 left-1/2 -translate-x-1/2 text-sm">🎯</div>
                                        )}
                                    </div>
                                    <p className={`text-xs mt-2 font-medium ${isToday ? 'text-purple-600' : 'text-gray-500'}`}>
                                        {day.label}
                                    </p>
                                </div>
                            )
                        })}
                    </div>
                    <div className="mt-4 pt-4 border-t flex justify-between text-sm text-gray-500">
                        <span>Target line: {targets.calories} kcal</span>
                        <span>Weekly avg: {weeklyData.averages.calories} kcal</span>
                    </div>
                </div>
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
                                className="flex justify-between items-center p-4 bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl hover:bg-white/10 transition-all group cursor-pointer"
                            >
                                <div className="flex items-center gap-4">
                                    <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-orange-100 to-red-100 flex items-center justify-center text-lg">
                                        {index === 0 ? '🌅' : index === 1 ? '☀️' : index === 2 ? '🌙' : '🍿'}
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
                <div className="bg-gradient-to-br from-purple-50 to-pink-50 border border-purple-100 rounded-2xl p-12 text-center">
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
