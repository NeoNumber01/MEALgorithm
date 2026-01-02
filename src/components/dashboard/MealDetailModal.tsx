'use client'

import { useEffect, useState } from 'react'

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
    imagePath?: string
    analysis: MealAnalysis
}

interface MealDetailModalProps {
    meal: Meal
    onClose: () => void
}

export default function MealDetailModal({ meal, onClose }: MealDetailModalProps) {
    const [isVisible, setIsVisible] = useState(false)

    useEffect(() => {
        setIsVisible(true)
        // Prevent body scroll
        document.body.style.overflow = 'hidden'
        return () => {
            document.body.style.overflow = 'unset'
        }
    }, [])

    const handleClose = () => {
        setIsVisible(false)
        setTimeout(onClose, 300) // Wait for animation
    }

    if (!meal) return null

    return (
        <div className={`fixed inset-0 z-50 flex items-center justify-center p-4 transition-all duration-300 ${isVisible ? 'bg-black/60 backdrop-blur-sm opacity-100' : 'bg-black/0 backdrop-blur-none opacity-0 pointer-events-none'}`} onClick={handleClose}>
            <div
                className={`w-full max-w-lg bg-white/80 backdrop-blur-2xl rounded-3xl shadow-2xl border border-white/40 overflow-hidden transform transition-all duration-300 ${isVisible ? 'scale-100 translate-y-0 opacity-100' : 'scale-95 translate-y-8 opacity-0'}`}
                onClick={(e) => e.stopPropagation()}
            >
                {/* Header Image or Gradient */}
                <div className="h-32 bg-gradient-to-r from-cyan-500 via-blue-500 to-indigo-500 relative">
                    {meal.imagePath && (
                        <div className="absolute inset-0">
                            {/* In a real app we'd need a signed URL or public URL handled properly */}
                            {/* Assuming imagePath might be a direct URL or handled elsewhere, but for now fallback to gradient if plain path */}
                            {/* placeholder for now if it's not a full url */}
                            <div className="w-full h-full bg-black/20" />
                        </div>
                    )}
                    <button
                        onClick={handleClose}
                        className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/20 hover:bg-black/30 text-white flex items-center justify-center backdrop-blur-md transition-colors"
                    >
                        ✕
                    </button>
                    <div className="absolute bottom-4 left-6 text-white">
                        <p className="text-sm font-medium opacity-90 uppercase tracking-widest mb-1">{meal.mealType || 'Meal'}</p>
                        <h2 className="text-3xl font-bold text-shadow-sm">Meal Details</h2>
                        <p className="text-sm opacity-80">
                            {new Date(meal.createdAt).toLocaleString()}
                        </p>
                    </div>
                </div>

                {/* Content */}
                <div className="p-6 max-h-[70vh] overflow-y-auto custom-scrollbar">
                    {/* Summary Cards */}
                    <div className="grid grid-cols-4 gap-2 mb-6">
                        <div className="bg-orange-50 p-3 rounded-2xl text-center border border-orange-100">
                            <div className="text-xl font-bold text-orange-600">{meal.analysis.summary.calories}</div>
                            <div className="text-xs text-orange-400 font-medium">kcal</div>
                        </div>
                        <div className="bg-red-50 p-3 rounded-2xl text-center border border-red-100">
                            <div className="text-lg font-bold text-red-600">{meal.analysis.summary.protein}g</div>
                            <div className="text-xs text-red-400 font-medium">Protein</div>
                        </div>
                        <div className="bg-amber-50 p-3 rounded-2xl text-center border border-amber-100">
                            <div className="text-lg font-bold text-amber-600">{meal.analysis.summary.carbs}g</div>
                            <div className="text-xs text-amber-400 font-medium">Carbs</div>
                        </div>
                        <div className="bg-blue-50 p-3 rounded-2xl text-center border border-blue-100">
                            <div className="text-lg font-bold text-blue-600">{meal.analysis.summary.fat}g</div>
                            <div className="text-xs text-blue-400 font-medium">Fat</div>
                        </div>
                    </div>

                    {/* AI Analysis Feedback */}
                    {meal.analysis.feedback && (
                        <div className="mb-6 bg-gradient-to-br from-indigo-50 to-purple-50 p-4 rounded-2xl border border-indigo-100/50">
                            <h3 className="font-semibold text-indigo-900 mb-2 flex items-center gap-2">
                                <span>🤖</span> AI Analysis
                            </h3>
                            <p className="text-indigo-700 text-sm leading-relaxed">
                                {meal.analysis.feedback}
                            </p>
                        </div>
                    )}

                    {/* Meal Items List */}
                    <div>
                        <h3 className="font-bold text-gray-800 mb-4 flex items-center gap-2">
                            <span>🍽️</span> Ingredients Breakdown
                        </h3>
                        <div className="space-y-3">
                            {meal.analysis.items.map((item, idx) => (
                                <div key={idx} className="flex justify-between items-start p-3 bg-white/50 rounded-xl border border-gray-100 hover:bg-white/80 transition-colors">
                                    <div>
                                        <div className="font-medium text-gray-900">{item.name}</div>
                                        <div className="text-sm text-gray-500">{item.quantity}</div>
                                    </div>
                                    <div className="text-right text-sm">
                                        <div className="font-semibold text-gray-700">{item.nutrition?.calories} kcal</div>
                                        <div className="text-xs text-gray-400">
                                            P:{item.nutrition?.protein} C:{item.nutrition?.carbs} F:{item.nutrition?.fat}
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>

                {/* Footer Actions */}
                <div className="p-4 border-t border-gray-100 bg-white/50 flex justify-end">
                    <button
                        onClick={handleClose}
                        className="px-6 py-2 bg-gray-900 text-white rounded-xl font-medium hover:bg-gray-800 transition-colors shadow-lg hover:shadow-xl hover:-translate-y-0.5 transform"
                    >
                        Close
                    </button>
                </div>
            </div>
        </div>
    )
}
