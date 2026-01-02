import { GoogleGenerativeAI } from '@google/generative-ai'

if (!process.env.GEMINI_API_KEY) {
    throw new Error('Missing GEMINI_API_KEY environment variable')
}

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY)

// Using gemini-1.5-flash as a stable default, or gemini-2.0-flash-exp if available and desired.
// Ideally usage of 'gemini-1.5-flash' is safest for general demo stability.
export const model = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash',
    generationConfig: {
        responseMimeType: "application/json",
    }
})
