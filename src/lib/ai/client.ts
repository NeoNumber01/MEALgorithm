import { GoogleGenerativeAI } from '@google/generative-ai'

// SECURITY: Ensure this module only runs on the server
// This check prevents accidental client-side bundling of the API key
if (typeof window !== 'undefined') {
    throw new Error('AI client module cannot be imported on the client side!')
}

const apiKey = process.env.GEMINI_API_KEY

if (!apiKey) {
    throw new Error('Missing GEMINI_API_KEY environment variable')
}

const genAI = new GoogleGenerativeAI(apiKey)

// Using gemini-1.5-flash as a stable default, or gemini-2.0-flash-exp if available and desired.
// Ideally usage of 'gemini-1.5-flash' is safest for general demo stability.
export const model = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash',
    generationConfig: {
        responseMimeType: "application/json",
    }
})
