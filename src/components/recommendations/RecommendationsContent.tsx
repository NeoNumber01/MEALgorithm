'use client'

import { useEffect, useState } from 'react'
import { getRecommendations } from '@/lib/recommendations/actions'

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

export default function RecommendationsContent() {
    const [loading, setLoading] = useState(true)
    const [recommendations, setRecommendations] = useState<Recommendation[]>([])
    const [context, setContext] = useState<{
        targetCalories: number
        recentAvgCalories: number
        goal?: string
    } | null>(null)

    useEffect(() => {
        loadRecommendations()
    }, [])

    const loadRecommendations = async () => {
        setLoading(true)
        const result = await getRecommendations()

        if (!('error' in result)) {
            setRecommendations(result.recommendations)
            setContext(result.context)
        }

        setLoading(false)
    }

    if (loading) {
        return (
            <div className="flex flex-col items-center justify-center py-20">
                <div className="animate-spin text-4xl mb-4">🤔</div>
                <p className="text-gray-600">AI is thinking of meal ideas...</p>
            </div>
        )
    }

    return (
        <div className="space-y-6">
            {/* Context Card */}
            {context && (
                <div className="bg-gradient-to-r from-purple-500 to-indigo-600 rounded-xl p-6 text-white">
                    <h2 className="text-lg font-semibold mb-2">Personalized For You</h2>
                    <div className="grid grid-cols-3 gap-4 text-sm">
                        <div>
                            <p className="opacity-80">Daily Target</p>
                            <p className="text-xl font-bold">{context.targetCalories} kcal</p>
                        </div>
                        <div>
                            <p className="opacity-80">Recent Avg/Meal</p>
                            <p className="text-xl font-bold">{context.recentAvgCalories} kcal</p>
                        </div>
                        <div>
                            <p className="opacity-80">Goal</p>
                            <p className="text-xl font-bold">{context.goal || 'General Health'}</p>
                        </div>
                    </div>
                </div>
            )}

            {/* Recommendations Grid */}
            <div className="grid gap-4 md:grid-cols-3">
                {recommendations.map((rec, idx) => (
                    <div
                        key={idx}
                        className="bg-white border rounded-xl p-6 hover:shadow-lg transition-shadow"
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
                    onClick={loadRecommendations}
                    className="text-blue-600 hover:text-blue-800 font-medium"
                >
                    🔄 Get New Suggestions
                </button>
            </div>
        </div>
    )
}
