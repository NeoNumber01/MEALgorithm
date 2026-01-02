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

export async function getDailyStats(date: string) {
    const supabase = createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { error: 'Not authenticated' }

    const startOfDay = `${date}T00:00:00.000Z`
    const endOfDay = `${date}T23:59:59.999Z`

    const { data: meals, error } = await supabase
        .from('meals')
        .select('*')
        .eq('user_id', user.id)
        .gte('created_at', startOfDay)
        .lte('created_at', endOfDay)
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
        date,
        meals: mealsList,
        totals: {
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
        },
    }
}

export async function getWeeklyStats() {
    const supabase = createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { error: 'Not authenticated' }

    const today = new Date()
    const weekAgo = new Date(today)
    weekAgo.setDate(weekAgo.getDate() - 7)

    const { data: meals, error } = await supabase
        .from('meals')
        .select('*')
        .eq('user_id', user.id)
        .gte('created_at', weekAgo.toISOString())
        .order('created_at', { ascending: true })

    if (error) {
        return { error: error.message }
    }

    const dailyData: Record<string, { calories: number; protein: number; carbs: number; fat: number }> = {}

    meals.forEach(meal => {
        const date = new Date(meal.created_at).toISOString().split('T')[0]
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
    for (let i = 6; i >= 0; i--) {
        const d = new Date(today)
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
    const supabase = createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { error: 'Not authenticated' }

    const { data: profile } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single()

    return { profile }
}
