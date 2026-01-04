
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "npm:@google/generative-ai"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const apiKey = Deno.env.get('GEMINI_API_KEY')
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY is not set in Supabase Secrets')
    }

    const { action, payload } = await req.json()
    
    // Initialize Gemini with the updated model
    const genAI = new GoogleGenerativeAI(apiKey)
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" })

    let resultText = ""

    switch (action) {
      case 'analyzeMeal':
        resultText = await analyzeMeal(model, payload)
        break
      case 'recommend':
        resultText = await generateRecommendations(model, payload)
        break
      case 'dayPlan':
        resultText = await generateDayPlan(model, payload)
        break
      case 'feedback':
        resultText = await generateFeedback(model, payload)
        break
      case 'stats':
        resultText = await generateStatsInsight(model, payload)
        break
      default:
        throw new Error(`Unknown action: ${action}`)
    }

    return new Response(JSON.stringify({ data: resultText }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error("Error processing request:", error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

// --- Helper Functions ---

async function analyzeMeal(model: any, payload: any) {
  const systemPrompt = `
    You are an expert Nutritionist AI.
    Your task is to analyze the user's meal input (text or image) and output a structured nutritional analysis.
    
    Rules:
    1. Identify all food items and estimate their portions.
    2. Estimate calories, protein(g), carbs(g), and fat(g) for each item.
    3. Provide a summary of the total values.
    4. Give a short, encouraging feedback message (max 2 sentences).
    5. Output strict JSON format matching the schema:
       {
         "items": [{ "name": "...", "quantity": "...", "nutrition": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 } }],
         "summary": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 },
         "feedback": "..."
       }
  `

  const parts: any[] = [systemPrompt]
  
  if (payload.text) {
    parts.push(`\nUser Text Input: "${payload.text}"`)
  }
  
  if (payload.imageBase64) {
    parts.push({
      inlineData: {
        data: payload.imageBase64,
        mimeType: "image/jpeg"
      }
    })
  }

  // Generate content
  const result = await model.generateContent(parts)
  const response = await result.response
  return response.text()
}

async function generateRecommendations(model: any, payload: any) {
  const prompt = `
    You are a personalized meal recommendation AI.
    
    User Context:
    - Daily calorie target: ${payload.targetCalories} kcal
    - Recent average calories per meal: ${payload.recentAvgCalories} kcal
    - Goal: ${payload.goal || "General Health"}
    - Food preferences: ${payload.preferences ? payload.preferences.join(", ") : "None specified"}
    
    Generate 3 meal recommendations. Output strict JSON array:
    [
      {
        "name": "Meal Name",
        "description": "Brief description",
        "reason": "Why this meal is recommended",
        "nutrition": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 }
      }
    ]
  `
  
  const result = await model.generateContent(prompt)
  const response = await result.response
  return response.text()
}

async function generateDayPlan(model: any, payload: any) {
  const prompt = `
    You are a meal planning AI.
    
    User Context:
    - Daily target: ${payload.targetCalories} kcal
    - Already consumed: ${payload.consumedCalories} kcal
    - Remaining calories: ${payload.targetCalories - payload.consumedCalories} kcal
    - Already eaten: ${!payload.eatenMealTypes || payload.eatenMealTypes.length === 0 ? "Nothing yet" : payload.eatenMealTypes.join(", ")}
    - Meals to plan: ${payload.remainingMealTypes ? payload.remainingMealTypes.join(", ") : "breakfast, lunch, dinner"}
    - Goal: ${payload.goal || "General Health"}
    - Preferences: ${payload.preferences ? payload.preferences.join(", ") : "None"}
    
    Create a meal plan for the remaining meals. Output strict JSON:
    {
      "dayPlan": [
        {
          "mealType": "breakfast|lunch|dinner|snack",
          "name": "Meal Name",
          "description": "Brief description",
          "nutrition": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 }
        }
      ],
      "summary": {
        "totalPlannedCalories": 0,
        "advice": "Brief nutritional advice"
      }
    }
  `

  const result = await model.generateContent(prompt)
  const response = await result.response
  return response.text()
}

async function generateFeedback(model: any, payload: any) {
  const prompt = `
    You are a supportive and motivating nutritionist AI coach.
    Based on the following data, provide a brief 1-2 sentence personalized feedback focused on TODAY's intake.
    
    Today's Calories: ${payload.todayCalories} kcal (${payload.todayPercent}% of target)
    Weekly Average: ${payload.weeklyAvgCalories} kcal (${payload.weeklyPercent}% of target)
    Daily Target: ${payload.targetCalories} kcal
    User's Goal: ${payload.goal || "General health and wellness"}
    
    Guidelines:
    - Focus primarily on TODAY's performance
    - If today is on target (80-120%), be encouraging and celebrate
    - If today is under target, suggest easy ways to add healthy calories
    - If today is over target, be gentle and suggest balance
    - Keep it positive and actionable
    - Use an emoji at the start that matches the mood
    - If there's no data today, encourage them to log their first meal
    
    Respond with just the feedback text, no JSON or markdown.
  `

  const result = await model.generateContent(prompt)
  const response = await result.response
  let text = response.text()
  
  // Clean response similar to client side
  text = text.trim()
  text = text.replace(/```json/g, "").replace(/```text/g, "").replace(/```/g, "")
  if (text.startsWith('"') && text.endsWith('"')) {
      text = text.substring(1, text.length - 1)
  }
  return text
}

async function generateStatsInsight(model: any, payload: any) {
  const prompt = `
    You are a supportive nutritionist AI analyzing a user's eating habits over a time period.
    Based on the following statistics, provide 2-3 sentences of insightful feedback and actionable advice.
    
    Period: ${payload.periodLabel}
    Days in Period: ${payload.totalDays}
    Days with Logged Meals: ${payload.daysWithMeals} (${payload.trackingRate}% tracking rate)
    Total Meals: ${payload.totalMeals}
    
    Daily Averages:
    - Calories: ${payload.avgCalories} kcal (${payload.avgPercent}% of ${payload.targetCalories} kcal target)
    - Protein: ${payload.avgProtein}g
    - Carbs: ${payload.avgCarbs}g
    - Fat: ${payload.avgFat}g
    
    User's Goal: ${payload.goalDescription || "General health and wellness"}
    
    Guidelines:
    - Analyze patterns and trends they should be aware of
    - Highlight what they're doing well (be specific)
    - Give one concrete, actionable suggestion for improvement
    - If tracking rate is low, encourage more consistent logging
    - Consider macro balance (protein for muscle, not just calories)
    - Use an emoji at the start
    - Be encouraging and insightful, not preachy
    
    Respond with just the feedback text, no JSON or markdown.
  `

  const result = await model.generateContent(prompt)
  const response = await result.response
  let text = response.text()
  
  // Clean response
  text = text.trim()
  text = text.replace(/```json/g, "").replace(/```text/g, "").replace(/```/g, "")
  if (text.startsWith('"') && text.endsWith('"')) {
      text = text.substring(1, text.length - 1)
  }
  return text
}
