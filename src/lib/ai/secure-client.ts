/**
 * Secure AI client for browser-side calls
 * 
 * SECURITY: This module calls Supabase Edge Functions instead of directly
 * using the Gemini API key. The API key is stored securely in Supabase
 * and never exposed to the client.
 */

import { createClient } from '@/lib/supabase/client'

export type AIRequestType = 'meal-analysis' | 'recommendations' | 'feedback'

interface AIResponse<T = unknown> {
    data?: T
    error?: string
}

/**
 * Call the AI service through Supabase Edge Functions
 * @param prompt - The prompt to send to the AI
 * @param type - The type of request (for validation and rate limiting)
 * @returns The AI response data or error
 */
export async function callAI<T = unknown>(
    prompt: string | Array<string | { inlineData: { data: string; mimeType: string } }>,
    type?: AIRequestType
): Promise<AIResponse<T>> {
    try {
        const supabase = createClient()
        const { data: { session } } = await supabase.auth.getSession()

        if (!session) {
            return { error: 'Unauthorized - please sign in' }
        }

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
            return { error: errorData.error || `Request failed: ${response.status}` }
        }

        const result = await response.json()
        return { data: result.data as T }

    } catch (error) {
        console.error('AI client error:', error)
        return { error: 'Failed to connect to AI service' }
    }
}

/**
 * Example usage:
 * 
 * // In a client component:
 * import { callAI } from '@/lib/ai/secure-client'
 * 
 * const result = await callAI<MealAnalysis>(
 *   'Analyze this meal: chicken salad with quinoa',
 *   'meal-analysis'
 * )
 * 
 * if (result.error) {
 *   console.error(result.error)
 * } else {
 *   console.log(result.data)
 * }
 */
