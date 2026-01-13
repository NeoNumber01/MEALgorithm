'use server'

import { createClient } from '@/lib/supabase/server'

interface Recommendation {
    name: string
    description: string
    reason: string
    nutrition: {
        calories: number
        protein: number
        carbs: number
        fat: number
    }
}

interface DayPlanMeal {
    mealType: string
    name: string
    description: string
    nutrition: {
        calories: number
        protein: number
        carbs: number
        fat: number
    }
}

interface NextMealResult {
    recommendations: Recommendation[]
    context: {
        targetCalories: number
        consumedCalories: number
        remainingCalories: number
        goal?: string
    }
}

interface DayPlanResult {
    dayPlan: DayPlanMeal[]
    summary: {
        totalPlannedCalories: number
        advice: string
    }
    context: {
        targetCalories: number
        consumedCalories: number
        remainingCalories: number
        mealsLeft: number
    }
}

export async function getNextMeal(forceRefresh = false): Promise<NextMealResult | { error: string }> {
    const supabase = await createClient()

    // Verify user
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) {
        return { error: 'Unauthorized - please sign in' }
    }

    // Get profile for cache check
    const { data: profile } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single()

    // Helper function to calculate today's calories
    const calculateTodayCalories = async () => {
        const today = new Date()
        const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate()).toISOString()

        const { data: todayMeals } = await supabase
            .from('meals')
            .select('analysis')
            .eq('user_id', user.id)
            .gte('created_at', startOfDay)

        let consumedCalories = 0
        todayMeals?.forEach(meal => {
            const analysis = meal.analysis as { summary?: { calories?: number } } | null
            if (analysis?.summary?.calories) {
                consumedCalories += analysis.summary.calories
            }
        })

        const targetCalories = profile?.calorie_target || 2000
        const remainingCalories = Math.max(0, targetCalories - consumedCalories)

        return { targetCalories, consumedCalories, remainingCalories }
    }

    // Check cache (unless force refresh)
    if (!forceRefresh && profile?.cached_next_meal) {
        const cached = profile.cached_next_meal as NextMealResult
        if (cached.recommendations && Array.isArray(cached.recommendations) && cached.recommendations.length > 0) {
            console.log('getNextMeal: Using cached recommendations, calculating fresh context')
            // Use cached recommendations but calculate fresh context
            const calorieData = await calculateTodayCalories()
            return {
                recommendations: cached.recommendations,
                context: {
                    ...calorieData,
                    goal: profile?.goal || 'maintenance',
                }
            }
        }
    }

    console.log('getNextMeal: Generating new recommendations...')

    // Get session for Edge Function auth
    const { data: { session }, error: sessionError } = await supabase.auth.getSession()
    if (sessionError || !session?.access_token) {
        return { error: 'Session expired - please sign in again' }
    }

    try {
        // Call Edge Function
        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
        console.log('Calling Edge Function:', `${supabaseUrl}/functions/v1/generate-suggestions`)

        const response = await fetch(`${supabaseUrl}/functions/v1/generate-suggestions`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${session.access_token}`,
            },
            body: JSON.stringify({ type: 'next-meal', forceRefresh }),
        })

        console.log('Edge Function response status:', response.status)

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}))
            console.error('Edge Function Error:', errorData)
            return { error: errorData.error || `Request failed: ${response.status}` }
        }

        const result = await response.json()
        const data = result.data

        if (!data?.recommendations || !Array.isArray(data.recommendations)) {
            console.error('Invalid response:', data)
            return { error: 'Invalid AI response' }
        }

        // Get today's consumed calories for context
        const today = new Date()
        const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate()).toISOString()

        const { data: todayMeals } = await supabase
            .from('meals')
            .select('analysis')
            .eq('user_id', user.id)
            .gte('created_at', startOfDay)

        let consumedCalories = 0
        todayMeals?.forEach(meal => {
            const analysis = meal.analysis as { summary?: { calories?: number } } | null
            if (analysis?.summary?.calories) {
                consumedCalories += analysis.summary.calories
            }
        })

        const targetCalories = profile?.calorie_target || 2000
        const remainingCalories = Math.max(0, targetCalories - consumedCalories)

        const nextMealResult: NextMealResult = {
            recommendations: data.recommendations,
            context: {
                targetCalories,
                consumedCalories,
                remainingCalories,
                goal: profile?.goal_description,
            }
        }

        // Cache the result
        await supabase
            .from('profiles')
            .update({
                cached_next_meal: nextMealResult,
                next_meal_updated_at: new Date().toISOString(),
            })
            .eq('id', user.id)

        console.log('getNextMeal: Generated', data.recommendations.length, 'recommendations')
        return nextMealResult

    } catch (e) {
        console.error('getNextMeal Error:', e)
        return { error: (e as Error).message || 'AI Service Error' }
    }
}

export async function getDayPlan(forceRefresh = false): Promise<DayPlanResult | { error: string }> {
    const supabase = await createClient()

    // Verify user
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) {
        return { error: 'Unauthorized - please sign in' }
    }

    // Get profile for cache check
    const { data: profile } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single()

    // Helper function to calculate today's context including macros
    const calculateTodayContext = async () => {
        const today = new Date()
        const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate()).toISOString()

        const { data: todayMeals } = await supabase
            .from('meals')
            .select('analysis, meal_type')
            .eq('user_id', user.id)
            .gte('created_at', startOfDay)

        let consumedCalories = 0
        let consumedProtein = 0
        let consumedCarbs = 0
        let consumedFat = 0
        const eatenMealTypes: string[] = []

        todayMeals?.forEach(meal => {
            const analysis = meal.analysis as { summary?: { calories?: number; protein?: number; carbs?: number; fat?: number } } | null
            if (analysis?.summary) {
                consumedCalories += analysis.summary.calories || 0
                consumedProtein += analysis.summary.protein || 0
                consumedCarbs += analysis.summary.carbs || 0
                consumedFat += analysis.summary.fat || 0
            }
            if (meal.meal_type) {
                eatenMealTypes.push(meal.meal_type)
            }
        })

        // Calculate remaining MAIN meals only (breakfast, lunch, dinner)
        // Snack is handled separately and not counted in mealsLeft
        const mainMealTypes = ['breakfast', 'lunch', 'dinner']
        const uneatenMainMeals = mainMealTypes.filter(type => !eatenMealTypes.includes(type))
        const hasEatenSnack = eatenMealTypes.includes('snack')

        // Targets - use profile values or calculate defaults based on calorie target
        const targetCalories = profile?.calorie_target || 2000
        // Default macro distribution: ~25% protein, ~50% carbs, ~25% fat (by calories)
        // Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
        const targetProtein = Math.round(targetCalories * 0.25 / 4)  // ~125g for 2000 kcal
        const targetCarbs = Math.round(targetCalories * 0.50 / 4)   // ~250g for 2000 kcal
        const targetFat = Math.round(targetCalories * 0.25 / 9)     // ~55g for 2000 kcal

        const remainingCalories = Math.max(0, targetCalories - consumedCalories)
        const remainingProtein = Math.max(0, targetProtein - consumedProtein)
        const remainingCarbs = Math.max(0, targetCarbs - consumedCarbs)
        const remainingFat = Math.max(0, targetFat - consumedFat)

        // Include snack recommendation if: not eaten yet AND remaining calories > 100 kcal
        const includeSnack = !hasEatenSnack && remainingCalories > 100

        return {
            targetCalories,
            consumedCalories,
            remainingCalories,
            targetProtein,
            consumedProtein,
            remainingProtein,
            targetCarbs,
            consumedCarbs,
            remainingCarbs,
            targetFat,
            consumedFat,
            remainingFat,
            // mealsLeft only counts main meals (breakfast, lunch, dinner)
            mealsLeft: uneatenMainMeals.length,
            // Array of uneaten main meals for Edge Function
            uneatenMainMeals,
            // Whether to include snack recommendation
            includeSnack,
        }
    }

    // Check cache (unless force refresh)
    if (!forceRefresh && profile?.cached_day_plan) {
        const cached = profile.cached_day_plan as DayPlanResult
        if (cached.dayPlan && Array.isArray(cached.dayPlan)) {
            console.log('getDayPlan: Using cached dayPlan, calculating fresh context')
            // Use cached dayPlan but calculate fresh context
            const contextData = await calculateTodayContext()
            return {
                dayPlan: cached.dayPlan,
                summary: cached.summary || { totalPlannedCalories: contextData.remainingCalories, advice: 'Enjoy your day!' },
                context: contextData,
            }
        }
    }

    console.log('getDayPlan: Generating new day plan...')

    // Calculate context first so we can pass it to Edge Function
    const contextData = await calculateTodayContext()
    console.log('getDayPlan: Context -', 'consumed:', contextData.consumedCalories, 'remaining:', contextData.remainingCalories, 'mainMealsLeft:', contextData.uneatenMainMeals, 'includeSnack:', contextData.includeSnack)

    // Get session for Edge Function auth
    const { data: { session }, error: sessionError } = await supabase.auth.getSession()
    if (sessionError || !session?.access_token) {
        return { error: 'Session expired - please sign in again' }
    }

    try {
        // Call Edge Function with dayPlanContext for consistency
        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
        console.log('Calling Edge Function:', `${supabaseUrl}/functions/v1/generate-suggestions`)

        const response = await fetch(`${supabaseUrl}/functions/v1/generate-suggestions`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${session.access_token}`,
            },
            body: JSON.stringify({
                type: 'day-plan',
                forceRefresh,
                // Pass context to Edge Function to ensure consistency with frontend
                dayPlanContext: {
                    consumed: contextData.consumedCalories,
                    remaining: contextData.remainingCalories,
                    mealsLeft: contextData.uneatenMainMeals,  // Only main meals (no snack)
                    includeSnack: contextData.includeSnack,   // Extra snack if calories remain
                    // Macro targets for nutrition-based planning
                    remainingProtein: contextData.remainingProtein,
                    remainingCarbs: contextData.remainingCarbs,
                    remainingFat: contextData.remainingFat,
                }
            }),
        })

        console.log('Edge Function response status:', response.status)

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}))
            console.error('Edge Function Error:', errorData)
            return { error: errorData.error || `Request failed: ${response.status}` }
        }

        const result = await response.json()
        const data = result.data

        if (!data?.dayPlan || !Array.isArray(data.dayPlan)) {
            console.error('Invalid response:', data)
            return { error: 'Invalid AI response' }
        }

        // Use the contextData we already calculated (no need to recalculate)
        const dayPlanResult: DayPlanResult = {
            dayPlan: data.dayPlan,
            summary: data.summary || { totalPlannedCalories: contextData.remainingCalories, advice: 'Enjoy your day!' },
            context: {
                targetCalories: contextData.targetCalories,
                consumedCalories: contextData.consumedCalories,
                remainingCalories: contextData.remainingCalories,
                mealsLeft: contextData.mealsLeft,  // Use the count from contextData
            }
        }

        // Cache the result
        await supabase
            .from('profiles')
            .update({
                cached_day_plan: dayPlanResult,
                day_plan_updated_at: new Date().toISOString(),
            })
            .eq('id', user.id)

        console.log('getDayPlan: Generated', data.dayPlan.length, 'meals for', contextData.uneatenMainMeals.join(', '), contextData.includeSnack ? '+ snack' : '')
        return dayPlanResult

    } catch (e) {
        console.error('getDayPlan Error:', e)
        return { error: (e as Error).message || 'AI Service Error' }
    }
}
