'use server'

import { createClient } from '@/lib/supabase/server'

export interface MealDay {
    date: string // ISO date string (YYYY-MM-DD)
    meals: Array<{
        id: string
        meal_type: string | null
        created_at: string
        analysis: {
            summary?: {
                calories?: number
                protein?: number
                carbs?: number
                fat?: number
            }
        }
        text_content: string | null
    }>
    totalCalories: number
}

export async function getMealsByDateRange(startDate: string, endDate: string) {
    const supabase = await createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
        return { error: 'Not authenticated' }
    }

    // Query meals within date range
    const { data: meals, error } = await supabase
        .from('meals')
        .select('*')
        .eq('user_id', user.id)
        .gte('created_at', `${startDate}T00:00:00Z`)
        .lte('created_at', `${endDate}T23:59:59Z`)
        .order('created_at', { ascending: false })

    if (error) {
        console.error('Error fetching meals:', error)
        return { error: error.message }
    }

    console.log(`Fetched ${meals?.length || 0} meals for range ${startDate} to ${endDate}`)

    // Group meals by date
    const mealsByDate: Record<string, MealDay> = {}

    meals?.forEach((meal: any) => {
        const mealDate = new Date(meal.created_at).toISOString().split('T')[0]

        if (!mealsByDate[mealDate]) {
            mealsByDate[mealDate] = {
                date: mealDate,
                meals: [],
                totalCalories: 0,
            }
        }

        const calories = meal.analysis?.summary?.calories || 0
        mealsByDate[mealDate].meals.push(meal)
        mealsByDate[mealDate].totalCalories += calories
    })

    // Convert to sorted array
    const sortedMeals = Object.values(mealsByDate).sort(
        (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()
    )

    return { meals: sortedMeals }
}

export async function getMealsForMonth(year: number, month: number) {
    const startDate = new Date(year, month - 1, 1).toISOString().split('T')[0]
    const endDate = new Date(year, month, 0).toISOString().split('T')[0]

    return getMealsByDateRange(startDate, endDate)
}

export async function getMealsForDate(date: string) {
    return getMealsByDateRange(date, date)
}
