// Supabase Edge Function for generic AI generation with Gemini
// Deploy with: supabase functions deploy ai-generate --no-verify-jwt

import { GoogleGenerativeAI } from "npm:@google/generative-ai@0.21.0"
import { createClient } from "npm:@supabase/supabase-js@2"
import { corsHeaders, handleCors } from "../_shared/cors.ts"

interface AIGenerateRequest {
    prompt: string | Array<string | { inlineData: { data: string; mimeType: string } }>
    type?: "meal-analysis" | "recommendations" | "feedback"
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
        const body: AIGenerateRequest = await req.json()
        const { prompt, type } = body

        if (!prompt) {
            return new Response(JSON.stringify({ error: "Prompt is required" }), {
                status: 400,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            })
        }

        // Validate request type
        const allowedTypes = ["meal-analysis", "recommendations", "feedback"]
        if (type && !allowedTypes.includes(type)) {
            return new Response(JSON.stringify({ error: "Invalid request type" }), {
                status: 400,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            })
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
        const result = await model.generateContent(prompt)
        const responseText = result.response.text()

        // Try to parse as JSON
        try {
            const parsed = JSON.parse(responseText)
            return new Response(JSON.stringify({ data: parsed }), {
                status: 200,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            })
        } catch {
            // Return raw text if not valid JSON
            return new Response(JSON.stringify({ data: responseText }), {
                status: 200,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            })
        }
    } catch (error) {
        console.error("AI Generate Error:", error)
        return new Response(JSON.stringify({ error: error.message || "AI service error" }), {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        })
    }
})
