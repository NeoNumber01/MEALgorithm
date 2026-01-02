'use client'

import { useEffect, useState, useRef } from 'react'
import { getRecommendations, getDayPlan } from '@/lib/recommendations/actions'
import PreferencesPanel from './PreferencesPanel'

type ViewMode = 'next' | 'dayplan'

interface Recommendation {
    name: string
    description: string
    reason: string
    nutrition: {
        calories: number
        protein: number
        carbs: number
        fat: number
    }
}

interface DayPlanMeal {
    mealType: string
    name: string
    description: string
    nutrition: {
        calories: number
        protein: number
        carbs: number
        fat: number
    }
}

interface DayPlanSummary {
    totalPlannedCalories: number
    advice: string
}

interface DayPlanContext {
    targetCalories: number
    consumedCalories: number
    remainingCalories: number
    eatenMealTypes: string[]
    remainingMealTypes: string[]
}

export default function RecommendationsContent() {
    const [viewMode, setViewMode] = useState<ViewMode>('next')

    // Separate loading states for each tab
    const [nextMealLoading, setNextMealLoading] = useState(false)
    const [dayPlanLoading, setDayPlanLoading] = useState(false)

    // Track if data has been loaded (to prevent auto-refresh)
    const nextMealLoaded = useRef(false)
    const dayPlanLoaded = useRef(false)

    // Next meal state
    const [recommendations, setRecommendations] = useState<Recommendation[]>([])
    const [nextMealContext, setNextMealContext] = useState<{
        targetCalories: number
        recentAvgCalories: number
        goal?: string
    } | null>(null)

    // Day plan state
    const [dayPlan, setDayPlan] = useState<DayPlanMeal[]>([])
    const [daySummary, setDaySummary] = useState<DayPlanSummary | null>(null)
    const [dayContext, setDayContext] = useState<DayPlanContext | null>(null)

    // Initial load only - once per tab
    useEffect(() => {
        if (viewMode === 'next' && !nextMealLoaded.current) {
            loadNextMeal()
        } else if (viewMode === 'dayplan' && !dayPlanLoaded.current) {
            loadDayPlan()
        }
    }, [viewMode])

    const loadNextMeal = async (forceRefresh = false) => {
        setNextMealLoading(true)
        const result = await getRecommendations(forceRefresh)

        if (!('error' in result)) {
            setRecommendations(result.recommendations)
            setNextMealContext(result.context)
            nextMealLoaded.current = true
        }

        setNextMealLoading(false)
    }

    const loadDayPlan = async (forceRefresh = false) => {
        setDayPlanLoading(true)
        const result = await getDayPlan(forceRefresh)

        if (!('error' in result)) {
            setDayPlan(result.dayPlan)
            setDaySummary(result.summary)
            setDayContext(result.context)
            dayPlanLoaded.current = true
        }

        setDayPlanLoading(false)
    }

    // Manual refresh handlers - force regeneration
    const handleRefreshNextMeal = () => {
        nextMealLoaded.current = false
        loadNextMeal(true) // Force refresh
    }

    const handleRefreshDayPlan = () => {
        dayPlanLoaded.current = false
        loadDayPlan(true) // Force refresh
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

    return (
        <div className="space-y-6">
            {/* Food Preferences Panel */}
            <PreferencesPanel onUpdate={() => {
                // Reset cache flags so next load will fetch fresh data
                nextMealLoaded.current = false
                dayPlanLoaded.current = false
            }} />

            {/* View Toggle - Always visible */}
            <div className="flex gap-2 bg-gray-100 p-1 rounded-lg w-fit">
                <button
                    onClick={() => setViewMode('next')}
                    className={`px-4 py-2 rounded-md font-medium transition flex items-center gap-2 ${viewMode === 'next' ? 'bg-white shadow' : 'text-gray-600'
                        }`}
                >
                    🍽️ Next Meal
                    {nextMealLoading && <span className="w-4 h-4 border-2 border-gray-300 border-t-gray-600 rounded-full animate-spin" />}
                </button>
                <button
                    onClick={() => setViewMode('dayplan')}
                    className={`px-4 py-2 rounded-md font-medium transition flex items-center gap-2 ${viewMode === 'dayplan' ? 'bg-white shadow' : 'text-gray-600'
                        }`}
                >
                    📅 Day Plan
                    {dayPlanLoading && <span className="w-4 h-4 border-2 border-gray-300 border-t-gray-600 rounded-full animate-spin" />}
                </button>
            </div>

            {/* Next Meal View */}
            {viewMode === 'next' && (
                <>
                    {/* Loading State for Next Meal */}
                    {nextMealLoading && recommendations.length === 0 && (
                        <div className="flex flex-col items-center justify-center py-16 bg-white/10 backdrop-blur-xl rounded-2xl border border-white/20">
                            <div className="relative mb-4">
                                <div className="w-16 h-16 border-4 border-cyan-200 rounded-full animate-spin border-t-cyan-500" />
                                <div className="absolute inset-0 flex items-center justify-center text-2xl animate-pulse">🍽️</div>
                            </div>
                            <p className="text-gray-600 animate-pulse">Finding meal ideas...</p>
                        </div>
                    )}

                    {/* Content */}
                    {recommendations.length > 0 && (
                        <>
                            {/* Context Card */}
                            {nextMealContext && (
                                <div className="bg-gradient-to-r from-cyan-500 via-sky-500 to-lime-500 rounded-xl p-6 text-white shadow-lg transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl">
                                    <h2 className="text-lg font-semibold mb-2">Personalized For You</h2>
                                    <div className="grid grid-cols-3 gap-4 text-sm">
                                        <div>
                                            <p className="opacity-80">Daily Target</p>
                                            <p className="text-xl font-bold">{nextMealContext.targetCalories} kcal</p>
                                        </div>
                                        <div>
                                            <p className="opacity-80">Recent Avg/Meal</p>
                                            <p className="text-xl font-bold">{nextMealContext.recentAvgCalories} kcal</p>
                                        </div>
                                        <div>
                                            <p className="opacity-80">Goal</p>
                                            <p className="text-xl font-bold">{nextMealContext.goal || 'General Health'}</p>
                                        </div>
                                    </div>
                                </div>
                            )}

                            {/* Recommendations Grid */}
                            <div className="grid gap-4 md:grid-cols-3">
                                {recommendations.map((rec, idx) => (
                                    <div
                                        key={idx}
                                        className="bg-white/15 backdrop-blur-2xl border border-white/20 rounded-xl p-6 transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20"
                                    >
                                        <div className="flex items-start justify-between mb-3">
                                            <h3 className="text-lg font-bold text-gray-900">{rec.name}</h3>
                                            <span className="text-2xl">
                                                {idx === 0 ? '🥇' : idx === 1 ? '🥈' : '🥉'}
                                            </span>
                                        </div>

                                        <p className="text-gray-600 mb-3">{rec.description}</p>

                                        <div className="bg-blue-50 rounded-lg p-3 mb-3">
                                            <p className="text-sm text-blue-800">💡 {rec.reason}</p>
                                        </div>

                                        <div className="grid grid-cols-4 gap-2 text-center text-sm">
                                            <div className="bg-orange-50 rounded p-2">
                                                <div className="font-bold text-orange-600">{rec.nutrition.calories}</div>
                                                <div className="text-xs text-gray-500">kcal</div>
                                            </div>
                                            <div className="bg-red-50 rounded p-2">
                                                <div className="font-bold text-red-600">{rec.nutrition.protein}g</div>
                                                <div className="text-xs text-gray-500">protein</div>
                                            </div>
                                            <div className="bg-yellow-50 rounded p-2">
                                                <div className="font-bold text-yellow-600">{rec.nutrition.carbs}g</div>
                                                <div className="text-xs text-gray-500">carbs</div>
                                            </div>
                                            <div className="bg-blue-50 rounded p-2">
                                                <div className="font-bold text-blue-600">{rec.nutrition.fat}g</div>
                                                <div className="text-xs text-gray-500">fat</div>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>

                            {/* Refresh Button */}
                            <div className="text-center">
                                <button
                                    onClick={handleRefreshNextMeal}
                                    disabled={nextMealLoading}
                                    className="text-blue-600 hover:text-blue-800 font-medium disabled:opacity-50"
                                >
                                    {nextMealLoading ? (
                                        <span className="flex items-center gap-2">
                                            <span className="w-4 h-4 border-2 border-blue-300 border-t-blue-600 rounded-full animate-spin" />
                                            Generating...
                                        </span>
                                    ) : '🔄 Get New Suggestions'}
                                </button>
                            </div>
                        </>
                    )}
                </>
            )}

            {/* Day Plan View */}
            {viewMode === 'dayplan' && (
                <>
                    {/* Loading State for Day Plan */}
                    {dayPlanLoading && dayPlan.length === 0 && dayContext === null && (
                        <div className="flex flex-col items-center justify-center py-16 bg-white/10 backdrop-blur-xl rounded-2xl border border-white/20">
                            <div className="relative mb-4">
                                <div className="w-16 h-16 border-4 border-green-200 rounded-full animate-spin border-t-green-500" />
                                <div className="absolute inset-0 flex items-center justify-center text-2xl animate-pulse">📅</div>
                            </div>
                            <p className="text-gray-600 animate-pulse">Planning your day...</p>
                        </div>
                    )}

                    {/* Content */}
                    {(dayPlan.length > 0 || dayContext !== null) && (
                        <>
                            {/* Progress Context */}
                            {dayContext && (
                                <div className="bg-gradient-to-r from-green-500 to-teal-600 rounded-xl p-6 text-white transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl">
                                    <h2 className="text-lg font-semibold mb-4">Today&apos;s Progress</h2>
                                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                                        <div>
                                            <p className="text-sm opacity-80">Consumed</p>
                                            <p className="text-2xl font-bold">{dayContext.consumedCalories} kcal</p>
                                        </div>
                                        <div>
                                            <p className="text-sm opacity-80">Remaining</p>
                                            <p className="text-2xl font-bold">{dayContext.remainingCalories} kcal</p>
                                        </div>
                                        <div>
                                            <p className="text-sm opacity-80">Target</p>
                                            <p className="text-2xl font-bold">{dayContext.targetCalories} kcal</p>
                                        </div>
                                        <div>
                                            <p className="text-sm opacity-80">Meals Left</p>
                                            <p className="text-2xl font-bold">{dayContext.remainingMealTypes.length}</p>
                                        </div>
                                    </div>

                                    {dayContext.eatenMealTypes.length > 0 && (
                                        <p className="mt-4 text-sm opacity-80">
                                            ✅ Already eaten: {dayContext.eatenMealTypes.map(t => t.charAt(0).toUpperCase() + t.slice(1)).join(', ')}
                                        </p>
                                    )}
                                </div>
                            )}

                            {/* Day Plan Timeline */}
                            <div className="space-y-4">
                                {dayPlan.length === 0 ? (
                                    <div className="text-center py-8 text-gray-500">
                                        <p className="text-4xl mb-2">🎉</p>
                                        <p>You&apos;ve completed all meals for today!</p>
                                    </div>
                                ) : (
                                    dayPlan.map((meal, idx) => (
                                        <div
                                            key={idx}
                                            className="bg-white/15 backdrop-blur-2xl border border-white/20 rounded-xl p-6 flex gap-4 transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20"
                                        >
                                            <div className="text-4xl">
                                                {getMealTypeEmoji(meal.mealType)}
                                            </div>
                                            <div className="flex-1">
                                                <div className="flex justify-between items-start">
                                                    <div>
                                                        <span className="text-sm font-medium text-gray-500 uppercase">
                                                            {meal.mealType}
                                                        </span>
                                                        <h3 className="text-xl font-bold text-gray-900">{meal.name}</h3>
                                                        <p className="text-gray-600 mt-1">{meal.description}</p>
                                                    </div>
                                                    <div className="text-right">
                                                        <span className="text-2xl font-bold text-orange-600">
                                                            {meal.nutrition.calories}
                                                        </span>
                                                        <span className="text-gray-500 text-sm"> kcal</span>
                                                    </div>
                                                </div>

                                                <div className="flex gap-4 mt-3 text-sm">
                                                    <span className="text-red-600">🥩 {meal.nutrition.protein}g protein</span>
                                                    <span className="text-yellow-600">🍞 {meal.nutrition.carbs}g carbs</span>
                                                    <span className="text-blue-600">🧈 {meal.nutrition.fat}g fat</span>
                                                </div>
                                            </div>
                                        </div>
                                    ))
                                )}
                            </div>

                            {/* Day Summary */}
                            {daySummary && dayPlan.length > 0 && (
                                <div className="bg-blue-50/20 backdrop-blur-xl border border-blue-200/20 rounded-xl p-6 transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-blue-50/40">
                                    <div className="flex items-center gap-4 mb-3">
                                        <span className="text-3xl">💡</span>
                                        <div>
                                            <h3 className="font-semibold text-blue-900">AI Coach Advice</h3>
                                            <p className="text-blue-800">{daySummary.advice}</p>
                                        </div>
                                    </div>
                                    <p className="text-sm text-blue-600">
                                        Planned calories: {daySummary.totalPlannedCalories} kcal
                                    </p>
                                </div>
                            )}

                            {/* Refresh Button */}
                            <div className="text-center">
                                <button
                                    onClick={handleRefreshDayPlan}
                                    disabled={dayPlanLoading}
                                    className="text-green-600 hover:text-green-800 font-medium disabled:opacity-50"
                                >
                                    {dayPlanLoading ? (
                                        <span className="flex items-center gap-2">
                                            <span className="w-4 h-4 border-2 border-green-300 border-t-green-600 rounded-full animate-spin" />
                                            Generating...
                                        </span>
                                    ) : '🔄 Regenerate Day Plan'}
                                </button>
                            </div>
                        </>
                    )}
                </>
            )}
        </div>
    )
}
