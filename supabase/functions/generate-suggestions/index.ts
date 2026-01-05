// Supabase Edge Function for Meal Suggestions with Gemini AI
// Deploy with: supabase functions deploy generate-suggestions --no-verify-jwt

import { GoogleGenerativeAI } from "npm:@google/generative-ai@0.21.0"
import { createClient } from "npm:@supabase/supabase-js@2"
import { corsHeaders, handleCors } from "../_shared/cors.ts"

interface SuggestionsRequest {
    type: "next-meal" | "day-plan" | "coach"
    forceRefresh?: boolean
    // Day plan context passed from frontend for consistency
    dayPlanContext?: {
        consumed: number
        remaining: number
        mealsLeft: string[]  // Only main meals: ['breakfast', 'lunch', 'dinner']
        includeSnack?: boolean  // Whether to add a snack recommendation
        // Macro targets for nutrition-based planning
        remainingProtein?: number
        remainingCarbs?: number
        remainingFat?: number
    }
    coachContext?: {
        context: "today" | "statistics"
        todayCalories?: number
        todayProtein?: number
        todayCarbs?: number
        todayFat?: number
        mealCount?: number
        mealTypes?: string[]  // e.g., ['breakfast', 'lunch']
        targetProtein?: number
        targetCarbs?: number
        targetFat?: number
        avgCalories?: number
        avgProtein?: number
        avgCarbs?: number
        avgFat?: number
        consistencyScore?: number
        totalMeals?: number
        daysWithMeals?: number
        totalDays?: number
        avgMealsPerDay?: string
        avgProteinPerMeal?: number
        timeRangeLabel?: string
        macroBalanceProtein?: number
        macroBalanceCarbs?: number
        macroBalanceFat?: number
    }
}

interface UserProfile {
    calorie_target?: number
    goal_description?: string
    food_preferences?: string
    food_dislikes?: string
    dietary_restrictions?: string
}

const NEXT_MEAL_PROMPT = (profile: UserProfile) => {
    // Random cuisine suggestions for variety
    const cuisines = ['Italian', 'Mexican', 'Japanese', 'Chinese', 'Thai', 'Indian', 'Mediterranean', 'American', 'Korean', 'Vietnamese', 'Greek', 'Middle Eastern', 'French', 'Spanish']
    const mealStyles = ['quick and easy', 'hearty and filling', 'light and refreshing', 'high-protein', 'comfort food', 'colorful and nutritious', 'simple and delicious', 'energy-boosting']

    const randomCuisine = cuisines[Math.floor(Math.random() * cuisines.length)]
    const randomStyle = mealStyles[Math.floor(Math.random() * mealStyles.length)]

    return `
You are a creative nutritionist AI. Suggest 3 UNIQUE and VARIED meal ideas based on the user's profile.
IMPORTANT: Be creative! Suggest DIFFERENT meals each time - avoid repetitive recommendations.

Today's inspiration: Try ${randomStyle} ${randomCuisine} cuisine or similar.
Variation seed: ${Date.now()}-${Math.random().toString(36).substring(7)}

User Profile:
- Calorie Target: ${profile.calorie_target || 2000} kcal/day
- Goal: ${profile.goal_description || 'General health'}
${profile.food_preferences ? `- Favorite Foods (PRIORITIZE THESE): ${profile.food_preferences}` : ''}
${profile.food_dislikes ? `- Foods to AVOID (DO NOT SUGGEST): ${profile.food_dislikes}` : ''}
${profile.dietary_restrictions ? `- Dietary Restrictions (MUST RESPECT): ${profile.dietary_restrictions}` : ''}

CRITICAL INSTRUCTIONS:
1. Each of the 3 suggestions should be DISTINCTLY DIFFERENT from each other
2. If user has favorite foods, include at least one meal featuring them
3. NEVER suggest foods the user dislikes or has restrictions against
4. Vary the cuisines, cooking methods, and main ingredients across suggestions
5. Make recommendations specific (e.g., "Grilled Salmon with Quinoa Salad" not just "Fish")

Respond in strict JSON format:
{
  "recommendations": [
    {
      "name": "Specific meal name with main ingredients",
      "description": "Brief 1-sentence appealing description",
      "reason": "Why this matches the user's preferences and goals",
      "nutrition": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 }
    }
  ]
}
`
}

// Helper function to generate a random seed for variety
function getRandomSeed(): string {
    const themes = [
        'comfort food', 'light and fresh', 'protein-rich', 'Mediterranean',
        'Asian-inspired', 'home-cooked classics', 'quick and easy',
        'vegetable-forward', 'hearty and filling', 'international flavors',
        'seasonal ingredients', 'high-fiber', 'low-carb options', 'balanced nutrition',
        'energy-boosting', 'satisfying meals', 'colorful dishes', 'simple ingredients'
    ]
    const styles = [
        'Try something new today!', 'Focus on variety', 'Mix textures and flavors',
        'Balance your macros', 'Include vegetables', 'Stay hydrated',
        'Enjoy mindful eating', 'Simple is delicious', 'Fuel your body well'
    ]
    const randomTheme = themes[Math.floor(Math.random() * themes.length)]
    const randomStyle = styles[Math.floor(Math.random() * styles.length)]
    return `Today's theme: ${randomTheme}. ${randomStyle}`
}

// Calculate calorie distribution across MAIN meals only (no snack)
// Snack calories are calculated separately if includeSnack is true
function getCalorieDistribution(remaining: number, mealsLeft: string[], includeSnack: boolean): { mainMealDistribution: string, snackCalories: number } {
    if (mealsLeft.length === 0 && !includeSnack) {
        return { mainMealDistribution: 'No meals to plan.', snackCalories: 0 }
    }

    // Reserve ~10-15% for snack if included, rest goes to main meals
    let snackCalories = 0
    let mainMealCalories = remaining

    if (includeSnack && remaining > 100) {
        // Snack gets 10-15% of remaining, capped at 200 kcal
        snackCalories = Math.min(200, Math.round(remaining * 0.12))
        mainMealCalories = remaining - snackCalories
    }

    // Distribute main meal calories evenly
    const perMealCalories = mealsLeft.length > 0 ? Math.round(mainMealCalories / mealsLeft.length) : 0

    const distribution: string[] = []
    for (const meal of mealsLeft) {
        distribution.push(`${meal}: ~${perMealCalories} kcal`)
    }

    const mainMealDistribution = distribution.length > 0
        ? `Suggested calorie distribution for main meals:\n${distribution.join('\n')}`
        : 'No main meals to plan.'

    return { mainMealDistribution, snackCalories }
}

interface MacroTargets {
    remainingProtein: number
    remainingCarbs: number
    remainingFat: number
}

// Calculate macro distribution across MAIN meals only (no snack)
function getMacroDistribution(macros: MacroTargets, mealsLeft: string[], includeSnack: boolean): { mainMealMacros: string, snackMacros: { protein: number, carbs: number, fat: number } } {
    if (mealsLeft.length === 0 && !includeSnack) {
        return { mainMealMacros: '', snackMacros: { protein: 0, carbs: 0, fat: 0 } }
    }

    // Reserve ~10% for snack if included
    const snackRatio = includeSnack ? 0.10 : 0
    const mainMealRatio = mealsLeft.length > 0 ? (1 - snackRatio) / mealsLeft.length : 0

    const snackMacros = {
        protein: Math.round(macros.remainingProtein * snackRatio),
        carbs: Math.round(macros.remainingCarbs * snackRatio),
        fat: Math.round(macros.remainingFat * snackRatio),
    }

    const distribution: string[] = []
    for (const meal of mealsLeft) {
        const protein = Math.round(macros.remainingProtein * mainMealRatio)
        const carbs = Math.round(macros.remainingCarbs * mainMealRatio)
        const fat = Math.round(macros.remainingFat * mainMealRatio)
        distribution.push(`${meal}: ~${protein}g protein, ~${carbs}g carbs, ~${fat}g fat`)
    }

    const mainMealMacros = distribution.length > 0
        ? `Suggested macro distribution per main meal:\n${distribution.join('\n')}`
        : ''

    return { mainMealMacros, snackMacros }
}

const DAY_PLAN_PROMPT = (profile: UserProfile, consumed: number, remaining: number, mealsLeft: string[], includeSnack: boolean, macros?: MacroTargets) => {
    const randomSeed = getRandomSeed()
    const { mainMealDistribution, snackCalories } = getCalorieDistribution(remaining, mealsLeft, includeSnack)
    const { mainMealMacros, snackMacros } = macros
        ? getMacroDistribution(macros, mealsLeft, includeSnack)
        : { mainMealMacros: '', snackMacros: { protein: 0, carbs: 0, fat: 0 } }

    // Calculate total meals to plan
    const totalMealsToplan = mealsLeft.length + (includeSnack ? 1 : 0)
    const mealsDescription = includeSnack
        ? `${mealsLeft.join(', ')} (main meals) + 1 snack`
        : mealsLeft.join(', ') || 'no meals remaining'

    return `
You are a creative nutritionist AI. Create a UNIQUE and VARIED meal plan for remaining meals today.
IMPORTANT: Be creative and suggest DIFFERENT meals each time. Avoid repetitive suggestions.

${randomSeed}
Random variation seed: ${Date.now()}-${Math.random().toString(36).substring(7)}

User Profile:
- Daily Calorie Target: ${profile.calorie_target || 2000} kcal
- Goal: ${profile.goal_description || 'General health'}
${profile.food_preferences ? `- Favorite Foods (PRIORITIZE THESE): ${profile.food_preferences}` : ''}
${profile.food_dislikes ? `- Foods to AVOID (DO NOT SUGGEST): ${profile.food_dislikes}` : ''}
${profile.dietary_restrictions ? `- Dietary Restrictions (MUST RESPECT): ${profile.dietary_restrictions}` : ''}

Today's Progress:
- Already consumed: ${consumed} kcal
- Remaining calorie budget: ${remaining} kcal
${macros ? `- Remaining protein: ${macros.remainingProtein}g` : ''}
${macros ? `- Remaining carbs: ${macros.remainingCarbs}g` : ''}
${macros ? `- Remaining fat: ${macros.remainingFat}g` : ''}
- Meals to plan: ${mealsDescription}

${mainMealDistribution}
${includeSnack ? `\nSnack allocation: ~${snackCalories} kcal (~${snackMacros.protein}g protein, ~${snackMacros.carbs}g carbs, ~${snackMacros.fat}g fat)` : ''}

${mainMealMacros}

CRITICAL INSTRUCTIONS:
1. Plan EXACTLY ${totalMealsToplan} meal(s): ${mealsLeft.length} main meal(s)${includeSnack ? ' + 1 snack' : ''}
2. PRIORITY ORDER: Plan main meals (${mealsLeft.join(', ')}) FIRST, then add snack if applicable
3. Main meals share the bulk of calories (~${remaining - snackCalories} kcal total)
${includeSnack ? `4. The snack should be light (~${snackCalories} kcal) and complement the main meals` : ''}
5. Total planned calories MUST equal approximately ${remaining} kcal (±50 kcal)
6. Total planned macros should approximately match: ${macros ? `${macros.remainingProtein}g protein, ${macros.remainingCarbs}g carbs, ${macros.remainingFat}g fat` : 'balanced nutrition'}
7. If user has favorite foods listed, incorporate them when appropriate
8. NEVER suggest foods the user dislikes or has restrictions against
9. Be creative - suggest varied cuisines, cooking styles, and ingredients
10. Match meal type to appropriate foods (e.g., lighter breakfast, satisfying dinner, light snack)

Respond in strict JSON format:
{
  "dayPlan": [
    {
      "mealType": "breakfast/lunch/dinner/snack",
      "name": "Specific meal name with main ingredients",
      "description": "Brief appealing description",
      "nutrition": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 }
    }
  ],
  "summary": {
    "totalPlannedCalories": 0,
    "totalPlannedProtein": 0,
    "totalPlannedCarbs": 0,
    "totalPlannedFat": 0,
    "advice": "Brief personalized advice for the day"
  }
}
`
}

Deno.serve(async (req: Request) => {
    // Handle CORS preflight requests
    const corsResponse = handleCors(req)
    if (corsResponse) return corsResponse

    // Only allow POST requests
    if (req.method !== "POST") {
        return new Response(JSON.stringify({ error: "Method not allowed" }), {
            status: 405,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        })
    }

    try {
        // Verify authentication
        const authHeader = req.headers.get("Authorization")
        if (!authHeader) {
            return new Response(JSON.stringify({ error: "Missing authorization header" }), {
                status: 401,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            })
        }

        // Verify user with Supabase
        const supabaseUrl = Deno.env.get("SUPABASE_URL")!
        const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!
        const supabase = createClient(supabaseUrl, supabaseAnonKey, {
            global: { headers: { Authorization: authHeader } },
        })

        const { data: { user }, error: authError } = await supabase.auth.getUser()
        if (authError || !user) {
            return new Response(JSON.stringify({ error: "Unauthorized" }), {
                status: 401,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            })
        }

        // Get Gemini API key
        const apiKey = Deno.env.get("GEMINI_API_KEY")
        if (!apiKey) {
            console.error("GEMINI_API_KEY not configured")
            return new Response(JSON.stringify({ error: "AI service not configured" }), {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            })
        }

        // Parse request body
        const body: SuggestionsRequest = await req.json()
        const { type } = body

        if (!type || !["next-meal", "day-plan", "coach"].includes(type)) {
            return new Response(JSON.stringify({ error: "Invalid request type" }), {
                status: 400,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            })
        }

        // Get user profile
        const { data: profile } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', user.id)
            .single()

        const userProfile: UserProfile = profile || {}

        // Build prompt based on request type
        let prompt: string

        if (type === "next-meal") {
            prompt = NEXT_MEAL_PROMPT(userProfile)
        } else if (type === "day-plan") {
            // Use context passed from frontend for consistency with displayed "Meals Left"
            // This avoids timezone issues between Edge Function (UTC) and frontend (user's timezone)
            const ctx = body.dayPlanContext

            let consumed: number
            let remaining: number
            let mealsLeft: string[]  // Only main meals (breakfast, lunch, dinner)
            let includeSnack: boolean

            if (ctx && ctx.mealsLeft && Array.isArray(ctx.mealsLeft)) {
                // Use frontend-calculated values for consistency
                console.log('Using dayPlanContext from frontend:', ctx)
                consumed = ctx.consumed
                remaining = ctx.remaining
                mealsLeft = ctx.mealsLeft  // Already filtered to main meals only
                includeSnack = ctx.includeSnack ?? (remaining > 100)  // Default: include if calories remain
            } else {
                // Fallback: calculate locally (may have timezone issues)
                console.log('No dayPlanContext provided, calculating locally')
                const today = new Date()
                const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate()).toISOString()

                const { data: todayMeals } = await supabase
                    .from('meals')
                    .select('*')
                    .eq('user_id', user.id)
                    .gte('created_at', startOfDay)

                consumed = 0
                const eatenTypes: string[] = []
                todayMeals?.forEach((meal: { analysis?: { summary?: { calories?: number } }, meal_type?: string }) => {
                    if (meal.analysis?.summary?.calories) {
                        consumed += meal.analysis.summary.calories
                    }
                    if (meal.meal_type) eatenTypes.push(meal.meal_type)
                })

                const target = userProfile.calorie_target || 2000
                remaining = Math.max(0, target - consumed)

                // Only main meals - snack is handled separately
                const mainMealTypes = ['breakfast', 'lunch', 'dinner']
                mealsLeft = mainMealTypes.filter(type => !eatenTypes.includes(type))

                // Include snack if not eaten and remaining calories > 100
                const hasEatenSnack = eatenTypes.includes('snack')
                includeSnack = !hasEatenSnack && remaining > 100
            }

            // Build macro targets if provided
            const macros: MacroTargets | undefined = ctx?.remainingProtein !== undefined ? {
                remainingProtein: ctx.remainingProtein || 0,
                remainingCarbs: ctx.remainingCarbs || 0,
                remainingFat: ctx.remainingFat || 0,
            } : undefined

            console.log('Day Plan - consumed:', consumed, 'remaining:', remaining, 'mealsLeft:', mealsLeft, 'includeSnack:', includeSnack, 'macros:', macros)
            prompt = DAY_PLAN_PROMPT(userProfile, consumed, remaining, mealsLeft, includeSnack, macros)
        }

        // Handle coach type (AI Coach insight)
        if (type === "coach") {
            const ctx = body.coachContext
            const target = userProfile.calorie_target || 2000

            if (ctx?.context === "today") {
                // Meal distribution ratios (default 4 meals: 3 main + 1 snack)
                const MEAL_RATIOS: Record<string, number> = {
                    breakfast: 0.25,  // 25%
                    lunch: 0.30,      // 30%
                    dinner: 0.30,     // 30%
                    snack: 0.15,      // 15%
                }

                // Calculate proportional targets based on consumed meal types
                const mealTypes = ctx.mealTypes || []
                let proportionalRatio = 0
                const uniqueMealTypes = [...new Set(mealTypes)] // Deduplicate
                for (const mealType of uniqueMealTypes) {
                    proportionalRatio += MEAL_RATIOS[mealType] || 0.25 // Default to 25% for unknown types
                }

                // If no meals, show 0% target; otherwise calculate proportional targets
                const proportionalCalorieTarget = Math.round(target * proportionalRatio)
                const proteinTarget = ctx.targetProtein || 100
                const carbsTarget = ctx.targetCarbs || 250
                const fatTarget = ctx.targetFat || 65
                const proportionalProteinTarget = Math.round(proteinTarget * proportionalRatio)
                const proportionalCarbsTarget = Math.round(carbsTarget * proportionalRatio)
                const proportionalFatTarget = Math.round(fatTarget * proportionalRatio)

                // Calculate percentages against proportional targets (avoid division by zero)
                const caloriePercent = proportionalCalorieTarget > 0
                    ? Math.round((ctx.todayCalories || 0) / proportionalCalorieTarget * 100)
                    : 0
                const proteinPercent = proportionalProteinTarget > 0
                    ? Math.round((ctx.todayProtein || 0) / proportionalProteinTarget * 100)
                    : 0
                const carbsPercent = proportionalCarbsTarget > 0
                    ? Math.round((ctx.todayCarbs || 0) / proportionalCarbsTarget * 100)
                    : 0
                const fatPercent = proportionalFatTarget > 0
                    ? Math.round((ctx.todayFat || 0) / proportionalFatTarget * 100)
                    : 0

                // Format meal types for display
                const mealsEatenList = uniqueMealTypes.length > 0
                    ? uniqueMealTypes.join(', ')
                    : 'none'
                const proportionalPercentage = Math.round(proportionalRatio * 100)

                prompt = `You are a friendly nutrition coach. The user has eaten ${ctx.mealCount || 0} meal(s): ${mealsEatenList}.
Based on our meal distribution (Breakfast 25%, Lunch 30%, Dinner 30%, Snack 15%), they should have consumed about ${proportionalPercentage}% of their daily targets by now.

CURRENT PROGRESS vs STAGE TARGETS (based on ${proportionalPercentage}% of daily goals):
- Calories: ${ctx.todayCalories || 0} / ${proportionalCalorieTarget} kcal (${caloriePercent}% of stage target)
- Protein: ${ctx.todayProtein || 0}g / ${proportionalProteinTarget}g (${proteinPercent}%)
- Carbs: ${ctx.todayCarbs || 0}g / ${proportionalCarbsTarget}g (${carbsPercent}%)
- Fat: ${ctx.todayFat || 0}g / ${proportionalFatTarget}g (${fatPercent}%)

Full Day Targets: ${target} kcal, ${proteinTarget}g protein, ${carbsTarget}g carbs, ${fatTarget}g fat
Goal: ${userProfile.goal_description || 'General health'}

Rules:
- Start with a relevant emoji (🎯🔥💪🥗✨📈)
- Compare actual intake to the STAGE TARGETS (proportional targets), NOT full day targets
- Highlight if significantly over (>120%) or under (<80%) the stage target for any macro
- If on track (80-120%), encourage them to keep it up
- If no meals logged, encourage them to log their first meal
- Keep it under 50 words, punchy and actionable

Respond in JSON: {"advice": "your advice with emoji"}`
            } else {
                // Statistics context - comprehensive analysis
                const avgPercent = ctx?.avgCalories ? Math.round(ctx.avgCalories / target * 100) : 0
                const timeRange = ctx?.timeRangeLabel || 'this period'

                prompt = `You are a friendly nutrition coach. Analyze the user's eating patterns for ${timeRange} and give a concise, actionable summary (2-3 sentences).

PERIOD: ${timeRange}

DAILY AVERAGES:
- Calories: ${ctx?.avgCalories || 0} kcal/day (${avgPercent}% of ${target} target)
- Protein: ${ctx?.avgProtein || 0}g/day
- Carbs: ${ctx?.avgCarbs || 0}g/day
- Fat: ${ctx?.avgFat || 0}g/day

MACRO BALANCE (by calories):
- Protein: ${ctx?.macroBalanceProtein || 0}%
- Carbs: ${ctx?.macroBalanceCarbs || 0}%
- Fat: ${ctx?.macroBalanceFat || 0}%

MEAL TRACKING:
- Total meals: ${ctx?.totalMeals || 0}
- Days tracked: ${ctx?.daysWithMeals || 0} of ${ctx?.totalDays || 0}
- Meals per day: ${ctx?.avgMealsPerDay || '0'}
- Protein per meal: ${ctx?.avgProteinPerMeal || 0}g

CONSISTENCY: ${ctx?.consistencyScore || 0}% of days within ±10% of calorie target

GOAL: ${userProfile.goal_description || 'General health'}

Rules:
- Start with a relevant emoji (📊📈💪🎯✨)
- Mention the time period analyzed
- Comment on macro balance if notable (ideal: ~25-30% protein, ~45-55% carbs, ~20-30% fat)
- Note meal frequency patterns if relevant
- Give ONE specific, actionable suggestion for improvement
- Keep it under 80 words, punchy and encouraging

Respond in JSON: {"advice": "your analysis with emoji"}`
            }
        }

        // Initialize Gemini AI
        const genAI = new GoogleGenerativeAI(apiKey)
        const model = genAI.getGenerativeModel({
            model: "gemini-2.0-flash",
            generationConfig: {
                responseMimeType: "application/json",
                maxOutputTokens: 2048,
            },
        })

        // Generate content
        const result = await model.generateContent(prompt)
        const responseText = result.response.text()

        // Parse and validate response
        try {
            const parsed = JSON.parse(responseText)
            return new Response(JSON.stringify({ data: parsed, type }), {
                status: 200,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            })
        } catch (parseError) {
            console.warn("First parse failed, retrying...", parseError)

            // Retry with error feedback
            const retryResult = await model.generateContent([
                prompt,
                `\nPrevious Output: ${responseText}`,
                `\nError: The JSON was invalid. Please fix it. JSON only, no markdown.`,
            ])
            const retryText = retryResult.response.text()

            try {
                const reParsed = JSON.parse(retryText)
                return new Response(JSON.stringify({ data: reParsed, type }), {
                    status: 200,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                })
            } catch {
                return new Response(JSON.stringify({ error: "Failed to parse AI response" }), {
                    status: 500,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                })
            }
        }
    } catch (error) {
        console.error("Edge Function Error:", error)
        return new Response(JSON.stringify({ error: error.message || "Internal server error" }), {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        })
    }
})
