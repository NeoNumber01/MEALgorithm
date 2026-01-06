'use client'

import { useEffect, useState } from 'react'
import { formatNumber } from '@/lib/format-utils'

interface NutritionalInfo {
    calories: number
    protein: number
    carbs: number
    fat: number
}

interface MealItem {
    name: string
    quantity: string
    nutrition: NutritionalInfo
}

interface MealAnalysis {
    items: MealItem[]
    summary: NutritionalInfo
    feedback: string
}

interface Meal {
    id: string
    mealType: string
    createdAt: string
    analysis: MealAnalysis
}

interface DayDetailModalProps {
    date: string
    label: string
    meals: Meal[]
    totals: NutritionalInfo
    onClose: () => void
    onMealClick?: (meal: any) => void
}

export default function DayDetailModal({ date, label, meals, totals, onClose, onMealClick }: DayDetailModalProps) {
    const [isVisible, setIsVisible] = useState(false)

    useEffect(() => {
        setIsVisible(true)
        document.body.style.overflow = 'hidden'
        return () => {
            document.body.style.overflow = 'unset'
        }
    }, [])

    const handleClose = () => {
        setIsVisible(false)
        setTimeout(onClose, 300)
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

    const formattedDate = new Date(date).toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    })

    return (
        <div
            className={`fixed inset-0 z-50 flex items-center justify-center p-4 transition-all duration-300 ${isVisible ? 'bg-black/60 backdrop-blur-sm opacity-100' : 'bg-black/0 backdrop-blur-none opacity-0 pointer-events-none'}`}
            onClick={handleClose}
        >
            <div
                className={`w-full max-w-2xl max-h-[85vh] bg-white/90 backdrop-blur-2xl rounded-3xl shadow-2xl border border-white/40 overflow-hidden transform transition-all duration-300 flex flex-col ${isVisible ? 'scale-100 translate-y-0 opacity-100' : 'scale-95 translate-y-8 opacity-0'}`}
                onClick={(e) => e.stopPropagation()}
            >
                {/* Header */}
                <div className="h-28 bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 relative flex-shrink-0">
                    <button
                        onClick={handleClose}
                        className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/20 hover:bg-black/30 text-white flex items-center justify-center backdrop-blur-md transition-colors"
                    >
                        ✕
                    </button>
                    <div className="absolute bottom-4 left-6 text-white">
                        <p className="text-sm font-medium opacity-90 uppercase tracking-widest mb-1">{label}</p>
                        <h2 className="text-2xl font-bold">{formattedDate}</h2>
                    </div>
                </div>

                {/* Content */}
                <div className="p-6 overflow-y-auto flex-1 custom-scrollbar">
                    {/* Summary Cards */}
                    <div className="grid grid-cols-4 gap-3 mb-6">
                        <div className="bg-orange-50 p-4 rounded-2xl text-center border border-orange-100">
                            <div className="text-2xl font-bold text-orange-600">{formatNumber(totals.calories)}</div>
                            <div className="text-xs text-orange-400 font-medium">Total kcal</div>
                        </div>
                        <div className="bg-red-50 p-4 rounded-2xl text-center border border-red-100">
                            <div className="text-xl font-bold text-red-600">{formatNumber(totals.protein)}g</div>
                            <div className="text-xs text-red-400 font-medium">Protein</div>
                        </div>
                        <div className="bg-amber-50 p-4 rounded-2xl text-center border border-amber-100">
                            <div className="text-xl font-bold text-amber-600">{formatNumber(totals.carbs)}g</div>
                            <div className="text-xs text-amber-400 font-medium">Carbs</div>
                        </div>
                        <div className="bg-blue-50 p-4 rounded-2xl text-center border border-blue-100">
                            <div className="text-xl font-bold text-blue-600">{formatNumber(totals.fat)}g</div>
                            <div className="text-xs text-blue-400 font-medium">Fat</div>
                        </div>
                    </div>

                    {/* Meals List */}
                    {meals.length === 0 ? (
                        <div className="text-center py-12 text-gray-500">
                            <div className="text-5xl mb-4">🍽️</div>
                            <p className="text-lg font-medium">No meals logged this day</p>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            <h3 className="font-bold text-gray-800 flex items-center gap-2">
                                <span>🍽️</span> Meals ({meals.length})
                            </h3>
                            {[...meals].sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()).map((meal) => (
                                <div
                                    key={meal.id}
                                    onClick={() => onMealClick && onMealClick(meal)}
                                    className={`bg-white/70 backdrop-blur-sm rounded-2xl p-4 border border-gray-100 shadow-sm hover:shadow-md transition-shadow group ${onMealClick ? 'cursor-pointer hover:bg-white/90 ring-1 ring-transparent hover:ring-purple-200' : ''}`}
                                >
                                    <div className="flex items-start gap-4">
                                        <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-orange-100 to-red-100 flex items-center justify-center text-2xl flex-shrink-0">
                                            {getMealTypeEmoji(meal.mealType)}
                                        </div>
                                        <div className="flex-1 min-w-0">
                                            <div className="flex items-center justify-between mb-1">
                                                <span className="capitalize font-semibold text-gray-900">
                                                    {meal.mealType || 'Meal'}
                                                </span>
                                                <span className="text-sm text-gray-400">
                                                    {new Date(meal.createdAt).toLocaleTimeString('en-US', {
                                                        hour: '2-digit',
                                                        minute: '2-digit'
                                                    })}
                                                </span>
                                            </div>

                                            {/* Meal Items */}
                                            {meal.analysis?.items && meal.analysis.items.length > 0 && (
                                                <div className="text-sm text-gray-500 mb-2">
                                                    {meal.analysis.items.map((item, idx) => (
                                                        <span key={idx}>
                                                            {item.name}
                                                            {idx < meal.analysis.items.length - 1 ? ', ' : ''}
                                                        </span>
                                                    ))}
                                                </div>
                                            )}

                                            {/* Nutrition Summary */}
                                            <div className="flex gap-3 text-xs">
                                                <span className="text-orange-600 font-medium">
                                                    {formatNumber(meal.analysis?.summary?.calories || 0)} kcal
                                                </span>
                                                <span className="text-red-500">
                                                    P: {formatNumber(meal.analysis?.summary?.protein || 0)}g
                                                </span>
                                                <span className="text-amber-500">
                                                    C: {formatNumber(meal.analysis?.summary?.carbs || 0)}g
                                                </span>
                                                <span className="text-blue-500">
                                                    F: {formatNumber(meal.analysis?.summary?.fat || 0)}g
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* Footer */}
                <div className="p-4 border-t border-gray-100 bg-white/50 flex-shrink-0">
                    <button
                        onClick={handleClose}
                        className="w-full px-6 py-3 bg-gray-900 text-white rounded-xl font-medium hover:bg-gray-800 transition-colors shadow-lg"
                    >
                        Close
                    </button>
                </div>
            </div>
        </div>
    )
}
