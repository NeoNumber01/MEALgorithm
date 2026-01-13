'use client'

import { useEffect, useState } from 'react'
import { getDailyStats, getUserProfile } from '@/lib/dashboard/actions'
import { getNutritionalTargets } from '@/lib/nutrition/calculator'
import { deleteMeal, updateMealType, updateMealDateTime } from '@/lib/meals/actions'
import CalorieGauge from './CalorieGauge'
import AICoachCard from './AICoachCard'
import Link from 'next/link'
import MealDetailModal from './MealDetailModal'
import StatisticsView from './StatisticsView'
import ConfirmModal from '@/components/ui/ConfirmModal'
import { notifyDataUpdated, getLastDataUpdateTime, invalidateAIFeedbackCache, CACHE_KEYS } from '@/lib/cache-utils'
import { formatNumber } from '@/lib/format-utils'

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
    const [editingMealId, setEditingMealId] = useState<string | null>(null)
    const [goal, setGoal] = useState<'maintenance' | 'weight-loss' | 'muscle-gain' | undefined>()

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

            if (cachedToday) {
                const parsedToday = JSON.parse(cachedToday)
                const cachedDate = parsedToday.date // Check stored date

                // If cache exists, isn't from another day, and is fresh relative to db updates
                if (cachedDate === today && cachedTime > lastDbUpdate) {
                    setTodayData(parsedToday)
                    if (cachedTargets) setTargets(JSON.parse(cachedTargets))
                    setLoading(false)
                    // Background refresh if cache is old (> 1 hour) but valid
                    if (Date.now() - cachedTime < 3600000) return
                }
            }
        } catch (e) {
            console.error('Cache read error', e)
        }

        const now = new Date()

        const startOfDay = new Date(now)
        startOfDay.setHours(0, 0, 0, 0)

        const endOfDay = new Date(now)
        endOfDay.setHours(23, 59, 59, 999)

        const [dailyResult, profileResult] = await Promise.all([
            getDailyStats(startOfDay.toISOString(), endOfDay.toISOString()),
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
            setGoal(profileResult.profile.goal || undefined)
            localStorage.setItem(CACHE_KEYS.DASHBOARD_TARGETS, JSON.stringify(calculatedTargets))
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

    const handleMealTypeChange = async (mealId: string, newType: 'breakfast' | 'lunch' | 'dinner' | 'snack') => {
        const result = await updateMealType(mealId, newType)

        if (result?.success) {
            notifyDataUpdated()
            // Update local state immediately
            if (todayData) {
                const updatedMeals = todayData.meals.map(meal =>
                    meal.id === mealId ? { ...meal, mealType: newType } : meal
                )
                setTodayData({ ...todayData, meals: updatedMeals })

                // Update cache
                localStorage.setItem(CACHE_KEYS.DASHBOARD_TODAY, JSON.stringify({
                    date: new Date().toLocaleDateString('en-CA'),
                    totals: todayData.totals,
                    meals: updatedMeals,
                }))
            }
            // Update selectedMeal if it's the one being edited
            if (selectedMeal?.id === mealId) {
                setSelectedMeal({ ...selectedMeal, mealType: newType })
            }
            setLastUpdateTimestamp(Date.now())
        }
        setEditingMealId(null)
    }

    const handleDateTimeChange = async (mealId: string, newDateTime: string) => {
        const result = await updateMealDateTime(mealId, newDateTime)

        if (result?.success) {
            notifyDataUpdated()
            // Clear cache and reload to reflect potential date change
            localStorage.removeItem(CACHE_KEYS.DASHBOARD_TODAY)
            localStorage.removeItem(CACHE_KEYS.DASHBOARD_TIMESTAMP)
            invalidateAIFeedbackCache()

            // Update selectedMeal if it's the one being edited
            if (selectedMeal?.id === mealId) {
                setSelectedMeal({ ...selectedMeal, createdAt: newDateTime })
            }

            // Reload data to reflect changes (meal might have moved to a different day)
            await loadData()
            setLastUpdateTimestamp(Date.now())
        }
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
                            // Clear all dashboard and AI feedback caches to force fresh data
                            localStorage.removeItem(CACHE_KEYS.DASHBOARD_TODAY)
                            localStorage.removeItem(CACHE_KEYS.DASHBOARD_TIMESTAMP)
                            invalidateAIFeedbackCache()
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
                                    {formatNumber(todayData?.totals?.protein || 0)}g
                                </div>
                                <div className="text-sm opacity-75 mb-3">of {formatNumber(targets.protein)}g target</div>
                                <div className="bg-white/20 rounded-full h-2">
                                    <div
                                        className="bg-white rounded-full h-2 transition-all duration-500"
                                        style={{ width: `${Math.min(100, ((todayData?.totals?.protein || 0) / targets.protein) * 100)}%` }}
                                    />
                                </div>
                                <div className="text-xs mt-2 opacity-75">
                                    {formatNumber(((todayData?.totals?.protein || 0) / targets.protein) * 100)}% complete
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
                                    {formatNumber(todayData?.totals?.carbs || 0)}g
                                </div>
                                <div className="text-sm opacity-75 mb-3">of {formatNumber(targets.carbs)}g target</div>
                                <div className="bg-white/20 rounded-full h-2">
                                    <div
                                        className="bg-white rounded-full h-2 transition-all duration-500"
                                        style={{ width: `${Math.min(100, ((todayData?.totals?.carbs || 0) / targets.carbs) * 100)}%` }}
                                    />
                                </div>
                                <div className="text-xs mt-2 opacity-75">
                                    {formatNumber(((todayData?.totals?.carbs || 0) / targets.carbs) * 100)}% complete
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
                                    {formatNumber(todayData?.totals?.fat || 0)}g
                                </div>
                                <div className="text-sm opacity-75 mb-3">of {formatNumber(targets.fat)}g target</div>
                                <div className="bg-white/20 rounded-full h-2">
                                    <div
                                        className="bg-white rounded-full h-2 transition-all duration-500"
                                        style={{ width: `${Math.min(100, ((todayData?.totals?.fat || 0) / targets.fat) * 100)}%` }}
                                    />
                                </div>
                                <div className="text-xs mt-2 opacity-75">
                                    {formatNumber(((todayData?.totals?.fat || 0) / targets.fat) * 100)}% complete
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* AI Coach */}
                    <AICoachCard
                        context="today"
                        todayData={{
                            calories: todayData?.totals?.calories || 0,
                            protein: todayData?.totals?.protein || 0,
                            carbs: todayData?.totals?.carbs || 0,
                            fat: todayData?.totals?.fat || 0,
                            mealCount: todayData?.meals?.length || 0,
                            mealTypes: todayData?.meals?.map(m => m.mealType || 'lunch') || [],
                            targetProtein: targets.protein,
                            targetCarbs: targets.carbs,
                            targetFat: targets.fat,
                        }}
                        targetCalories={targets.calories}
                        goal={goal}
                    />

                </>
            )}

            {/* Statistics View (if statistics view) */}
            {viewMode === 'week' && (
                <StatisticsView
                    targetCalories={targets.calories}
                    lastUpdateTimestamp={lastUpdateTimestamp}
                    onDataUpdate={loadData}
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
                        {[...todayData.meals].sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()).map((meal) => (
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
                                        {editingMealId === meal.id ? (
                                            <select
                                                value={meal.mealType || 'lunch'}
                                                onChange={(e) => {
                                                    e.stopPropagation()
                                                    handleMealTypeChange(meal.id, e.target.value as 'breakfast' | 'lunch' | 'dinner' | 'snack')
                                                }}
                                                onClick={(e) => e.stopPropagation()}
                                                onBlur={() => setEditingMealId(null)}
                                                autoFocus
                                                className="bg-white border border-gray-200 rounded-lg px-2 py-1 text-sm font-semibold text-gray-900 focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                                            >
                                                <option value="breakfast">🌅 Breakfast</option>
                                                <option value="lunch">☀️ Lunch</option>
                                                <option value="dinner">🌙 Dinner</option>
                                                <option value="snack">🍿 Snack</option>
                                            </select>
                                        ) : (
                                            <div className="flex items-center gap-1">
                                                <span className="capitalize font-semibold text-gray-900">
                                                    {meal.mealType || 'Meal'}
                                                </span>
                                                <button
                                                    onClick={(e) => {
                                                        e.stopPropagation()
                                                        setEditingMealId(meal.id)
                                                    }}
                                                    className="opacity-0 group-hover:opacity-100 text-gray-400 hover:text-purple-600 transition-all p-1"
                                                    title="Edit meal type"
                                                >
                                                    ✏️
                                                </button>
                                            </div>
                                        )}
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
                                            {formatNumber(meal.analysis?.summary?.calories || 0)}
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
                    onMealTypeChange={handleMealTypeChange}
                    onDateTimeChange={handleDateTimeChange}
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
