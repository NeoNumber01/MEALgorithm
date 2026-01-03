import { NextRequest, NextResponse } from 'next/server'
import { GoogleGenerativeAI } from '@google/generative-ai'
import { createClient } from '@/lib/supabase/server'

// SECURITY: API Key is only accessed server-side in this route handler
// This route provides a secure proxy for AI operations

export async function POST(request: NextRequest) {
    // Verify user is authenticated
    const supabase = createClient()
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
        return NextResponse.json(
            { error: 'Unauthorized' },
            { status: 401 }
        )
    }

    // Get API key from server environment (never exposed to client)
    const apiKey = process.env.GEMINI_API_KEY
    
    if (!apiKey) {
        console.error('GEMINI_API_KEY not configured')
        return NextResponse.json(
            { error: 'AI service not configured' },
            { status: 500 }
        )
    }

    try {
        const body = await request.json()
        const { prompt, type } = body

        if (!prompt) {
            return NextResponse.json(
                { error: 'Prompt is required' },
                { status: 400 }
            )
        }

        // Validate request type to prevent abuse
        const allowedTypes = ['meal-analysis', 'recommendations', 'feedback']
        if (type && !allowedTypes.includes(type)) {
            return NextResponse.json(
                { error: 'Invalid request type' },
                { status: 400 }
            )
        }

        const genAI = new GoogleGenerativeAI(apiKey)
        const model = genAI.getGenerativeModel({
            model: 'gemini-2.5-flash',
            generationConfig: {
                responseMimeType: 'application/json',
            }
        })

        const result = await model.generateContent(prompt)
        const responseText = result.response.text()

        // Try to parse as JSON
        try {
            const parsed = JSON.parse(responseText)
            return NextResponse.json({ data: parsed })
        } catch {
            // Return raw text if not valid JSON
            return NextResponse.json({ data: responseText })
        }

    } catch (error) {
        console.error('AI API Error:', error)
        return NextResponse.json(
            { error: 'AI service error' },
            { status: 500 }
        )
    }
}

// Prevent GET requests
export async function GET() {
    return NextResponse.json(
        { error: 'Method not allowed' },
        { status: 405 }
    )
}
