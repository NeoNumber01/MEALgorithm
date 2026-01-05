'use server'

import { createClient } from '@/lib/supabase/server'

export interface CoachAdviceParams {
    context: 'today' | 'statistics'
    todayData?: {
        calories: number
        protein: number
        carbs: number
        fat: number
        mealCount: number
        mealTypes: string[]  // e.g., ['breakfast', 'lunch']
        targetProtein: number
        targetCarbs: number
        targetFat: number
    }
    targetCalories: number
    goalDescription?: string
    statsData?: {
        avgCalories: number
        avgProtein: number
        avgCarbs: number
        avgFat: number
        totalMeals: number
        daysWithMeals: number
        totalDays: number
        consistencyScore: number
        avgMealsPerDay: string
        avgProteinPerMeal: number
        timeRangeLabel: string
        macroBalance?: {
            protein: number
            carbs: number
            fat: number
        }
    }
}

export async function generateCoachAdvice(params: CoachAdviceParams): Promise<{ advice: string } | { error: string }> {
    const { context, todayData, statsData } = params

    // Get Supabase client and verify authentication
    const supabase = await createClient()

    const { data: { user }, error: userError } = await supabase.auth.getUser()

    if (userError || !user) {
        console.error('AI Coach Auth error:', userError)
        return { error: 'Please sign in to get AI advice' }
    }

    // Get session for access token
    const { data: { session }, error: sessionError } = await supabase.auth.getSession()

    if (sessionError || !session?.access_token) {
        console.error('AI Coach Session error:', sessionError)
        return { error: 'Session expired - please sign in again' }
    }

    try {
        // Call generate-suggestions Edge Function (same as getNextMeal pattern)
        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
        console.log('AI Coach: Calling generate-suggestions Edge Function...')

        const response = await fetch(`${supabaseUrl}/functions/v1/generate-suggestions`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${session.access_token}`,
            },
            body: JSON.stringify({
                type: 'coach',
                coachContext: {
                    context,
                    todayCalories: todayData?.calories,
                    todayProtein: todayData?.protein,
                    todayCarbs: todayData?.carbs,
                    todayFat: todayData?.fat,
                    mealCount: todayData?.mealCount,
                    mealTypes: todayData?.mealTypes || [],
                    targetProtein: todayData?.targetProtein,
                    targetCarbs: todayData?.targetCarbs,
                    targetFat: todayData?.targetFat,
                    // Statistics fields
                    avgCalories: statsData?.avgCalories,
                    avgProtein: statsData?.avgProtein,
                    avgCarbs: statsData?.avgCarbs,
                    avgFat: statsData?.avgFat,
                    consistencyScore: statsData?.consistencyScore,
                    totalMeals: statsData?.totalMeals,
                    daysWithMeals: statsData?.daysWithMeals,
                    totalDays: statsData?.totalDays,
                    avgMealsPerDay: statsData?.avgMealsPerDay,
                    avgProteinPerMeal: statsData?.avgProteinPerMeal,
                    timeRangeLabel: statsData?.timeRangeLabel,
                    macroBalanceProtein: statsData?.macroBalance?.protein,
                    macroBalanceCarbs: statsData?.macroBalance?.carbs,
                    macroBalanceFat: statsData?.macroBalance?.fat,
                }
            }),
        })

        console.log('AI Coach: Edge Function response status:', response.status)

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}))
            console.error('AI Coach Edge Function Error:', errorData)
            return { error: errorData.error || `Request failed: ${response.status}` }
        }

        const result = await response.json()

        // Extract advice from response
        let advice = ''
        const data = result.data

        if (typeof data === 'object' && data !== null) {
            // JSON object - try to get advice field
            advice = data.advice || data.text || data.content || ''
        } else if (typeof data === 'string') {
            // Try to parse as JSON first
            try {
                const parsed = JSON.parse(data)
                advice = parsed.advice || parsed.text || data
            } catch {
                advice = data
            }
        }

        if (!advice) {
            return { error: 'No advice generated' }
        }

        console.log('AI Coach: Generated advice successfully')
        return { advice: typeof advice === 'string' ? advice : JSON.stringify(advice) }

    } catch (e) {
        console.error('AI Coach Error:', e)
        return { error: (e as Error).message || 'AI Service Error' }
    }
}
