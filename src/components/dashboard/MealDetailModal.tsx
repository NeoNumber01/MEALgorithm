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
    imagePath?: string
    analysis: MealAnalysis
}

type MealType = 'breakfast' | 'lunch' | 'dinner' | 'snack'

interface MealDetailModalProps {
    meal: Meal
    onClose: () => void
    onMealTypeChange?: (mealId: string, newType: MealType) => Promise<void>
    onDelete?: (mealId: string) => Promise<void>
    onDateTimeChange?: (mealId: string, newDateTime: string) => Promise<void>
}

const MEAL_TYPE_OPTIONS: { value: MealType; label: string; emoji: string }[] = [
    { value: 'breakfast', label: 'Breakfast', emoji: '🌅' },
    { value: 'lunch', label: 'Lunch', emoji: '☀️' },
    { value: 'dinner', label: 'Dinner', emoji: '🌙' },
    { value: 'snack', label: 'Snack', emoji: '🍿' },
]

export default function MealDetailModal({ meal, onClose, onMealTypeChange, onDelete, onDateTimeChange }: MealDetailModalProps) {
    const [isVisible, setIsVisible] = useState(false)
    const [isEditingType, setIsEditingType] = useState(false)
    const [isEditingDateTime, setIsEditingDateTime] = useState(false)
    const [currentMealType, setCurrentMealType] = useState<string>(meal.mealType || 'meal')
    const [currentDateTime, setCurrentDateTime] = useState<string>(meal.createdAt)
    const [editingDateTime, setEditingDateTime] = useState<string>('')
    const [isUpdating, setIsUpdating] = useState(false)

    useEffect(() => {
        setIsVisible(true)
        // Prevent body scroll
        document.body.style.overflow = 'hidden'
        return () => {
            document.body.style.overflow = 'unset'
        }
    }, [])

    const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)

    // Sync current type with prop changes
    useEffect(() => {
        setCurrentMealType(meal.mealType || 'meal')
    }, [meal.mealType])

    // Sync current datetime with prop changes
    useEffect(() => {
        setCurrentDateTime(meal.createdAt)
    }, [meal.createdAt])

    const handleClose = () => {
        setIsVisible(false)
        setTimeout(onClose, 300) // Wait for animation
    }

    const handleMealTypeSelect = async (newType: MealType) => {
        if (!onMealTypeChange || newType === currentMealType) {
            setIsEditingType(false)
            return
        }

        setIsUpdating(true)
        try {
            await onMealTypeChange(meal.id, newType)
            setCurrentMealType(newType)
        } catch (error) {
            console.error('Failed to update meal type:', error)
        } finally {
            setIsUpdating(false)
            setIsEditingType(false)
        }
    }

    const getMealTypeEmoji = (type: string) => {
        const option = MEAL_TYPE_OPTIONS.find(o => o.value === type)
        return option?.emoji || '🍽️'
    }

    // Convert ISO string to datetime-local format (YYYY-MM-DDTHH:MM)
    const toDateTimeLocal = (isoString: string) => {
        const date = new Date(isoString)
        const year = date.getFullYear()
        const month = String(date.getMonth() + 1).padStart(2, '0')
        const day = String(date.getDate()).padStart(2, '0')
        const hours = String(date.getHours()).padStart(2, '0')
        const minutes = String(date.getMinutes()).padStart(2, '0')
        return `${year}-${month}-${day}T${hours}:${minutes}`
    }

    // Convert datetime-local format to ISO string
    const fromDateTimeLocal = (dateTimeLocal: string) => {
        const date = new Date(dateTimeLocal)
        return date.toISOString()
    }

    const handleStartEditDateTime = () => {
        if (!onDateTimeChange) return
        setEditingDateTime(toDateTimeLocal(currentDateTime))
        setIsEditingDateTime(true)
    }

    const handleDateTimeCancel = () => {
        setIsEditingDateTime(false)
        setEditingDateTime('')
    }

    const handleDateTimeSave = async () => {
        if (!onDateTimeChange || !editingDateTime) {
            setIsEditingDateTime(false)
            return
        }

        const newIsoDateTime = fromDateTimeLocal(editingDateTime)
        if (newIsoDateTime === currentDateTime) {
            setIsEditingDateTime(false)
            return
        }

        setIsUpdating(true)
        try {
            await onDateTimeChange(meal.id, newIsoDateTime)
            setCurrentDateTime(newIsoDateTime)
        } catch (error) {
            console.error('Failed to update meal date/time:', error)
        } finally {
            setIsUpdating(false)
            setIsEditingDateTime(false)
            setEditingDateTime('')
        }
    }

    const handleDeleteClick = () => {
        setShowDeleteConfirm(true)
    }

    const handleConfirmDelete = async () => {
        if (!onDelete) return
        setIsUpdating(true)
        try {
            await onDelete(meal.id)
            handleClose()
        } catch (error) {
            console.error('Failed to delete meal:', error)
            setIsUpdating(false)
            setShowDeleteConfirm(false)
        }
    }

    if (!meal) return null

    return (
        <div
            className={`fixed inset-0 z-50 flex items-center justify-center p-4 ${isVisible ? 'modal-backdrop-enter' : 'modal-backdrop-exit pointer-events-none'}`}
            style={{ backgroundColor: 'rgba(0, 0, 0, 0.45)' }}
            onClick={handleClose}
        >
            <div
                className={`relative w-full max-w-lg overflow-hidden rounded-3xl ${isVisible ? 'modal-content-enter' : 'modal-content-exit'}`}
                style={{
                    background: 'rgba(255, 255, 255, 0.75)',
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
                <div className="absolute inset-0 bg-gradient-to-br from-white/40 via-transparent to-blue-50/20 pointer-events-none rounded-3xl" />
                {/* Delete Confirmation Overlay */}
                {showDeleteConfirm && (
                    <div className="absolute inset-0 z-50 flex items-center justify-center p-6 modal-backdrop-enter" style={{ background: 'rgba(255, 255, 255, 0.5)', backdropFilter: 'blur(8px)' }}>
                        <div
                            className="modal-content-enter w-full max-w-sm text-center p-6 rounded-3xl"
                            style={{
                                background: 'rgba(255, 255, 255, 0.9)',
                                backdropFilter: 'blur(20px)',
                                boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
                                border: '1px solid rgba(255, 255, 255, 0.6)',
                            }}
                        >
                            <div className="w-16 h-16 bg-gradient-to-br from-red-100 via-rose-100 to-orange-100 rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg shadow-red-200/50">
                                <span className="text-3xl">🗑️</span>
                            </div>
                            <h3 className="text-xl font-bold text-gray-900 mb-2">Delete Meal?</h3>
                            <p className="text-gray-500 mb-6 text-sm leading-relaxed">
                                Are you sure you want to delete this meal? This action cannot be undone.
                            </p>
                            <div className="flex gap-3">
                                <button
                                    onClick={() => setShowDeleteConfirm(false)}
                                    className="flex-1 py-3 px-4 rounded-xl font-semibold text-gray-700 bg-white/60 backdrop-blur-sm border border-gray-200/50 hover:bg-white/80 transition-all shadow-sm hover:shadow-md"
                                    disabled={isUpdating}
                                >
                                    Cancel
                                </button>
                                <button
                                    onClick={handleConfirmDelete}
                                    className="flex-1 py-3 px-4 rounded-xl font-semibold text-white bg-gradient-to-r from-red-500 via-rose-500 to-red-600 hover:from-red-600 hover:via-rose-600 hover:to-red-700 shadow-lg shadow-red-500/30 hover:shadow-red-500/40 transition-all hover:-translate-y-0.5 active:scale-95"
                                    disabled={isUpdating}
                                >
                                    {isUpdating ? 'Deleting...' : 'Delete'}
                                </button>
                            </div>
                        </div>
                    </div>
                )}

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
                        className="absolute top-4 right-4 w-9 h-9 rounded-full bg-white/20 hover:bg-white/30 backdrop-blur-sm text-white flex items-center justify-center transition-all duration-200 border border-white/30 hover:border-white/50 shadow-lg"
                    >
                        ✕
                    </button>
                    <div className="absolute bottom-4 left-6 text-white">
                        {/* Meal Type Editor */}
                        {isEditingType ? (
                            <div className="flex items-center gap-2 mb-1">
                                {MEAL_TYPE_OPTIONS.map((option) => (
                                    <button
                                        key={option.value}
                                        onClick={() => handleMealTypeSelect(option.value)}
                                        disabled={isUpdating}
                                        className={`px-3 py-1 rounded-full text-sm font-medium transition-all ${currentMealType === option.value
                                            ? 'bg-white text-gray-900'
                                            : 'bg-white/20 hover:bg-white/30'
                                            } ${isUpdating ? 'opacity-50 cursor-not-allowed' : ''}`}
                                    >
                                        {option.emoji} {option.label}
                                    </button>
                                ))}
                                <button
                                    onClick={() => setIsEditingType(false)}
                                    className="ml-2 text-white/70 hover:text-white text-sm"
                                >
                                    ✕
                                </button>
                            </div>
                        ) : (
                            <button
                                onClick={() => onMealTypeChange && setIsEditingType(true)}
                                className={`text-sm font-medium opacity-90 uppercase tracking-widest mb-1 flex items-center gap-2 ${onMealTypeChange ? 'hover:bg-white/20 px-2 py-1 -ml-2 rounded-lg cursor-pointer transition-colors' : ''
                                    }`}
                                disabled={!onMealTypeChange}
                            >
                                <span>{getMealTypeEmoji(currentMealType)}</span>
                                <span>{currentMealType || 'Meal'}</span>
                                {onMealTypeChange && <span className="text-xs opacity-70">✏️</span>}
                            </button>
                        )}
                        <h2 className="text-3xl font-bold text-shadow-sm">Meal Details</h2>
                        {/* DateTime Editor */}
                        {isEditingDateTime ? (
                            <div className="flex items-center gap-2 mt-1 animate-in fade-in duration-200">
                                <input
                                    type="datetime-local"
                                    value={editingDateTime}
                                    onChange={(e) => setEditingDateTime(e.target.value)}
                                    disabled={isUpdating}
                                    className="px-3 py-1.5 rounded-lg bg-white/90 text-gray-900 text-sm font-medium border-0 focus:ring-2 focus:ring-white/50 disabled:opacity-50"
                                />
                                <button
                                    onClick={handleDateTimeSave}
                                    disabled={isUpdating}
                                    className="w-8 h-8 rounded-full bg-green-500 hover:bg-green-600 text-white flex items-center justify-center transition-colors disabled:opacity-50 shadow-lg"
                                    title="Save"
                                >
                                    {isUpdating ? (
                                        <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                    ) : (
                                        '✓'
                                    )}
                                </button>
                                <button
                                    onClick={handleDateTimeCancel}
                                    disabled={isUpdating}
                                    className="w-8 h-8 rounded-full bg-white/20 hover:bg-white/30 text-white flex items-center justify-center transition-colors disabled:opacity-50"
                                    title="Cancel"
                                >
                                    ✕
                                </button>
                            </div>
                        ) : (
                            <button
                                onClick={handleStartEditDateTime}
                                className={`text-sm opacity-80 mt-1 flex items-center gap-2 ${onDateTimeChange ? 'hover:bg-white/20 px-2 py-1 -ml-2 rounded-lg cursor-pointer transition-colors' : ''}`}
                                disabled={!onDateTimeChange}
                            >
                                <span>🕐</span>
                                <span>{new Date(currentDateTime).toLocaleString()}</span>
                                {onDateTimeChange && <span className="text-xs opacity-70">✏️</span>}
                            </button>
                        )}
                    </div>
                </div>

                {/* Content */}
                <div className="p-6 max-h-[70vh] overflow-y-auto custom-scrollbar">
                    {/* Summary Cards */}
                    <div className="grid grid-cols-4 gap-2 mb-6">
                        <div className="bg-orange-50 p-3 rounded-2xl text-center border border-orange-100">
                            <div className="text-xl font-bold text-orange-600">{formatNumber(meal.analysis.summary.calories)}</div>
                            <div className="text-xs text-orange-400 font-medium">kcal</div>
                        </div>
                        <div className="bg-red-50 p-3 rounded-2xl text-center border border-red-100">
                            <div className="text-lg font-bold text-red-600">{formatNumber(meal.analysis.summary.protein)}g</div>
                            <div className="text-xs text-red-400 font-medium">Protein</div>
                        </div>
                        <div className="bg-amber-50 p-3 rounded-2xl text-center border border-amber-100">
                            <div className="text-lg font-bold text-amber-600">{formatNumber(meal.analysis.summary.carbs)}g</div>
                            <div className="text-xs text-amber-400 font-medium">Carbs</div>
                        </div>
                        <div className="bg-blue-50 p-3 rounded-2xl text-center border border-blue-100">
                            <div className="text-lg font-bold text-blue-600">{formatNumber(meal.analysis.summary.fat)}g</div>
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
                                        <div className="font-semibold text-gray-700">{formatNumber(item.nutrition?.calories)} kcal</div>
                                        <div className="text-xs text-gray-400">
                                            P:{formatNumber(item.nutrition?.protein)} C:{formatNumber(item.nutrition?.carbs)} F:{formatNumber(item.nutrition?.fat)}
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>

                {/* Footer Actions */}
                <div className="relative p-4 border-t border-white/30 bg-white/40 backdrop-blur-sm flex justify-between items-center">
                    {onDelete && (
                        <button
                            onClick={handleDeleteClick}
                            disabled={isUpdating}
                            className="px-4 py-2.5 text-red-500 hover:text-red-700 bg-white/50 hover:bg-red-50/80 backdrop-blur-sm rounded-xl font-medium transition-all duration-200 flex items-center gap-2 border border-red-200/30 hover:border-red-300/50 shadow-sm hover:shadow-md"
                        >
                            🗑️ Delete Meal
                        </button>
                    )}
                    <button
                        onClick={handleClose}
                        className="px-6 py-2.5 bg-gradient-to-r from-gray-800 via-gray-900 to-gray-800 text-white rounded-xl font-semibold hover:from-gray-900 hover:via-black hover:to-gray-900 transition-all duration-200 shadow-lg hover:shadow-xl hover:-translate-y-0.5 ml-auto"
                    >
                        Close
                    </button>
                </div>
            </div>
        </div>
    )
}
