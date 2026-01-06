'use client'

import { useState, useEffect, useRef } from 'react'
import { getNextMeal, getDayPlan } from '@/lib/suggestions/actions'
import PreferencesModal from './PreferencesModal'
import { formatNumber } from '@/lib/format-utils'

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

export default function RecommendationsContent() {
    const [viewMode, setViewMode] = useState<'next' | 'dayplan'>('next')
    const [showPreferences, setShowPreferences] = useState(false)

    // Next Meal state
    const [recommendations, setRecommendations] = useState<Recommendation[]>([])
    const [nextMealContext, setNextMealContext] = useState<{ targetCalories: number; consumedCalories: number; remainingCalories: number; goal?: string } | null>(null)
    const [nextMealLoading, setNextMealLoading] = useState(false)
    const [nextMealError, setNextMealError] = useState<string | null>(null)
    const nextMealLoaded = useRef(false)

    // Day Plan state
    const [dayPlan, setDayPlan] = useState<DayPlanMeal[]>([])
    const [dayContext, setDayContext] = useState<{ targetCalories: number; consumedCalories: number; remainingCalories: number; mealsLeft: number } | null>(null)
    const [daySummary, setDaySummary] = useState<{ totalPlannedCalories: number; advice: string } | null>(null)
    const [dayPlanLoading, setDayPlanLoading] = useState(false)
    const [dayPlanError, setDayPlanError] = useState<string | null>(null)
    const dayPlanLoaded = useRef(false)

    // Load data when view changes
    useEffect(() => {
        if (viewMode === 'next' && !nextMealLoaded.current) {
            loadNextMeal(false)
        } else if (viewMode === 'dayplan' && !dayPlanLoaded.current) {
            loadDayPlan(false)
        }
    }, [viewMode])

    const loadNextMeal = async (forceRefresh: boolean) => {
        setNextMealLoading(true)
        setNextMealError(null)

        const result = await getNextMeal(forceRefresh)

        if ('error' in result) {
            setNextMealError(result.error)
        } else {
            setRecommendations(result.recommendations)
            setNextMealContext(result.context)
            nextMealLoaded.current = true
        }

        setNextMealLoading(false)
    }

    const loadDayPlan = async (forceRefresh: boolean) => {
        setDayPlanLoading(true)
        setDayPlanError(null)

        const result = await getDayPlan(forceRefresh)

        if ('error' in result) {
            setDayPlanError(result.error)
        } else {
            setDayPlan(result.dayPlan)
            setDayContext(result.context)
            setDaySummary(result.summary)
            dayPlanLoaded.current = true
        }

        setDayPlanLoading(false)
    }

    const handleRefreshNextMeal = () => {
        nextMealLoaded.current = false
        loadNextMeal(true)
    }

    const handleRefreshDayPlan = () => {
        dayPlanLoaded.current = false
        loadDayPlan(true)
    }

    return (
        <div className="space-y-6">
            {/* View Toggle */}
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

            {/* Food Preferences Card */}
            <button
                onClick={() => setShowPreferences(true)}
                className="w-full bg-white/40 backdrop-blur-2xl border border-white/40 rounded-xl p-4 shadow-lg transition-all duration-300 hover:-translate-y-1 hover:shadow-2xl hover:bg-white/60 group text-left"
            >
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-400 to-teal-500 flex items-center justify-center text-xl shadow-md group-hover:scale-110 transition-transform">
                            🍽️
                        </div>
                        <div>
                            <h3 className="font-semibold text-gray-900">Food Preferences</h3>
                            <p className="text-sm text-gray-500">Set your likes, dislikes & dietary needs</p>
                        </div>
                    </div>
                    <div className="flex items-center gap-2 text-emerald-600 group-hover:translate-x-1 transition-transform">
                        <span className="text-sm font-medium">Edit</span>
                        <span>→</span>
                    </div>
                </div>
            </button>

            {/* Preferences Modal */}
            <PreferencesModal
                isOpen={showPreferences}
                onClose={() => setShowPreferences(false)}
            />

            {/* Next Meal View */}
            {viewMode === 'next' && (
                <div className="space-y-6">
                    {nextMealLoading && recommendations.length === 0 && (
                        <div className="flex flex-col items-center justify-center py-16 bg-white/40 backdrop-blur-2xl rounded-2xl border border-white/40 shadow-lg">
                            <div className="relative mb-4">
                                <div className="w-16 h-16 border-4 border-cyan-200 rounded-full animate-spin border-t-cyan-500" />
                                <div className="absolute inset-0 flex items-center justify-center text-2xl animate-pulse">🍽️</div>
                            </div>
                            <p className="text-gray-600 animate-pulse">Finding meal ideas...</p>
                        </div>
                    )}

                    {!nextMealLoading && nextMealError && recommendations.length === 0 && (
                        <div className="flex flex-col items-center justify-center py-16 bg-white/40 backdrop-blur-2xl rounded-2xl border border-white/40 shadow-lg">
                            <div className="text-4xl mb-4">😕</div>
                            <p className="text-gray-600 mb-4">{nextMealError}</p>
                            <button
                                onClick={handleRefreshNextMeal}
                                className="px-6 py-3 bg-gradient-to-r from-cyan-500 to-blue-500 text-white rounded-lg font-medium hover:from-cyan-600 hover:to-blue-600 transition"
                            >
                                🔄 Try Again
                            </button>
                        </div>
                    )}

                    {recommendations.length > 0 && (
                        <>
                            {nextMealContext && (
                                <div className="bg-gradient-to-r from-cyan-500 via-sky-500 to-lime-500 rounded-xl p-6 text-white shadow-lg backdrop-blur-sm transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl">
                                    <h2 className="text-lg font-semibold mb-2">Personalized For You</h2>
                                    <div className="grid grid-cols-4 gap-4 text-sm">
                                        <div>
                                            <p className="opacity-80">Target</p>
                                            <p className="text-xl font-bold">{formatNumber(nextMealContext.targetCalories)} kcal</p>
                                        </div>
                                        <div>
                                            <p className="opacity-80">Consumed</p>
                                            <p className="text-xl font-bold">{formatNumber(nextMealContext.consumedCalories)} kcal</p>
                                        </div>
                                        <div>
                                            <p className="opacity-80">Remaining</p>
                                            <p className="text-xl font-bold">{formatNumber(nextMealContext.remainingCalories)} kcal</p>
                                        </div>
                                        <div>
                                            <p className="opacity-80">Goal</p>
                                            <p className="text-xl font-bold">{nextMealContext.goal || 'General Health'}</p>
                                        </div>
                                    </div>
                                </div>
                            )}

                            <div className="grid gap-4 md:grid-cols-3">
                                {recommendations.map((rec, idx) => (
                                    <div key={idx} className="bg-white/40 backdrop-blur-2xl border border-white/40 rounded-xl p-6 shadow-lg transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/60">
                                        <div className="flex items-start justify-between mb-3">
                                            <h3 className="text-lg font-bold text-gray-900">{rec.name}</h3>
                                            <span className="text-2xl">{idx === 0 ? '🥇' : idx === 1 ? '🥈' : '🥉'}</span>
                                        </div>
                                        <p className="text-gray-600 mb-3">{rec.description}</p>
                                        <div className="bg-blue-50 rounded-lg p-3 mb-3">
                                            <p className="text-sm text-blue-800">💡 {rec.reason}</p>
                                        </div>
                                        <div className="grid grid-cols-4 gap-2 text-center text-sm">
                                            <div className="bg-orange-50 rounded p-2">
                                                <div className="font-bold text-orange-600">{formatNumber(rec.nutrition.calories)}</div>
                                                <div className="text-xs text-gray-500">kcal</div>
                                            </div>
                                            <div className="bg-red-50 rounded p-2">
                                                <div className="font-bold text-red-600">{formatNumber(rec.nutrition.protein)}g</div>
                                                <div className="text-xs text-gray-500">protein</div>
                                            </div>
                                            <div className="bg-yellow-50 rounded p-2">
                                                <div className="font-bold text-yellow-600">{formatNumber(rec.nutrition.carbs)}g</div>
                                                <div className="text-xs text-gray-500">carbs</div>
                                            </div>
                                            <div className="bg-blue-50 rounded p-2">
                                                <div className="font-bold text-blue-600">{formatNumber(rec.nutrition.fat)}g</div>
                                                <div className="text-xs text-gray-500">fat</div>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>

                            <div className="text-center">
                                <button
                                    onClick={handleRefreshNextMeal}
                                    disabled={nextMealLoading}
                                    className="text-blue-600 hover:text-blue-800 font-medium disabled:opacity-50 flex items-center gap-2 mx-auto"
                                >
                                    {nextMealLoading ? (
                                        <>
                                            <span className="w-4 h-4 border-2 border-blue-300 border-t-blue-600 rounded-full animate-spin" />
                                            Generating...
                                        </>
                                    ) : '🔄 Get New Suggestions'}
                                </button>
                            </div>
                        </>
                    )}
                </div>
            )}

            {/* Day Plan View */}
            {viewMode === 'dayplan' && (
                <div className="space-y-6">
                    {dayPlanLoading && dayPlan.length === 0 && (
                        <div className="flex flex-col items-center justify-center py-16 bg-white/40 backdrop-blur-2xl rounded-2xl border border-white/40 shadow-lg">
                            <div className="relative mb-4">
                                <div className="w-16 h-16 border-4 border-green-200 rounded-full animate-spin border-t-green-500" />
                                <div className="absolute inset-0 flex items-center justify-center text-2xl animate-pulse">📅</div>
                            </div>
                            <p className="text-gray-600 animate-pulse">Planning your day...</p>
                        </div>
                    )}

                    {!dayPlanLoading && dayPlanError && dayPlan.length === 0 && (
                        <div className="flex flex-col items-center justify-center py-16 bg-white/40 backdrop-blur-2xl rounded-2xl border border-white/40 shadow-lg">
                            <div className="text-4xl mb-4">😕</div>
                            <p className="text-gray-600 mb-4">{dayPlanError}</p>
                            <button
                                onClick={handleRefreshDayPlan}
                                className="px-6 py-3 bg-gradient-to-r from-green-500 to-teal-500 text-white rounded-lg font-medium hover:from-green-600 hover:to-teal-600 transition"
                            >
                                🔄 Try Again
                            </button>
                        </div>
                    )}

                    {(dayPlan.length > 0 || dayContext) && (
                        <>
                            {dayContext && (
                                <div className="bg-gradient-to-r from-green-500 to-teal-600 rounded-xl p-6 text-white shadow-lg backdrop-blur-sm transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl">
                                    <h2 className="text-lg font-semibold mb-4">Today&apos;s Progress</h2>
                                    <div className="grid grid-cols-4 gap-4">
                                        <div>
                                            <p className="text-sm opacity-80">Target</p>
                                            <p className="text-2xl font-bold">{formatNumber(dayContext.targetCalories)} kcal</p>
                                        </div>
                                        <div>
                                            <p className="text-sm opacity-80">Consumed</p>
                                            <p className="text-2xl font-bold">{formatNumber(dayContext.consumedCalories)} kcal</p>
                                        </div>
                                        <div>
                                            <p className="text-sm opacity-80">Remaining</p>
                                            <p className="text-2xl font-bold">{formatNumber(dayContext.remainingCalories)} kcal</p>
                                        </div>
                                        <div>
                                            <p className="text-sm opacity-80">Meals Left</p>
                                            <p className="text-2xl font-bold">{dayContext.mealsLeft}</p>
                                        </div>
                                    </div>
                                </div>
                            )}

                            {dayPlan.length > 0 && (
                                <div className="space-y-4">
                                    {dayPlan.map((meal, idx) => (
                                        <div key={idx} className="bg-white/40 backdrop-blur-2xl border border-white/40 rounded-xl p-6 shadow-lg transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/60">
                                            <div className="flex items-center justify-between mb-3">
                                                <div className="flex items-center gap-3">
                                                    <span className="text-2xl">
                                                        {meal.mealType === 'breakfast' ? '🌅' :
                                                            meal.mealType === 'lunch' ? '☀️' :
                                                                meal.mealType === 'dinner' ? '🌙' : '🍎'}
                                                    </span>
                                                    <div>
                                                        <p className="text-sm text-gray-500 capitalize">{meal.mealType}</p>
                                                        <h3 className="text-lg font-bold text-gray-900">{meal.name}</h3>
                                                    </div>
                                                </div>
                                                <div className="text-right">
                                                    <p className="text-2xl font-bold text-orange-500">{formatNumber(meal.nutrition.calories)}</p>
                                                    <p className="text-xs text-gray-500">kcal</p>
                                                </div>
                                            </div>
                                            <p className="text-gray-600 mb-3">{meal.description}</p>
                                            <div className="flex gap-4 text-sm">
                                                <span className="text-red-600">P: {formatNumber(meal.nutrition.protein)}g</span>
                                                <span className="text-yellow-600">C: {formatNumber(meal.nutrition.carbs)}g</span>
                                                <span className="text-blue-600">F: {formatNumber(meal.nutrition.fat)}g</span>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}

                            {daySummary && (
                                <div className="bg-blue-50/50 backdrop-blur-2xl rounded-xl p-4 border border-blue-200/40 shadow-md transition-all duration-300 hover:-translate-y-1 hover:shadow-lg">
                                    <p className="text-blue-800">💡 {daySummary.advice}</p>
                                </div>
                            )}

                            <div className="text-center">
                                <button
                                    onClick={handleRefreshDayPlan}
                                    disabled={dayPlanLoading}
                                    className="text-green-600 hover:text-green-800 font-medium disabled:opacity-50 flex items-center gap-2 mx-auto"
                                >
                                    {dayPlanLoading ? (
                                        <>
                                            <span className="w-4 h-4 border-2 border-green-300 border-t-green-600 rounded-full animate-spin" />
                                            Generating...
                                        </>
                                    ) : '🔄 Regenerate Day Plan'}
                                </button>
                            </div>
                        </>
                    )}
                </div>
            )}
        </div>
    )
}
