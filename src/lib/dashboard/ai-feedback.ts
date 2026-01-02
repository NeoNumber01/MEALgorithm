'use server'

import { model } from '@/lib/ai/client'

export async function generateGoalFeedback(data: {
    todayCalories: number
    weeklyAvgCalories: number
    targetCalories: number
    goalDescription?: string
}) {
    const prompt = `
You are a supportive nutritionist AI.
Based on the following data, provide a brief 1-2 sentence feedback on the user's progress.

Today's Calories: ${data.todayCalories} kcal
Weekly Average: ${data.weeklyAvgCalories} kcal
Target: ${data.targetCalories} kcal
User's Goal: ${data.goalDescription || 'Not specified'}

Respond with just the feedback text, no JSON.
Be encouraging but honest. Use an emoji at the start.
`

    try {
        const result = await model.generateContent(prompt)
        return { feedback: result.response.text() }
    } catch (e) {
        console.error('Goal feedback error:', e)
        return { feedback: '🎯 Keep tracking your meals to get personalized feedback!' }
    }
}
