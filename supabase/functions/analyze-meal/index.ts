// Supabase Edge Function for Meal Analysis with Gemini AI
// Deploy with: supabase functions deploy analyze-meal --no-verify-jwt

import { GoogleGenerativeAI } from "npm:@google/generative-ai@0.21.0"
import { createClient } from "npm:@supabase/supabase-js@2"
import { corsHeaders, handleCors } from "../_shared/cors.ts"

const SYSTEM_PROMPT = `
You are an expert Nutritionist AI.
Your task is to analyze the user's meal input (text or image) and output a structured nutritional analysis.

Rules:
1. Identify all food items and estimate their portions.
2. Estimate calories, protein(g), carbs(g), and fat(g) for each item.
3. Provide a summary of the total values.
4. Give a short, encouraging feedback message (max 2 sentences).
5. Output strict JSON format matching the schema:
   {
     "items": [{ "name": "...", "quantity": "...", "nutrition": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 }, "confidence": 0.8 }],
     "summary": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 },
     "feedback": "..."
   }
`

interface MealAnalysisRequest {
    text?: string
    imageBase64?: string
    imageMimeType?: string
    imageDescription?: string
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

        // Get Gemini API key from environment
        const apiKey = Deno.env.get("GEMINI_API_KEY")
        if (!apiKey) {
            console.error("GEMINI_API_KEY not configured")
            return new Response(JSON.stringify({ error: "AI service not configured" }), {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            })
        }

        // Parse request body
        const body: MealAnalysisRequest = await req.json()
        const { text, imageBase64, imageMimeType, imageDescription } = body

        if (!text && !imageBase64) {
            return new Response(JSON.stringify({ error: "No input provided" }), {
                status: 400,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            })
        }

        // Build prompt parts
        const promptParts: (string | { inlineData: { data: string; mimeType: string } })[] = [SYSTEM_PROMPT]

        if (text) {
            promptParts.push(`\nUser Text Input: "${text}"`)
        }

        if (imageBase64 && imageMimeType) {
            promptParts.push({
                inlineData: {
                    data: imageBase64,
                    mimeType: imageMimeType,
                },
            })

            if (imageDescription) {
                promptParts.push(`\nIMPORTANT - User's additional notes about this meal: "${imageDescription}"\nPlease consider these details when analyzing portion sizes and nutritional content.`)
            }
        }

        // Initialize Gemini AI
        const genAI = new GoogleGenerativeAI(apiKey)
        const model = genAI.getGenerativeModel({
            model: "gemini-2.0-flash",
            generationConfig: {
                responseMimeType: "application/json",
            },
        })

        // Generate content
        const result = await model.generateContent(promptParts)
        const responseText = result.response.text()

        // Parse and validate response
        try {
            const parsed = JSON.parse(responseText)
            return new Response(JSON.stringify({ data: parsed }), {
                status: 200,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            })
        } catch (parseError) {
            console.warn("First parse failed, retrying...", parseError)

            // Retry with error feedback
            const retryPrompt = [
                ...promptParts,
                `\nPrevious Output: ${responseText}`,
                `\nError: The JSON was invalid. Please fix it to match the schema strictly. JSON only.`,
            ]

            const retryResult = await model.generateContent(retryPrompt)
            const retryText = retryResult.response.text()

            try {
                const reParsed = JSON.parse(retryText)
                return new Response(JSON.stringify({ data: reParsed }), {
                    status: 200,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                })
            } catch {
                return new Response(JSON.stringify({ error: "Failed to parse AI response", raw: retryText }), {
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
