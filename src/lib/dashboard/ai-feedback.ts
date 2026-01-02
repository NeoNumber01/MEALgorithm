'use server'

import { model } from '@/lib/ai/client'

export async function generateGoalFeedback(data: {
    todayCalories: number
    weeklyAvgCalories: number
    targetCalories: number
    goalDescription?: string
}) {
    const todayPercent = Math.round((data.todayCalories / data.targetCalories) * 100)
    const weeklyPercent = Math.round((data.weeklyAvgCalories / data.targetCalories) * 100)

    const prompt = `
You are a supportive and motivating nutritionist AI coach.
Based on the following data, provide a brief 1-2 sentence personalized feedback focused on TODAY's intake.

Today's Calories: ${data.todayCalories} kcal (${todayPercent}% of target)
Weekly Average: ${data.weeklyAvgCalories} kcal (${weeklyPercent}% of target)
Daily Target: ${data.targetCalories} kcal
User's Goal: ${data.goalDescription || 'General health and wellness'}

Guidelines:
- Focus primarily on TODAY's performance
- If today is on target (80-120%), be encouraging and celebrate
- If today is under target, suggest easy ways to add healthy calories
- If today is over target, be gentle and suggest balance
- Keep it positive and actionable
- Use an emoji at the start that matches the mood
- If there's no data today, encourage them to log their first meal

Respond with just the feedback text, no JSON or markdown.
`

    try {
        const result = await model.generateContent(prompt)
        return { feedback: cleanResponse(result.response.text()) }
    } catch (e) {
        console.error('Goal feedback error:', e)
        return { feedback: '🎯 Keep tracking your meals to get personalized feedback!' }
    }
}

function cleanResponse(text: string): string {
    let clean = text.trim()

    // Remove markdown code blocks
    clean = clean.replace(/```(json|text)?/g, '').replace(/```/g, '')

    // Try to parse as JSON if it looks like JSON
    if (clean.startsWith('{') && clean.endsWith('}')) {
        try {
            const parsed = JSON.parse(clean)
            // Return first string value found in the object
            const values = Object.values(parsed)
            if (values.length > 0 && typeof values[0] === 'string') {
                return values[0] as string
            }
        } catch {
            // Not valid JSON, continue with raw text
        }
    }

    // Remove surrounding quotes if present
    if (clean.startsWith('"') && clean.endsWith('"')) {
        clean = clean.slice(1, -1)
    }

    return clean.trim()
}

export async function generateStatisticsInsight(data: {
    periodLabel: string
    totalDays: number
    daysWithMeals: number
    totalMeals: number
    avgCalories: number
    avgProtein: number
    avgCarbs: number
    avgFat: number
    targetCalories: number
    consistencyScore: number
    currentStreak: number
    goalDescription?: string
}) {
    const avgPercent = Math.round((data.avgCalories / data.targetCalories) * 100)
    const trackingRate = Math.round((data.daysWithMeals / data.totalDays) * 100)

    const prompt = `
You are a supportive nutritionist AI analyzing a user's eating habits over a time period.
Based on the following statistics, provide 2-3 sentences of insightful feedback and actionable advice.

Period: ${data.periodLabel}
Days in Period: ${data.totalDays}
Days with Logged Meals: ${data.daysWithMeals} (${trackingRate}% tracking rate)
Total Meals: ${data.totalMeals}

Daily Averages:
- Calories: ${data.avgCalories} kcal (${avgPercent}% of ${data.targetCalories} kcal target)
- Protein: ${data.avgProtein}g
- Carbs: ${data.avgCarbs}g
- Fat: ${data.avgFat}g

Consistency Score: ${data.consistencyScore}% (days within ±10% of target)
Current Streak: ${data.currentStreak} days on target
User's Goal: ${data.goalDescription || 'General health and wellness'}

Guidelines:
- Analyze patterns and trends they should be aware of
- Highlight what they're doing well (be specific)
- Give one concrete, actionable suggestion for improvement
- If tracking rate is low, encourage more consistent logging
- Consider macro balance (protein for muscle, not just calories)
- Use an emoji at the start
- Be encouraging and insightful, not preachy

Respond with just the feedback text, no JSON or markdown.
`

    try {
        const result = await model.generateContent(prompt)
        return { insight: cleanResponse(result.response.text()) }
    } catch (e) {
        console.error('Statistics insight error:', e)
        return { insight: '📊 Keep logging your meals consistently to get detailed insights about your eating patterns!' }
    }
}
