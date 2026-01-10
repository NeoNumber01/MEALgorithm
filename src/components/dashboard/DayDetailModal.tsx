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
            className={`fixed inset-0 z-50 flex items-center justify-center p-4 ${isVisible ? 'modal-backdrop-enter' : 'modal-backdrop-exit pointer-events-none'}`}
            style={{ backgroundColor: 'rgba(0, 0, 0, 0.45)' }}
            onClick={handleClose}
        >
            <div
                className={`w-full max-w-2xl max-h-[85vh] overflow-hidden rounded-3xl flex flex-col ${isVisible ? 'modal-content-enter' : 'modal-content-exit'}`}
                style={{
                    background: 'rgba(255, 255, 255, 0.8)',
                    backdropFilter: 'blur(24px) saturate(180%)',
                    WebkitBackdropFilter: 'blur(24px) saturate(180%)',
                    border: '1px solid rgba(255, 255, 255, 0.45)',
                    boxShadow: `
                        0 25px 50px -12px rgba(0, 0, 0, 0.3),
                        0 0 0 1px rgba(255, 255, 255, 0.2) inset,
                        0 0 80px rgba(255, 255, 255, 0.15) inset
                    `,
                }}
                onClick={(e) => e.stopPropagation()}
            >
                {/* Gradient overlay for enhanced glass effect */}
                <div className="absolute inset-0 bg-gradient-to-br from-white/40 via-transparent to-purple-50/20 pointer-events-none rounded-3xl" />

                {/* Header */}
                <div className="relative h-28 bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 flex-shrink-0">
                    <button
                        onClick={handleClose}
                        className="absolute top-4 right-4 w-9 h-9 rounded-full bg-white/20 hover:bg-white/30 backdrop-blur-sm text-white flex items-center justify-center transition-all duration-200 border border-white/30 hover:border-white/50 shadow-lg"
                    >
                        ✕
                    </button>
                    <div className="absolute bottom-4 left-6 text-white">
                        <p className="text-sm font-medium opacity-90 uppercase tracking-widest mb-1">{label}</p>
                        <h2 className="text-2xl font-bold drop-shadow-sm">{formattedDate}</h2>
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
                <div className="relative p-4 border-t border-white/30 bg-white/40 backdrop-blur-sm flex-shrink-0">
                    <button
                        onClick={handleClose}
                        className="w-full px-6 py-3.5 bg-gradient-to-r from-gray-800 via-gray-900 to-gray-800 text-white rounded-xl font-semibold hover:from-gray-900 hover:via-black hover:to-gray-900 transition-all duration-200 shadow-lg hover:shadow-xl hover:-translate-y-0.5"
                    >
                        Close
                    </button>
                </div>
            </div>
        </div>
    )
}
