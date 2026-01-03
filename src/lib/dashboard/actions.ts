'use server'

import { createClient } from '@/lib/supabase/server'

interface MealAnalysis {
    items: Array<{
        name: string
        quantity: string
        nutrition: {
            calories: number
            protein: number
            carbs: number
            fat: number
        }
    }>
    summary: {
        calories: number
        protein: number
        carbs: number
        fat: number
    }
    feedback: string
}

export async function getDailyStats(start: string, end: string) {
    const supabase = await createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { error: 'Not authenticated' }

    const { data: meals, error } = await supabase
        .from('meals')
        .select('*')
        .eq('user_id', user.id)
        .gte('created_at', start)
        .lte('created_at', end)
        .order('created_at', { ascending: true })

    if (error) {
        return { error: error.message }
    }

    let totalCalories = 0
    let totalProtein = 0
    let totalCarbs = 0
    let totalFat = 0

    const mealsList = meals.map(meal => {
        const analysis = meal.analysis as MealAnalysis | null
        if (analysis?.summary) {
            totalCalories += analysis.summary.calories
            totalProtein += analysis.summary.protein
            totalCarbs += analysis.summary.carbs
            totalFat += analysis.summary.fat
        }
        return {
            id: meal.id,
            mealType: meal.meal_type,
            createdAt: meal.created_at,
            analysis,
        }
    })

    return {
        meals: mealsList,
        totals: {
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
        },
    }
}

export async function getWeeklyStats(start: string, end: string, timezoneOffset: number) {
    const supabase = await createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { error: 'Not authenticated' }

    const { data: meals, error } = await supabase
        .from('meals')
        .select('*')
        .eq('user_id', user.id)
        .gte('created_at', start)
        .lte('created_at', end)
        .order('created_at', { ascending: true })

    if (error) {
        return { error: error.message }
    }

    const dailyData: Record<string, { calories: number; protein: number; carbs: number; fat: number }> = {}

    // Helper to get local YYYY-MM-DD from UTC timestamp and offset
    const getLocalDate = (utcIso: string) => {
        const date = new Date(utcIso)
        // Adjust for timezone offset (offset is in minutes, negative for east of UTC)
        // We want to add the offset to get local time representation
        // Note: getTimezoneOffset() returns positive for West, negative for East
        // But the argument passed in is usually the browser's result.
        // If browser says -480 (UTC+8), we need to ADD 480 minutes to UTC time to get local time numbers.
        // Wait, standard JS: new Date().getTimezoneOffset() -> -480 for China.
        // To shift UTC to Local: UTC_ms - (offset * 60000). 
        // Example: UTC 12:00. Offset -480. 12:00 - (-8h) = 20:00. Correct.
        const localTime = new Date(date.getTime() - (timezoneOffset * 60000))
        return localTime.toISOString().split('T')[0]
    }

    meals.forEach(meal => {
        const date = getLocalDate(meal.created_at)
        if (!dailyData[date]) {
            dailyData[date] = { calories: 0, protein: 0, carbs: 0, fat: 0 }
        }
        const analysis = meal.analysis as MealAnalysis | null
        if (analysis?.summary) {
            dailyData[date].calories += analysis.summary.calories
            dailyData[date].protein += analysis.summary.protein
            dailyData[date].carbs += analysis.summary.carbs
            dailyData[date].fat += analysis.summary.fat
        }
    })

    const days = []
    // Generate last 7 days keys based on the provided range logic
    // We assume the range passed covers 7 days.
    // We need to reconstruct the dates from the 'end' date backwards.
    // Calculate local end date first.
    const localEndDate = new Date(new Date(end).getTime() - (timezoneOffset * 60000))

    for (let i = 6; i >= 0; i--) {
        const d = new Date(localEndDate)
        d.setDate(d.getDate() - i)
        const dateStr = d.toISOString().split('T')[0]
        days.push({
            date: dateStr,
            label: d.toLocaleDateString('en-US', { weekday: 'short' }),
            ...(dailyData[dateStr] || { calories: 0, protein: 0, carbs: 0, fat: 0 }),
        })
    }

    const totals = days.reduce(
        (acc, day) => ({
            calories: acc.calories + day.calories,
            protein: acc.protein + day.protein,
            carbs: acc.carbs + day.carbs,
            fat: acc.fat + day.fat,
        }),
        { calories: 0, protein: 0, carbs: 0, fat: 0 }
    )

    return {
        days,
        totals,
        averages: {
            calories: Math.round(totals.calories / 7),
            protein: Math.round(totals.protein / 7),
            carbs: Math.round(totals.carbs / 7),
            fat: Math.round(totals.fat / 7),
        },
    }
}

export async function getUserProfile() {
    const supabase = await createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { error: 'Not authenticated' }

    const { data: profile } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single()

    return { profile }
}

interface MealTypeStats {
    breakfast: number
    lunch: number
    dinner: number
    snack: number
}

export async function getStatsForRange(start: string, end: string, timezoneOffset: number) {
    const supabase = await createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { error: 'Not authenticated' }

    const { data: meals, error } = await supabase
        .from('meals')
        .select('*')
        .eq('user_id', user.id)
        .gte('created_at', start)
        .lte('created_at', end)
        .order('created_at', { ascending: true })

    if (error) {
        return { error: error.message }
    }

    // Helper to get local YYYY-MM-DD
    const getLocalDate = (utcIso: string) => {
        const date = new Date(utcIso)
        const localTime = new Date(date.getTime() - (timezoneOffset * 60000))
        return localTime.toISOString().split('T')[0]
    }

    // Daily breakdown
    const dailyData: Record<string, {
        calories: number
        protein: number
        carbs: number
        fat: number
        mealCount: number
    }> = {}

    // Meal type counts
    const mealTypes: MealTypeStats = {
        breakfast: 0,
        lunch: 0,
        dinner: 0,
        snack: 0,
    }

    let totalCalories = 0
    let totalProtein = 0
    let totalCarbs = 0
    let totalFat = 0
    let totalMeals = 0

    meals.forEach(meal => {
        const date = getLocalDate(meal.created_at)
        if (!dailyData[date]) {
            dailyData[date] = { calories: 0, protein: 0, carbs: 0, fat: 0, mealCount: 0 }
        }

        const analysis = meal.analysis as MealAnalysis | null
        if (analysis?.summary) {
            dailyData[date].calories += analysis.summary.calories
            dailyData[date].protein += analysis.summary.protein
            dailyData[date].carbs += analysis.summary.carbs
            dailyData[date].fat += analysis.summary.fat
            dailyData[date].mealCount += 1

            totalCalories += analysis.summary.calories
            totalProtein += analysis.summary.protein
            totalCarbs += analysis.summary.carbs
            totalFat += analysis.summary.fat
            totalMeals += 1
        }

        // Count meal types
        const mealType = meal.meal_type as keyof MealTypeStats
        if (mealType && mealTypes[mealType] !== undefined) {
            mealTypes[mealType] += 1
        }
    })

    // Convert to array sorted by date
    const days = Object.entries(dailyData)
        .map(([date, data]) => ({
            date,
            label: new Date(date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
            ...data,
        }))
        .sort((a, b) => a.date.localeCompare(b.date))

    // Calculate date range info
    // For calculating "Total Days", we can rely on the number of days in the range or roughly the diff.
    // Using the raw start/end timestamps diff in days.
    const startDt = new Date(start)
    const endDt = new Date(end)
    const totalDays = Math.ceil((endDt.getTime() - startDt.getTime()) / (1000 * 60 * 60 * 24))
    const daysWithMeals = Object.keys(dailyData).length

    return {
        days,
        totals: {
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
        },
        averages: {
            calories: daysWithMeals > 0 ? Math.round(totalCalories / daysWithMeals) : 0,
            protein: daysWithMeals > 0 ? Math.round(totalProtein / daysWithMeals) : 0,
            carbs: daysWithMeals > 0 ? Math.round(totalCarbs / daysWithMeals) : 0,
            fat: daysWithMeals > 0 ? Math.round(totalFat / daysWithMeals) : 0,
        },
        mealTypes,
        summary: {
            totalDays,
            daysWithMeals,
            totalMeals,
            avgMealsPerDay: daysWithMeals > 0 ? (totalMeals / daysWithMeals).toFixed(1) : '0',
        },
    }
}
