import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

interface MealAnalysis {
    summary: {
        calories: number
        protein: number
        carbs: number
        fat: number
    }
}

export async function POST(request: NextRequest) {
    try {
        const { forceRefresh } = await request.json()

        const supabase = await createClient()
        const { data: { user } } = await supabase.auth.getUser()

        if (!user) {
            return NextResponse.json({ error: 'Not authenticated' }, { status: 401 })
        }

        // Get user profile
        const { data: profile } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', user.id)
            .single()

        // Check cache (only if not force refresh)
        if (!forceRefresh && profile?.cached_day_plan && profile?.day_plan_updated_at) {
            const cached = profile.cached_day_plan as { dayPlan: unknown[], context: unknown }

            if (cached.dayPlan && Array.isArray(cached.dayPlan) && cached.context) {
                const cacheTime = new Date(profile.day_plan_updated_at).getTime()
                const lastMealTime = profile.last_meal_at ? new Date(profile.last_meal_at).getTime() : 0
                const profileUpdatedTime = profile.profile_updated_at ? new Date(profile.profile_updated_at).getTime() : 0

                if (cacheTime > lastMealTime && cacheTime > profileUpdatedTime) {
                    console.log('Day Plan API: Using cached data')
                    return NextResponse.json(cached)
                }
            }
        }

        console.log('Day Plan API: Generating new day plan...')

        // Get today's meals
        const today = new Date()
        const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate()).toISOString()

        const { data: todayMeals } = await supabase
            .from('meals')
            .select('*')
            .eq('user_id', user.id)
            .gte('created_at', startOfDay)
            .order('created_at', { ascending: true })

        // Calculate consumed calories
        let consumedCalories = 0
        const eatenMealTypes: string[] = []

        todayMeals?.forEach(meal => {
            const analysis = meal.analysis as MealAnalysis | null
            if (analysis?.summary) {
                consumedCalories += analysis.summary.calories
            }
            if (meal.meal_type) eatenMealTypes.push(meal.meal_type)
        })

        const targetCalories = profile?.calorie_target || 2000
        const remainingCalories = Math.max(0, targetCalories - consumedCalories)

        // Determine remaining meals
        const currentHour = new Date().getHours()
        const mealTimeWindows: Record<string, { end: number }> = {
            breakfast: { end: 10 },
            lunch: { end: 14 },
            dinner: { end: 21 },
            snack: { end: 24 },
        }

        const remainingMealTypes = Object.entries(mealTimeWindows)
            .filter(([mealType, window]) => {
                if (eatenMealTypes.includes(mealType)) return false
                if (mealType === 'snack') return true
                return currentHour < window.end
            })
            .map(([mealType]) => mealType)

        const prompt = `You are a nutritionist AI. Create a meal plan for remaining meals.

User Profile:
- Daily Calorie Target: ${targetCalories} kcal
- Goal: ${profile?.goal_description || 'General health'}

Today's Progress:
- Consumed: ${consumedCalories} kcal
- Remaining: ${remainingCalories} kcal
- Already eaten: ${eatenMealTypes.join(', ') || 'None'}
- To plan: ${remainingMealTypes.join(', ')}

Respond in JSON format:
{
  "dayPlan": [
    {
      "mealType": "breakfast/lunch/dinner/snack",
      "name": "Meal name",
      "description": "Brief description",
      "nutrition": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 }
    }
  ],
  "summary": {
    "totalPlannedCalories": 0,
    "advice": "Brief advice"
  }
}`

        // Get session for Edge Function
        const { data: { session } } = await supabase.auth.getSession()
        if (!session) {
            return NextResponse.json({ error: 'No session' }, { status: 401 })
        }

        // Call Edge Function
        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
        const response = await fetch(`${supabaseUrl}/functions/v1/ai-generate`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${session.access_token}`,
            },
            body: JSON.stringify({ prompt, type: 'recommendations' }),
        })

        if (!response.ok) {
            const errorText = await response.text()
            console.error('Edge Function error:', response.status, errorText)
            return NextResponse.json({
                error: `AI service error: ${response.status}`,
                details: errorText
            }, { status: 500 })
        }

        const aiResult = await response.json()

        // Parse response
        let parsed
        if (typeof aiResult.data === 'string') {
            parsed = JSON.parse(aiResult.data)
        } else {
            parsed = aiResult.data
        }

        if (!parsed?.dayPlan || !Array.isArray(parsed.dayPlan)) {
            console.error('Invalid AI response:', parsed)
            return NextResponse.json({ error: 'Invalid AI response' }, { status: 500 })
        }

        const result = {
            dayPlan: parsed.dayPlan,
            summary: parsed.summary || { totalPlannedCalories: remainingCalories, advice: 'Enjoy your day!' },
            context: {
                targetCalories,
                consumedCalories,
                remainingCalories,
                eatenMealTypes,
                remainingMealTypes,
            }
        }

        // Cache the result
        await supabase
            .from('profiles')
            .update({
                cached_day_plan: result,
                day_plan_updated_at: new Date().toISOString(),
            })
            .eq('id', user.id)

        console.log('Day Plan API: Generated', parsed.dayPlan.length, 'meals')
        return NextResponse.json(result)

    } catch (error) {
        console.error('Day Plan API error:', error)
        return NextResponse.json({ error: 'Failed to generate day plan' }, { status: 500 })
    }
}
