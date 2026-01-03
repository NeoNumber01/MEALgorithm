import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

// SECURITY: This route proxies AI requests to Supabase Edge Functions
// The Gemini API key is stored securely in Supabase Edge Function environment

export async function POST(request: NextRequest) {
    // Verify user is authenticated
    const supabase = await createClient()
    const { data: { session }, error: authError } = await supabase.auth.getSession()

    if (authError || !session) {
        return NextResponse.json(
            { error: 'Unauthorized' },
            { status: 401 }
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

        // Forward request to Supabase Edge Function
        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
        const response = await fetch(`${supabaseUrl}/functions/v1/ai-generate`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${session.access_token}`,
            },
            body: JSON.stringify({ prompt, type }),
        })

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}))
            return NextResponse.json(
                { error: errorData.error || 'AI service error' },
                { status: response.status }
            )
        }

        const result = await response.json()
        return NextResponse.json(result)

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
