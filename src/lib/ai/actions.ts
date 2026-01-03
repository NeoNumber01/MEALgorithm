'use server'

import { model } from './client'
import { SYSTEM_PROMPT } from './prompts'
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

    const promptParts: (string | { inlineData: { data: string; mimeType: string } })[] = [SYSTEM_PROMPT]

    if (textInput) {
        promptParts.push(`\nUser Text Input: "${textInput}"`)
    }

    if (imageFile) {
        const bytes = await imageFile.arrayBuffer()
        const base64Data = Buffer.from(bytes).toString('base64')
        promptParts.push({
            inlineData: {
                data: base64Data,
                mimeType: imageFile.type,
            },
        })
        
        // Add user's additional description about the image
        if (imageDescription) {
            promptParts.push(`\nIMPORTANT - User's additional notes about this meal: "${imageDescription}"\nPlease consider these details when analyzing portion sizes and nutritional content. For example, if the user says they only ate 1/4 of the food shown, adjust the nutritional values accordingly.`)
        }
    }

    try {
        const result = await model.generateContent(promptParts)
        const responseText = result.response.text()

        // Attempt parse
        try {
            const parsed = MealAnalysisSchema.parse(JSON.parse(responseText))
            return { data: parsed }
        } catch (parseError) {
            console.warn('First parse failed, retrying...', parseError)

            // Retry logic: Feed error back to model
            const retryPrompt: (string | { inlineData: { data: string; mimeType: string } })[] = [
                ...promptParts,
                `\nPrevious Output: ${responseText}`,
                `\nError: The JSON was invalid. Please fix it to match the schema strictly. JSON only.`,
            ]

            const retryResult = await model.generateContent(retryPrompt)
            const retryText = retryResult.response.text()
            try {
                const reParsed = MealAnalysisSchema.parse(JSON.parse(retryText))
                return { data: reParsed }
            } catch {
                return { error: 'Failed to parse AI response', raw: retryText }
            }
        }

    } catch (e) {
        console.error('Gemini API Error:', e)
        return { error: (e as Error).message || 'AI Service Error' }
    }
}
