'use server'

import { createClient } from '@/lib/supabase/server'

interface FrequentMeal {
    text_content: string
    count: number
    mealType: string
}

export async function getFrequentMeals(limit: number = 5) {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return { error: 'Not authenticated' }

    // Get meals logged in the last 30 days
    const thirtyDaysAgo = new Date()
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)

    const { data: meals, error } = await supabase
        .from('meals')
        .select('text_content, meal_type, id')
        .eq('user_id', user.id)
        .gte('created_at', thirtyDaysAgo.toISOString())
        .order('created_at', { ascending: false })

    if (error) {
        return { error: error.message }
    }

    // Count occurrences of each meal description
    const mealCounts: { [key: string]: { count: number; mealType: string } } = {}

    meals.forEach((meal) => {
        if (meal.text_content) {
            const key = meal.text_content.toLowerCase()
            if (!mealCounts[key]) {
                mealCounts[key] = { count: 0, mealType: meal.meal_type || 'snack' }
            }
            mealCounts[key].count++
        }
    })

    // Convert to array and sort by frequency
    const frequentMeals: FrequentMeal[] = Object.entries(mealCounts)
        .map(([text_content, data]) => ({
            text_content,
            count: data.count,
            mealType: data.mealType,
        }))
        .sort((a, b) => b.count - a.count)
        .slice(0, limit)

    return { meals: frequentMeals }
}
