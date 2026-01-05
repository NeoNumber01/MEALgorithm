'use server'

import { createClient } from '@/lib/supabase/server'

interface MealAnalysis {
    summary: {
        calories: number
        protein: number
        carbs: number
        fat: number
    }
}

interface RecommendationResult {
    recommendations: Array<{
        name: string
        description: string
        reason: string
        nutrition: {
            calories: number
            protein: number
            carbs: number
            fat: number
        }
    }>
    context: {
        targetCalories: number
        recentAvgCalories: number
        goal?: string
    }
}

interface DayPlanResult {
    dayPlan: Array<{
        mealType: string
        name: string
        description: string
        nutrition: {
            calories: number
            protein: number
            carbs: number
            fat: number
        }
    }>
    summary: {
        totalPlannedCalories: number
        advice: string
    }
    context: {
        targetCalories: number
        consumedCalories: number
        remainingCalories: number
        eatenMealTypes: string[]
        remainingMealTypes: string[]
    }
}

// Helper function to extract frequently mentioned ingredients from meal descriptions
function extractFrequentIngredients(mealDescriptions: string[]): string[] {
    const combinedText = mealDescriptions.join(' ').toLowerCase()

    // Common food keywords to look for
    const foodKeywords = [
        'chicken', 'beef', 'pork', 'fish', 'salmon', 'tuna', 'shrimp',
        'rice', 'pasta', 'noodles', 'bread', 'potato',
        'salad', 'vegetables', 'broccoli', 'spinach', 'tomato',
        'eggs', 'cheese', 'yogurt', 'milk',
        'apple', 'banana', 'berries', 'orange',
        'tofu', 'beans', 'lentils',
        'avocado', 'nuts', 'almonds',
        'soup', 'sandwich', 'burger', 'pizza', 'sushi',
        'coffee', 'tea', 'smoothie',
        '鸡肉', '牛肉', '猪肉', '鱼', '虾',
        '米饭', '面条', '面包',
        '沙拉', '蔬菜', '西兰花', '菠菜',
        '鸡蛋', '奶酪', '酸奶',
        '苹果', '香蕉', '橙子',
        '豆腐', '豆类'
    ]

    const found: string[] = []
    for (const keyword of foodKeywords) {
        if (combinedText.includes(keyword)) {
            found.push(keyword)
        }
    }

    return found.slice(0, 8) // Return top 8 ingredients
}

// Get cached recommendations or generate new ones
export async function getRecommendations(forceRefresh = false): Promise<RecommendationResult | { error: string }> {
    const supabase = await createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { error: 'Not authenticated' }

    // Get user profile with cache info
    const { data: profile } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single()

    // When forceRefresh is true, skip cache entirely and regenerate
    if (forceRefresh) {
        console.log('Recommendations: Force refresh requested, skipping cache...')
    } else if (profile?.cached_next_meal && profile?.next_meal_updated_at) {
        const cached = profile.cached_next_meal as RecommendationResult

        // Validate cache structure - must have recommendations array
        if (!cached.recommendations || !Array.isArray(cached.recommendations) || cached.recommendations.length === 0) {
            console.log('Recommendations: Cache invalid - missing or empty recommendations array, regenerating...')
        } else {
            const cacheTime = new Date(profile.next_meal_updated_at).getTime()
            const lastMealTime = profile.last_meal_at ? new Date(profile.last_meal_at).getTime() : 0
            const profileUpdatedTime = profile.profile_updated_at ? new Date(profile.profile_updated_at).getTime() : 0

            // Check if the cached targets match current profile targets
            const cachedTargetCalories = cached.context?.targetCalories
            const currentTargetCalories = profile.calorie_target || 2000
            const targetsMatch = cachedTargetCalories === currentTargetCalories

            // Check if the cached goal matches current profile goal
            const cachedGoal = cached.context?.goal
            const currentGoal = profile.goal_description || 'General health'
            const goalsMatch = cachedGoal === currentGoal

            // Use cache if all conditions are met
            if (cacheTime > lastMealTime && cacheTime > profileUpdatedTime && targetsMatch && goalsMatch) {
                console.log('Recommendations: Using cached data (no changes detected)')
                return cached
            }
            console.log('Recommendations: Cache invalid, regenerating...', { targetsMatch, goalsMatch, cacheTime, lastMealTime, profileUpdatedTime })
        }
    }

    // Generate new recommendations
    let result: RecommendationResult
    try {
        result = await generateNewRecommendations(user.id, profile)
    } catch (e) {
        console.error('Recommendations: Generation failed:', e)
        return { error: 'Failed to generate recommendations. Please try again.' }
    }

    // Cache the result (only on success)
    await supabase
        .from('profiles')
        .update({
            cached_next_meal: result,
            next_meal_updated_at: new Date().toISOString(),
        })
        .eq('id', user.id)

    return result
}

// Internal function to generate new recommendations
// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function generateNewRecommendations(userId: string, profile: any): Promise<RecommendationResult> {
    const supabase = await createClient()

    // Get recent meals (last 3 days)
    const threeDaysAgo = new Date()
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3)

    const { data: recentMeals } = await supabase
        .from('meals')
        .select('*')
        .eq('user_id', userId)
        .gte('created_at', threeDaysAgo.toISOString())
        .order('created_at', { ascending: false })
        .limit(10)

    // Calculate recent averages
    let totalCalories = 0
    let totalProtein = 0
    let totalCarbs = 0
    let totalFat = 0
    let mealCount = 0

    const mealDescriptions: string[] = []

    recentMeals?.forEach(meal => {
        const analysis = meal.analysis as MealAnalysis | null
        if (analysis?.summary) {
            totalCalories += analysis.summary.calories
            totalProtein += analysis.summary.protein
            totalCarbs += analysis.summary.carbs
            totalFat += analysis.summary.fat
            mealCount++
        }
        if (meal.text_content) {
            mealDescriptions.push(meal.text_content)
        }
    })

    const avgCalories = mealCount > 0 ? Math.round(totalCalories / mealCount) : 0
    const avgProtein = mealCount > 0 ? Math.round(totalProtein / mealCount) : 0
    const avgCarbs = mealCount > 0 ? Math.round(totalCarbs / mealCount) : 0
    const avgFat = mealCount > 0 ? Math.round(totalFat / mealCount) : 0

    // Build preference context
    const preferencesSection = []
    if (profile?.food_preferences) {
        preferencesSection.push(`- Favorite Foods: ${profile.food_preferences}`)
    }
    if (profile?.food_dislikes) {
        preferencesSection.push(`- Foods to Avoid: ${profile.food_dislikes}`)
    }
    if (profile?.dietary_restrictions) {
        preferencesSection.push(`- Dietary Restrictions: ${profile.dietary_restrictions}`)
    }
    if (profile?.custom_notes) {
        preferencesSection.push(`- Special Requests: ${profile.custom_notes}`)
    }

    // Analyze meal history for preferences
    const frequentIngredients = extractFrequentIngredients(mealDescriptions)

    const prompt = `
You are a helpful nutritionist AI. Based on the user's data, suggest 3 meal ideas for their next meal.
IMPORTANT: Pay close attention to the user's food preferences and restrictions!

User Profile:
- Calorie Target: ${profile?.calorie_target || 2000} kcal/day
- Goal: ${profile?.goal_description || 'General health'}

${preferencesSection.length > 0 ? `User Preferences:\n${preferencesSection.join('\n')}` : ''}

${frequentIngredients.length > 0 ? `Based on meal history, user seems to enjoy: ${frequentIngredients.join(', ')}` : ''}

Recent Eating Pattern (per meal averages):
- Calories: ${avgCalories} kcal
- Protein: ${avgProtein}g
- Carbs: ${avgCarbs}g
- Fat: ${avgFat}g

Recent Meals: ${mealDescriptions.slice(0, 5).join('; ') || 'No recent data'}

Provide exactly 3 recommendations in this JSON format:
{
  "recommendations": [
    {
      "name": "Meal name",
      "description": "Brief 1-sentence description",
      "reason": "Why this is good for the user (1 sentence)",
      "nutrition": {
        "calories": 0,
        "protein": 0,
        "carbs": 0,
        "fat": 0
      }
    }
  ]
}
`

    try {
        // Get session for Edge Function auth
        const { data: { session } } = await supabase.auth.getSession()
        if (!session) {
            throw new Error('No session')
        }

        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
        console.log('Recommendations: Calling Edge Function...')
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
            console.error('Recommendations: Edge Function error:', response.status, errorText)
            throw new Error(`Edge Function error: ${response.status}`)
        }

        const result = await response.json()
        console.log('Recommendations: Edge Function response type:', typeof result.data)

        // Parse the data - it might be a string that needs JSON.parse
        let parsed
        if (typeof result.data === 'string') {
            try {
                parsed = JSON.parse(result.data)
                console.log('Recommendations: Parsed string data successfully')
            } catch (parseError) {
                console.error('Recommendations: Failed to parse JSON string:', parseError)
                throw new Error('Failed to parse AI response')
            }
        } else {
            parsed = result.data || result
        }

        console.log('Recommendations: Parsed data has', parsed?.recommendations?.length, 'recommendations')

        // Validate the parsed data
        if (!parsed || !Array.isArray(parsed.recommendations) || parsed.recommendations.length === 0) {
            console.error('Recommendations: Invalid response structure:', parsed)
            throw new Error('Invalid response from AI')
        }

        return {
            recommendations: parsed.recommendations,
            context: {
                targetCalories: profile?.calorie_target || 2000,
                recentAvgCalories: avgCalories,
                goal: profile?.goal_description,
            }
        }
    } catch (e) {
        console.error('Recommendations: AI generation error:', e)
        // Re-throw the error so the caller can handle it properly
        throw e
    }
}

// Get cached day plan or generate new one
export async function getDayPlan(forceRefresh = false): Promise<DayPlanResult | { error: string }> {
    const supabase = await createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { error: 'Not authenticated' }

    // Get user profile with cache info
    const { data: profile } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single()

    // When forceRefresh is true, skip cache entirely and regenerate
    if (forceRefresh) {
        console.log('Day Plan: Force refresh requested, skipping cache...')
    } else if (profile?.cached_day_plan && profile?.day_plan_updated_at) {
        const cached = profile.cached_day_plan as DayPlanResult

        // Validate cache structure - must have dayPlan array and context
        if (!cached.dayPlan || !Array.isArray(cached.dayPlan) || !cached.context) {
            console.log('Day Plan: Cache invalid - missing dayPlan array or context, regenerating...')
        } else {
            const cacheTime = new Date(profile.day_plan_updated_at).getTime()
            const lastMealTime = profile.last_meal_at ? new Date(profile.last_meal_at).getTime() : 0
            const profileUpdatedTime = profile.profile_updated_at ? new Date(profile.profile_updated_at).getTime() : 0

            // Check if the cached targets match current profile targets
            const cachedTargetCalories = cached.context?.targetCalories
            const currentTargetCalories = profile.calorie_target || 2000
            const targetsMatch = cachedTargetCalories === currentTargetCalories

            // Use cache if all conditions are met
            if (cacheTime > lastMealTime && cacheTime > profileUpdatedTime && targetsMatch) {
                console.log('Day Plan: Using cached data (no changes detected)')
                return cached
            }
            console.log('Day Plan: Cache invalid, regenerating...', { targetsMatch, cacheTime, lastMealTime, profileUpdatedTime })
        }
    }

    // Generate new day plan
    let result: DayPlanResult
    try {
        result = await generateNewDayPlan(user.id, profile)
    } catch (e) {
        console.error('Day Plan: Generation failed:', e)
        return { error: 'Failed to generate day plan. Please try again.' }
    }

    // Cache the result (only on success)
    await supabase
        .from('profiles')
        .update({
            cached_day_plan: result,
            day_plan_updated_at: new Date().toISOString(),
        })
        .eq('id', user.id)

    return result
}

// Internal function to generate new day plan
// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function generateNewDayPlan(userId: string, profile: any): Promise<DayPlanResult> {
    const supabase = await createClient()

    // Get today's meals
    const today = new Date()
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate()).toISOString()

    const { data: todayMeals } = await supabase
        .from('meals')
        .select('*')
        .eq('user_id', userId)
        .gte('created_at', startOfDay)
        .order('created_at', { ascending: true })

    // Calculate what's been eaten today
    let consumedCalories = 0
    let consumedProtein = 0
    let consumedCarbs = 0
    let consumedFat = 0
    const eatenMealTypes: string[] = []

    todayMeals?.forEach(meal => {
        const analysis = meal.analysis as MealAnalysis | null
        if (analysis?.summary) {
            consumedCalories += analysis.summary.calories
            consumedProtein += analysis.summary.protein
            consumedCarbs += analysis.summary.carbs
            consumedFat += analysis.summary.fat
        }
        if (meal.meal_type) {
            eatenMealTypes.push(meal.meal_type)
        }
    })

    const targetCalories = profile?.calorie_target || 2000
    const remainingCalories = Math.max(0, targetCalories - consumedCalories)

    // Determine remaining meals based on time of day
    const currentHour = new Date().getHours()

    // Define meal time windows
    const mealTimeWindows: Record<string, { start: number; end: number }> = {
        breakfast: { start: 5, end: 10 },
        lunch: { start: 11, end: 14 },
        dinner: { start: 17, end: 21 },
        snack: { start: 0, end: 24 },
    }

    // Filter out meals that are already eaten or past their time window
    const remainingMealTypes = Object.entries(mealTimeWindows)
        .filter(([mealType, window]) => {
            if (eatenMealTypes.includes(mealType)) return false
            if (mealType === 'snack') return true
            return currentHour < window.end
        })
        .map(([mealType]) => mealType)

    const prompt = `
You are a professional nutritionist AI. Create a meal plan for the remaining meals of today.

User Profile:
- Daily Calorie Target: ${targetCalories} kcal
- Goal: ${profile?.goal_description || 'General health'}

Today's Progress:
- Calories consumed so far: ${consumedCalories} kcal
- Remaining budget: ${remainingCalories} kcal
- Protein consumed: ${consumedProtein}g
- Carbs consumed: ${consumedCarbs}g
- Fat consumed: ${consumedFat}g
- Meals already eaten: ${eatenMealTypes.length > 0 ? eatenMealTypes.join(', ') : 'None'}
- Remaining meals to plan: ${remainingMealTypes.join(', ')}

Create a balanced plan for the remaining meals. Distribute the remaining ${remainingCalories} kcal across these meals.

Respond in this exact JSON format:
{
  "dayPlan": [
    {
      "mealType": "breakfast/lunch/dinner/snack",
      "name": "Meal name",
      "description": "Brief description",
      "nutrition": {
        "calories": 0,
        "protein": 0,
        "carbs": 0,
        "fat": 0
      }
    }
  ],
  "summary": {
    "totalPlannedCalories": 0,
    "advice": "Brief overall advice for the day"
  }
}
`

    try {
        // Get session for Edge Function auth
        const { data: { session } } = await supabase.auth.getSession()
        if (!session) {
            throw new Error('No session')
        }

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
            throw new Error(`Edge Function error: ${response.status}`)
        }

        const result = await response.json()
        console.log('Day Plan: Edge Function response type:', typeof result.data)

        // Parse the data - it might be a string that needs JSON.parse
        let parsed
        if (typeof result.data === 'string') {
            try {
                parsed = JSON.parse(result.data)
                console.log('Day Plan: Parsed string data successfully')
            } catch (parseError) {
                console.error('Day Plan: Failed to parse JSON string:', parseError)
                throw new Error('Failed to parse AI response')
            }
        } else {
            parsed = result.data || result
        }

        console.log('Day Plan: Parsed data has', parsed?.dayPlan?.length, 'meals')

        // Validate the parsed data - dayPlan can be empty if all meals are eaten
        if (!parsed || !Array.isArray(parsed.dayPlan)) {
            console.error('Day Plan: Invalid response structure:', parsed)
            throw new Error('Invalid response from AI')
        }

        return {
            dayPlan: parsed.dayPlan,
            summary: parsed.summary || { totalPlannedCalories: 0, advice: 'Enjoy your day!' },
            context: {
                targetCalories,
                consumedCalories,
                remainingCalories,
                eatenMealTypes,
                remainingMealTypes,
            }
        }
    } catch (e) {
        console.error('Day Plan: AI generation error:', e)
        // Re-throw the error so the caller can handle it properly
        throw e
    }
}
