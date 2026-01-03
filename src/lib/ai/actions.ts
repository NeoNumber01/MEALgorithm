'use server'

import { createClient } from '@/lib/supabase/server'
import { MealAnalysisSchema } from './schema'


export async function analyzeMeal(formData: FormData) {
    const textInput = formData.get('text') as string | null
    const imageFile = formData.get('image') as File | null
    const imageDescription = formData.get('imageDescription') as string | null

    if (!textInput && !imageFile) {
        console.log('analyzeMeal: No input provided')
        return { error: 'No input provided' }
    }

    console.log('analyzeMeal: Processing input...', { 
        text: textInput, 
        hasImage: !!imageFile,
        imageDescription: imageDescription 
    })

    // Get Supabase client and user for auth
    const supabase = await createClient()
    
    // First verify the user is authenticated
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    
    if (userError || !user) {
        console.error('Auth error:', userError)
        return { error: 'Unauthorized - please sign in' }
    }

    // Get session for access token
    const { data: { session }, error: sessionError } = await supabase.auth.getSession()
    
    if (sessionError || !session?.access_token) {
        console.error('Session error:', sessionError)
        return { error: 'Session expired - please sign in again' }
    }

    // Prepare request body for Edge Function
    const requestBody: {
        text?: string
        imageBase64?: string
        imageMimeType?: string
        imageDescription?: string
    } = {}

    if (textInput) {
        requestBody.text = textInput
    }

    if (imageFile) {
        const bytes = await imageFile.arrayBuffer()
        const base64Data = Buffer.from(bytes).toString('base64')
        requestBody.imageBase64 = base64Data
        requestBody.imageMimeType = imageFile.type
        
        if (imageDescription) {
            requestBody.imageDescription = imageDescription
        }
    }

    try {
        // Call Supabase Edge Function
        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
        console.log('Calling Edge Function:', `${supabaseUrl}/functions/v1/analyze-meal`)
        
        const response = await fetch(`${supabaseUrl}/functions/v1/analyze-meal`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${session.access_token}`,
            },
            body: JSON.stringify(requestBody),
        })

        console.log('Edge Function response status:', response.status)

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}))
            console.error('Edge Function Error:', errorData)
            return { error: errorData.error || `Request failed: ${response.status}` }
        }

        const result = await response.json()

        // Validate with Zod schema
        try {
            const parsed = MealAnalysisSchema.parse(result.data)
            return { data: parsed }
        } catch (parseError) {
            console.warn('Schema validation failed:', parseError)
            // Return raw data if schema validation fails but response was successful
            return { data: result.data }
        }

    } catch (e) {
        console.error('Edge Function API Error:', e)
        return { error: (e as Error).message || 'AI Service Error' }
    }
}
