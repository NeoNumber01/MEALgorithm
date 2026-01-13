'use client'

import { useState, useCallback, useEffect } from 'react'
import { generateCoachAdvice, CoachAdviceParams } from '@/lib/ai/coach-actions'
import { generateDataHash, CACHE_KEYS } from '@/lib/cache-utils'

interface AICoachCardProps {
    context: 'today' | 'statistics'
    // Today context data
    todayData?: {
        calories: number
        protein: number
        carbs: number
        fat: number
        mealCount: number
        mealTypes: string[]  // e.g., ['breakfast', 'lunch']
        targetProtein: number
        targetCarbs: number
        targetFat: number
    }
    targetCalories: number
    goal?: 'maintenance' | 'weight-loss' | 'muscle-gain'
    // Statistics context data
    statsData?: {
        avgCalories: number
        avgProtein: number
        avgCarbs: number
        avgFat: number
        totalMeals: number
        daysWithMeals: number
        totalDays: number
        consistencyScore: number
        avgMealsPerDay: string
        avgProteinPerMeal: number
        timeRangeLabel: string
        macroBalance?: {
            protein: number
            carbs: number
            fat: number
        }
    }
}

export default function AICoachCard({
    context,
    todayData,
    targetCalories,
    goal,
    statsData
}: AICoachCardProps) {
    const [advice, setAdvice] = useState<string>('')
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [hasGenerated, setHasGenerated] = useState(false)

    // Generate cache key and data hash based on context
    const getCacheKey = useCallback(() => {
        if (context === 'today') {
            return CACHE_KEYS.DASHBOARD_FEEDBACK
        }
        return `ai_coach_stats_${targetCalories}`
    }, [context, targetCalories])

    const getDataHash = useCallback(() => {
        if (context === 'today' && todayData) {
            return generateDataHash({
                calories: todayData.calories,
                mealCount: todayData.mealCount,
                targetCalories,
            })
        }
        if (context === 'statistics' && statsData) {
            return generateDataHash({
                avgCalories: statsData.avgCalories,
                totalMeals: statsData.totalMeals,
                targetCalories,
            })
        }
        return ''
    }, [context, todayData, statsData, targetCalories])

    // Check cache on mount
    useEffect(() => {
        const cacheKey = getCacheKey()
        const hashKey = `${cacheKey}_hash`
        const cachedAdvice = localStorage.getItem(cacheKey)
        const cachedHash = localStorage.getItem(hashKey)
        const currentHash = getDataHash()

        // If we have cached advice and hash matches, use it
        if (cachedAdvice && cachedHash === currentHash) {
            setAdvice(cachedAdvice)
            setHasGenerated(true)
        }
    }, [getCacheKey, getDataHash])

    const generateAdvice = async () => {
        setLoading(true)
        setError(null)

        try {
            const params: CoachAdviceParams = {
                context,
                todayData,
                targetCalories,
                goal,
                statsData,
            }

            const result = await generateCoachAdvice(params)

            if ('error' in result) {
                setError(result.error)
                return
            }

            setAdvice(result.advice)
            setHasGenerated(true)

            // Cache the result
            const cacheKey = getCacheKey()
            const hashKey = `${cacheKey}_hash`
            localStorage.setItem(cacheKey, result.advice)
            localStorage.setItem(hashKey, getDataHash())

        } catch (err) {
            console.error('AI Coach error:', err)
            setError('Unable to generate advice. Please try again.')
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="relative overflow-hidden bg-gradient-to-r from-emerald-50 to-teal-50 border border-emerald-200 rounded-2xl p-5 transition-all duration-300 hover:-translate-y-2 hover:shadow-xl">
            <div className="absolute -right-4 -bottom-4 text-7xl opacity-10">🤖</div>

            <div className="relative flex gap-4">
                {/* Icon */}
                <div className="flex-shrink-0 w-11 h-11 bg-gradient-to-br from-emerald-400 to-teal-500 rounded-xl flex items-center justify-center text-xl shadow-lg">
                    🤖
                </div>

                {/* Content */}
                <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between mb-2">
                        <h3 className="font-bold text-emerald-800">
                            AI Coach
                        </h3>
                        <button
                            onClick={generateAdvice}
                            disabled={loading}
                            className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-emerald-700 bg-emerald-100 hover:bg-emerald-200 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                            title={hasGenerated ? "Refresh advice" : "Get AI advice"}
                        >
                            {loading ? (
                                <>
                                    <div className="w-3 h-3 border-2 border-emerald-300 border-t-emerald-600 rounded-full animate-spin" />
                                    <span>Thinking...</span>
                                </>
                            ) : (
                                <>
                                    <span>{hasGenerated ? '🔄' : '✨'}</span>
                                    <span>{hasGenerated ? 'Refresh' : 'Ask AI'}</span>
                                </>
                            )}
                        </button>
                    </div>

                    {/* Advice content */}
                    <div className="text-emerald-700 text-sm leading-relaxed">
                        {loading && !advice ? (
                            <div className="flex items-center gap-2">
                                <div className="flex gap-1">
                                    <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                                    <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                                    <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
                                </div>
                                <span className="text-emerald-600 animate-pulse">Analyzing your data...</span>
                            </div>
                        ) : error ? (
                            <p className="text-red-500">{error}</p>
                        ) : advice ? (
                            <p className="whitespace-pre-wrap">{advice}</p>
                        ) : (
                            <p className="text-emerald-500 italic">
                                Click &quot;Ask AI&quot; to get personalized nutrition advice based on your {context === 'today' ? "today's meals" : 'eating patterns'}.
                            </p>
                        )}
                    </div>
                </div>
            </div>
        </div>
    )
}
