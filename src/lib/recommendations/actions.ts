'use server'

import { createClient } from '@/lib/supabase/server'
import { model } from '@/lib/ai/client'

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
    const supabase = createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { error: 'Not authenticated' }

    // Get user profile with cache info
    const { data: profile } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single()

    // Check if we should use cache
    if (!forceRefresh && profile?.cached_next_meal && profile?.next_meal_updated_at) {
        const cached = profile.cached_next_meal as RecommendationResult
        const cacheTime = new Date(profile.next_meal_updated_at).getTime()
        const lastMealTime = profile.last_meal_at ? new Date(profile.last_meal_at).getTime() : 0

        // Check if the cached targets match current profile targets
        // This prevents unnecessary regeneration when profile is saved with same values
        const cachedTargetCalories = cached.context?.targetCalories
        const currentTargetCalories = profile.calorie_target || 2000
        const targetsMatch = cachedTargetCalories === currentTargetCalories

        // Use cache if:
        // 1. Cache is newer than last meal, AND
        // 2. Target values haven't actually changed
        if (cacheTime > lastMealTime && targetsMatch) {
            return cached
        }
    }

    // Generate new recommendations
    const result = await generateNewRecommendations(user.id, profile)

    // Cache the result
    if (!('error' in result)) {
        await supabase
            .from('profiles')
            .update({
                cached_next_meal: result,
                next_meal_updated_at: new Date().toISOString(),
            })
            .eq('id', user.id)
    }

    return result
}

// Internal function to generate new recommendations
// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function generateNewRecommendations(userId: string, profile: any): Promise<RecommendationResult> {
    const supabase = createClient()

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
        const result = await model.generateContent(prompt)
        const text = result.response.text()
        const parsed = JSON.parse(text)

        return {
            recommendations: parsed.recommendations,
            context: {
                targetCalories: profile?.calorie_target || 2000,
                recentAvgCalories: avgCalories,
                goal: profile?.goal_description,
            }
        }
    } catch (e) {
        console.error('Recommendations error:', e)
        return {
            recommendations: [
                {
                    name: 'Grilled Chicken Salad',
                    description: 'Fresh greens with grilled chicken breast and light vinaigrette.',
                    reason: 'High protein, low calorie option perfect for staying on track.',
                    nutrition: { calories: 350, protein: 35, carbs: 15, fat: 12 }
                },
                {
                    name: 'Salmon with Vegetables',
                    description: 'Baked salmon fillet with steamed broccoli and quinoa.',
                    reason: 'Rich in omega-3s and complete protein.',
                    nutrition: { calories: 450, protein: 40, carbs: 25, fat: 18 }
                },
                {
                    name: 'Greek Yogurt Bowl',
                    description: 'Greek yogurt with berries, honey, and granola.',
                    reason: 'Great for a light snack with protein and probiotics.',
                    nutrition: { calories: 280, protein: 18, carbs: 35, fat: 8 }
                }
            ],
            context: {
                targetCalories: 2000,
                recentAvgCalories: avgCalories,
                goal: 'General health',
            }
        }
    }
}

// Get cached day plan or generate new one
export async function getDayPlan(forceRefresh = false): Promise<DayPlanResult | { error: string }> {
    const supabase = createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { error: 'Not authenticated' }

    // Get user profile with cache info
    const { data: profile } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single()

    // Check if we should use cache
    if (!forceRefresh && profile?.cached_day_plan && profile?.day_plan_updated_at) {
        const cached = profile.cached_day_plan as DayPlanResult
        const cacheTime = new Date(profile.day_plan_updated_at).getTime()
        const lastMealTime = profile.last_meal_at ? new Date(profile.last_meal_at).getTime() : 0

        // Check if the cached targets match current profile targets
        const cachedTargetCalories = cached.context?.targetCalories
        const currentTargetCalories = profile.calorie_target || 2000
        const targetsMatch = cachedTargetCalories === currentTargetCalories

        // Use cache if:
        // 1. Cache is newer than last meal, AND
        // 2. Target values haven't actually changed
        if (cacheTime > lastMealTime && targetsMatch) {
            return cached
        }
    }

    // Generate new day plan
    const result = await generateNewDayPlan(user.id, profile)

    // Cache the result
    if (!('error' in result)) {
        await supabase
            .from('profiles')
            .update({
                cached_day_plan: result,
                day_plan_updated_at: new Date().toISOString(),
            })
            .eq('id', user.id)
    }

    return result
}

// Internal function to generate new day plan
// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function generateNewDayPlan(userId: string, profile: any): Promise<DayPlanResult> {
    const supabase = createClient()

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
        const result = await model.generateContent(prompt)
        const text = result.response.text()
        const parsed = JSON.parse(text)

        return {
            dayPlan: parsed.dayPlan,
            summary: parsed.summary,
            context: {
                targetCalories,
                consumedCalories,
                remainingCalories,
                eatenMealTypes,
                remainingMealTypes,
            }
        }
    } catch (e) {
        console.error('Day plan error:', e)
        return {
            dayPlan: remainingMealTypes.map(mealType => ({
                mealType,
                name: mealType === 'breakfast' ? 'Oatmeal with Fruits' :
                    mealType === 'lunch' ? 'Grilled Chicken Salad' :
                        mealType === 'dinner' ? 'Salmon with Vegetables' : 'Greek Yogurt',
                description: 'A balanced and nutritious option.',
                nutrition: {
                    calories: Math.round(remainingCalories / Math.max(1, remainingMealTypes.length)),
                    protein: 25,
                    carbs: 30,
                    fat: 10
                }
            })),
            summary: {
                totalPlannedCalories: remainingCalories,
                advice: 'Stay hydrated and maintain balanced portions throughout the day.'
            },
            context: {
                targetCalories,
                consumedCalories,
                remainingCalories,
                eatenMealTypes,
                remainingMealTypes,
            }
        }
    }
}
