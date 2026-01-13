'use client'

import { useState, useEffect } from 'react'
import { getMealsByDateRange, MealDay } from '@/lib/meals/calendar-actions'
import { deleteMeal, updateMealType } from '@/lib/meals/actions'
import { formatNumber } from '@/lib/format-utils'

interface CalendarDay {
    date: string
    dayOfMonth: number
    isCurrentMonth: boolean
    hasMeals: boolean
    totalCalories: number
    meals: MealDay['meals']
}

interface MealCalendarProps {
    onDateSelect?: (date: string, meals: MealDay['meals']) => void
}

export default function MealCalendar({ onDateSelect }: MealCalendarProps) {
    const [currentDate, setCurrentDate] = useState(new Date())
    const [calendarDays, setCalendarDays] = useState<CalendarDay[]>([])
    const [mealData, setMealData] = useState<Record<string, MealDay>>({})
    const [loading, setLoading] = useState(true)
    const [selectedDate, setSelectedDate] = useState<string | null>(null)
    const [editingMealId, setEditingMealId] = useState<string | null>(null)
    const [deletingMealId, setDeletingMealId] = useState<string | null>(null)
    const [mealTypeFilter, setMealTypeFilter] = useState<string | null>(null)

    // Load meals for current month
    useEffect(() => {
        loadMonthMeals()
    }, [currentDate])

    const loadMonthMeals = async () => {
        setLoading(true)
        const year = currentDate.getFullYear()
        const month = currentDate.getMonth() + 1

        // Format dates in local timezone (YYYY-MM-DD)
        const startDate = new Date(year, month - 1, 1)
        const endDate = new Date(year, month, 0)
        
        const formatLocalDate = (date: Date) => {
            const year = date.getFullYear()
            const monthStr = String(date.getMonth() + 1).padStart(2, '0')
            const dayStr = String(date.getDate()).padStart(2, '0')
            return `${year}-${monthStr}-${dayStr}`
        }

        const startDateStr = formatLocalDate(startDate)
        const endDateStr = formatLocalDate(endDate)

        console.log('Loading meals for:', { startDateStr, endDateStr })

        const result = await getMealsByDateRange(startDateStr, endDateStr)

        if (!('error' in result) && result.meals) {
            const mealsMap: Record<string, MealDay> = {}
            result.meals.forEach((day: MealDay) => {
                mealsMap[day.date] = day
            })
            setMealData(mealsMap)
        }

        generateCalendarDays()
        setLoading(false)
    }

    const generateCalendarDays = () => {
        const year = currentDate.getFullYear()
        const month = currentDate.getMonth()

        // Helper to format date as YYYY-MM-DD in local timezone
        const formatLocalDate = (date: Date) => {
            const year = date.getFullYear()
            const monthStr = String(date.getMonth() + 1).padStart(2, '0')
            const dayStr = String(date.getDate()).padStart(2, '0')
            return `${year}-${monthStr}-${dayStr}`
        }

        // First day of month and number of days
        const firstDay = new Date(year, month, 1)
        const lastDay = new Date(year, month + 1, 0)
        const daysInMonth = lastDay.getDate()
        const startingDayOfWeek = firstDay.getDay()

        const days: CalendarDay[] = []

        // Previous month's days
        const prevMonthLastDay = new Date(year, month, 0).getDate()
        for (let i = startingDayOfWeek - 1; i >= 0; i--) {
            const dayNum = prevMonthLastDay - i
            const date = formatLocalDate(new Date(year, month - 1, dayNum))
            days.push({
                date,
                dayOfMonth: dayNum,
                isCurrentMonth: false,
                hasMeals: !!mealData[date],
                totalCalories: mealData[date]?.totalCalories || 0,
                meals: mealData[date]?.meals || [],
            })
        }

        // Current month's days
        for (let dayNum = 1; dayNum <= daysInMonth; dayNum++) {
            const date = formatLocalDate(new Date(year, month, dayNum))
            days.push({
                date,
                dayOfMonth: dayNum,
                isCurrentMonth: true,
                hasMeals: !!mealData[date],
                totalCalories: mealData[date]?.totalCalories || 0,
                meals: mealData[date]?.meals || [],
            })
        }

        // Next month's days
        const remainingDays = 42 - days.length // 6 rows * 7 days
        for (let dayNum = 1; dayNum <= remainingDays; dayNum++) {
            const date = formatLocalDate(new Date(year, month + 1, dayNum))
            days.push({
                date,
                dayOfMonth: dayNum,
                isCurrentMonth: false,
                hasMeals: !!mealData[date],
                totalCalories: mealData[date]?.totalCalories || 0,
                meals: mealData[date]?.meals || [],
            })
        }

        setCalendarDays(days)
    }

    const goToPreviousMonth = () => {
        setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1))
    }

    const goToNextMonth = () => {
        setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1))
    }

    const handleDayClick = (day: CalendarDay) => {
        setSelectedDate(day.date)
        if (onDateSelect) {
            onDateSelect(day.date, day.meals)
        }
    }

    const handleDeleteMeal = async (mealId: string) => {
        setDeletingMealId(mealId)
        const result = await deleteMeal(mealId)
        
        if (!('error' in result)) {
            // Reload meals after deletion
            await loadMonthMeals()
        }
        
        setDeletingMealId(null)
    }

    const handleUpdateMealType = async (mealId: string, newType: string) => {
        const validTypes = ['breakfast', 'lunch', 'dinner', 'snack']
        if (!validTypes.includes(newType)) return

        const result = await updateMealType(
            mealId,
            newType as 'breakfast' | 'lunch' | 'dinner' | 'snack'
        )

        if (!('error' in result)) {
            // Reload meals after update
            await loadMonthMeals()
        }
        
        setEditingMealId(null)
    }

    const monthName = currentDate.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
    const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

    return (
        <div className="w-full bg-white/15 backdrop-blur-2xl rounded-2xl border border-white/20 p-6 shadow-lg">
            {/* Header */}
            <div className="flex items-center justify-between mb-6">
                <button
                    onClick={goToPreviousMonth}
                    className="p-2 hover:bg-white/20 rounded-lg transition"
                    aria-label="Previous month"
                >
                    ←
                </button>
                <h2 className="text-xl font-bold text-gray-900">{monthName}</h2>
                <button
                    onClick={goToNextMonth}
                    className="p-2 hover:bg-white/20 rounded-lg transition"
                    aria-label="Next month"
                >
                    →
                </button>
            </div>

            {/* Weekday headers */}
            <div className="grid grid-cols-7 gap-2 mb-2">
                {weekDays.map((day) => (
                    <div
                        key={day}
                        className="text-center font-semibold text-sm text-gray-600 py-2"
                    >
                        {day}
                    </div>
                ))}
            </div>

            {/* Calendar grid */}
            {loading ? (
                <div className="flex items-center justify-center py-16">
                    <div className="text-gray-400">Loading calendar...</div>
                </div>
            ) : (
                <div className="grid grid-cols-7 gap-2">
                    {calendarDays.map((day) => (
                        <button
                            key={day.date}
                            onClick={() => handleDayClick(day)}
                            className={`
                                aspect-square p-2 rounded-lg border transition-all
                                ${!day.isCurrentMonth ? 'opacity-40' : ''}
                                ${selectedDate === day.date ? 'border-blue-500 bg-blue-50' : 'border-gray-200'}
                                ${day.hasMeals ? 'bg-green-50 border-green-300' : 'bg-white hover:bg-gray-50'}
                            `}
                        >
                            <div className="flex flex-col items-center justify-center h-full">
                                <div className="text-sm font-semibold text-gray-900">
                                    {day.dayOfMonth}
                                </div>
                                {day.hasMeals && (
                                    <div className="text-xs text-green-700 font-medium mt-1">
                                        {formatNumber(day.totalCalories)}kcal
                                    </div>
                                )}
                            </div>
                        </button>
                    ))}
                </div>
            )}

            {/* Selected day details */}
            {selectedDate && mealData[selectedDate] && (
                <div className="mt-6 pt-6 border-t border-white/20">
                    <h3 className="font-semibold text-gray-900 mb-4">
                        Meals on {new Date(selectedDate + 'T00:00:00').toLocaleDateString('en-US', {
                            weekday: 'long',
                            year: 'numeric',
                            month: 'long',
                            day: 'numeric',
                        })}
                    </h3>
                    <div className="space-y-3">
                        {mealData[selectedDate].meals.map((meal) => (
                            <div
                                key={meal.id}
                                className="bg-white/50 rounded-lg p-4 transition-all hover:bg-white/70"
                            >
                                <div className="flex justify-between items-start gap-3">
                                    <div className="flex-1">
                                        {editingMealId === meal.id ? (
                                            <select
                                                value={meal.meal_type || 'breakfast'}
                                                onChange={(e) => handleUpdateMealType(meal.id, e.target.value)}
                                                className="text-sm font-medium border border-gray-300 rounded px-2 py-1 mb-2 w-full"
                                            >
                                                <option value="breakfast">🌅 Breakfast</option>
                                                <option value="lunch">☀️ Lunch</option>
                                                <option value="dinner">🌙 Dinner</option>
                                                <option value="snack">🍎 Snack</option>
                                            </select>
                                        ) : (
                                            <div className="font-medium text-gray-900 capitalize mb-2 cursor-pointer hover:text-blue-600 transition"
                                                onClick={() => setEditingMealId(meal.id)}>
                                                {meal.meal_type === 'breakfast' && '🌅 '}
                                                {meal.meal_type === 'lunch' && '☀️ '}
                                                {meal.meal_type === 'dinner' && '🌙 '}
                                                {meal.meal_type === 'snack' && '🍎 '}
                                                {meal.meal_type || 'Meal'}
                                                <span className="text-xs text-gray-400 ml-1">(click to edit)</span>
                                            </div>
                                        )}
                                        {meal.text_content && (
                                            <div className="text-gray-600 text-sm mb-2">
                                                {meal.text_content.substring(0, 80)}
                                                {meal.text_content.length > 80 ? '...' : ''}
                                            </div>
                                        )}
                                        <div className="text-xs text-gray-500">
                                            {new Date(meal.created_at).toLocaleTimeString('en-US', {
                                                hour: '2-digit',
                                                minute: '2-digit',
                                            })}
                                        </div>
                                    </div>
                                    <div className="flex flex-col items-end gap-2">
                                        <div className="text-right">
                                            <div className="font-semibold text-gray-900">
                                                {formatNumber(meal.analysis?.summary?.calories || 0)}kcal
                                            </div>
                                            <div className="text-xs text-gray-500">
                                                {formatNumber(meal.analysis?.summary?.protein || 0)}p
                                            </div>
                                        </div>
                                        <button
                                            onClick={() => handleDeleteMeal(meal.id)}
                                            disabled={deletingMealId === meal.id}
                                            className="px-3 py-1 text-xs font-medium text-red-600 hover:bg-red-50 rounded transition disabled:opacity-50"
                                        >
                                            {deletingMealId === meal.id ? '⏳' : '🗑️ Delete'}
                                        </button>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            )}
        </div>
    )
}
