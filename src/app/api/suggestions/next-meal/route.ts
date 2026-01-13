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

// Helper function to extract frequently mentioned ingredients
function extractFrequentIngredients(mealDescriptions: string[]): string[] {
    const combinedText = mealDescriptions.join(' ').toLowerCase()
    const foodKeywords = [
        'chicken', 'beef', 'pork', 'fish', 'salmon', 'tuna', 'shrimp',
        'rice', 'pasta', 'noodles', 'bread', 'potato',
        'salad', 'vegetables', 'broccoli', 'spinach', 'tomato',
        'eggs', 'cheese', 'yogurt', 'milk',
        'apple', 'banana', 'berries', 'orange',
        'tofu', 'beans', 'lentils',
        'avocado', 'nuts', 'almonds',
    ]
    return foodKeywords.filter(keyword => combinedText.includes(keyword)).slice(0, 8)
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
        if (!forceRefresh && profile?.cached_next_meal && profile?.next_meal_updated_at) {
            const cached = profile.cached_next_meal as { recommendations: unknown[], context: unknown }

            if (cached.recommendations && Array.isArray(cached.recommendations) && cached.recommendations.length > 0) {
                const cacheTime = new Date(profile.next_meal_updated_at).getTime()
                const lastMealTime = profile.last_meal_at ? new Date(profile.last_meal_at).getTime() : 0
                const profileUpdatedTime = profile.profile_updated_at ? new Date(profile.profile_updated_at).getTime() : 0

                if (cacheTime > lastMealTime && cacheTime > profileUpdatedTime) {
                    console.log('Next Meal API: Using cached data')
                    return NextResponse.json(cached)
                }
            }
        }

        console.log('Next Meal API: Generating new recommendations...')

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

        // Calculate averages
        let totalCalories = 0, mealCount = 0
        const mealDescriptions: string[] = []

        recentMeals?.forEach(meal => {
            const analysis = meal.analysis as MealAnalysis | null
            if (analysis?.summary) {
                totalCalories += analysis.summary.calories
                mealCount++
            }
            if (meal.text_content) mealDescriptions.push(meal.text_content)
        })

        const avgCalories = mealCount > 0 ? Math.round(totalCalories / mealCount) : 0

        // Build prompt
        const preferencesSection = []
        if (profile?.food_preferences) preferencesSection.push(`- Favorite Foods: ${profile.food_preferences}`)
        if (profile?.food_dislikes) preferencesSection.push(`- Foods to Avoid: ${profile.food_dislikes}`)
        if (profile?.dietary_restrictions) preferencesSection.push(`- Dietary Restrictions: ${profile.dietary_restrictions}`)

        const frequentIngredients = extractFrequentIngredients(mealDescriptions)

        const prompt = `You are a helpful nutritionist AI. Suggest 3 meal ideas.

User Profile:
- Calorie Target: ${profile?.calorie_target || 2000} kcal/day
- Goal: ${profile?.goal === 'weight-loss' ? 'Weight Loss' : profile?.goal === 'muscle-gain' ? 'Muscle Gain' : 'Maintenance'}

${preferencesSection.length > 0 ? `Preferences:\n${preferencesSection.join('\n')}` : ''}
${frequentIngredients.length > 0 ? `User enjoys: ${frequentIngredients.join(', ')}` : ''}

Recent averages: ${avgCalories} kcal per meal

Respond in JSON format:
{
  "recommendations": [
    {
      "name": "Meal name",
      "description": "Brief description",
      "reason": "Why this is good",
      "nutrition": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 }
    }
  ]
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

        if (!parsed?.recommendations || !Array.isArray(parsed.recommendations)) {
            console.error('Invalid AI response:', parsed)
            return NextResponse.json({ error: 'Invalid AI response' }, { status: 500 })
        }

        const result = {
            recommendations: parsed.recommendations,
            context: {
                targetCalories: profile?.calorie_target || 2000,
                recentAvgCalories: avgCalories,
                goal: profile?.goal,
            }
        }

        // Cache the result
        await supabase
            .from('profiles')
            .update({
                cached_next_meal: result,
                next_meal_updated_at: new Date().toISOString(),
            })
            .eq('id', user.id)

        console.log('Next Meal API: Generated', parsed.recommendations.length, 'recommendations')
        return NextResponse.json(result)

    } catch (error) {
        console.error('Next Meal API error:', error)
        return NextResponse.json({ error: 'Failed to generate recommendations' }, { status: 500 })
    }
}
