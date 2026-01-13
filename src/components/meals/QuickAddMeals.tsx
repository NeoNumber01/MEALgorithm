'use client'

import { useEffect, useState } from 'react'
import { getFrequentMeals } from '@/lib/meals/frequent-actions'
import { saveMeal } from '@/lib/meals/actions'

interface FrequentMeal {
    text_content: string
    count: number
    mealType: string
}

export default function QuickAddMeals() {
    const [meals, setMeals] = useState<FrequentMeal[]>([])
    const [loading, setLoading] = useState(true)
    const [loggingId, setLoggingId] = useState<string | null>(null)

    useEffect(() => {
        loadFrequentMeals()
    }, [])

    const loadFrequentMeals = async () => {
        setLoading(true)
        const result = await getFrequentMeals(6)
        if (!('error' in result)) {
            setMeals(result.meals)
        }
        setLoading(false)
    }

    const handleQuickAdd = async (meal: FrequentMeal) => {
        setLoggingId(meal.text_content)
        const result = await saveMeal({
            text_content: meal.text_content,
            meal_type: meal.mealType as 'breakfast' | 'lunch' | 'dinner' | 'snack',
            image_path: null,
        })

        if (!('error' in result)) {
            // Refresh the list after logging
            await loadFrequentMeals()
        }
        setLoggingId(null)
    }

    if (loading) {
        return (
            <div className="space-y-3">
                <h3 className="text-sm font-semibold text-gray-700">⚡ Quick Add (Loading...)</h3>
            </div>
        )
    }

    if (meals.length === 0) {
        return null
    }

    // Get emoji for meal type
    const getMealEmoji = (mealType: string) => {
        switch (mealType) {
            case 'breakfast':
                return '🌅'
            case 'lunch':
                return '☀️'
            case 'dinner':
                return '🌙'
            case 'snack':
                return '🍿'
            default:
                return '🍽️'
        }
    }

    return (
        <div className="bg-white/15 backdrop-blur-2xl rounded-xl border border-white/20 p-4 transition-all duration-300 hover:bg-white/20">
            <h3 className="text-sm font-semibold text-gray-700 mb-3">⚡ Quick Add (Recent Meals)</h3>
            <div className="space-y-2">
                {meals.map((meal) => (
                    <button
                        key={meal.text_content}
                        onClick={() => handleQuickAdd(meal)}
                        disabled={loggingId === meal.text_content}
                        className="w-full text-left p-3 bg-white/30 hover:bg-white/50 disabled:opacity-50 rounded-lg transition-colors duration-200 group"
                    >
                        <div className="flex items-start justify-between gap-2">
                            <div className="flex-1 min-w-0">
                                <p className="text-sm font-medium text-gray-800 truncate group-hover:text-gray-900">
                                    {getMealEmoji(meal.mealType)} {meal.text_content}
                                </p>
                                <p className="text-xs text-gray-600 mt-1">
                                    Logged {meal.count} time{meal.count > 1 ? 's' : ''}
                                </p>
                            </div>
                            {loggingId === meal.text_content && (
                                <div className="flex-shrink-0 pt-1">
                                    <div className="w-4 h-4 border-2 border-blue-400 border-t-blue-600 rounded-full animate-spin" />
                                </div>
                            )}
                        </div>
                    </button>
                ))}
            </div>
        </div>
    )
}
