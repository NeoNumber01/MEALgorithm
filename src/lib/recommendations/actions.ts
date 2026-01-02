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

export async function getRecommendations() {
    const supabase = createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { error: 'Not authenticated' }

    // Get user profile
    const { data: profile } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single()

    // Get recent meals (last 3 days)
    const threeDaysAgo = new Date()
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3)

    const { data: recentMeals } = await supabase
        .from('meals')
        .select('*')
        .eq('user_id', user.id)
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

    const prompt = `
You are a helpful nutritionist AI. Based on the user's data, suggest 3 meal ideas for their next meal.

User Profile:
- Calorie Target: ${profile?.calorie_target || 2000} kcal/day
- Goal: ${profile?.goal_description || 'General health'}

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
