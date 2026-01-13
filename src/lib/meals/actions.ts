'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export async function saveMeal(data: {
    textContent?: string
    analysis: unknown
    mealType?: 'breakfast' | 'lunch' | 'dinner' | 'snack'
    createdAt?: string
}) {
    const supabase = await createClient()

    const { data: { user }, error: authError } = await supabase.auth.getUser()

    if (authError || !user) {
        return { error: 'Not authenticated' }
    }

    const { error } = await supabase.from('meals').insert({
        user_id: user.id,
        text_content: data.textContent || null,
        analysis: data.analysis,
        meal_type: data.mealType || null,
        created_at: data.createdAt || new Date().toISOString(),
    })

    if (error) {
        console.error('Error saving meal:', error)
        return { error: error.message }
    }

    // Update last_meal_at to invalidate cached feedback
    await supabase
        .from('profiles')
        .update({ last_meal_at: new Date().toISOString() })
        .eq('id', user.id)

    revalidatePath('/dashboard')
    return { success: true }
}

export async function deleteMeal(mealId: string) {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        return { error: 'Not authenticated' }
    }

    const { error } = await supabase
        .from('meals')
        .delete()
        .eq('id', mealId)
        .eq('user_id', user.id)

    if (error) {
        console.error('Error deleting meal:', error)
        return { error: error.message }
    }

    revalidatePath('/dashboard')
    return { success: true }
}

export async function updateMealType(
    mealId: string,
    mealType: 'breakfast' | 'lunch' | 'dinner' | 'snack'
) {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        return { error: 'Not authenticated' }
    }

    const { error } = await supabase
        .from('meals')
        .update({ meal_type: mealType })
        .eq('id', mealId)
        .eq('user_id', user.id)

    if (error) {
        console.error('Error updating meal type:', error)
        return { error: error.message }
    }

    revalidatePath('/dashboard')
    return { success: true }
}

export async function updateMealDateTime(
    mealId: string,
    newDateTime: string // ISO string
) {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        return { error: 'Not authenticated' }
    }

    const { error } = await supabase
        .from('meals')
        .update({ created_at: newDateTime })
        .eq('id', mealId)
        .eq('user_id', user.id)

    if (error) {
        console.error('Error updating meal date/time:', error)
        return { error: error.message }
    }

    revalidatePath('/dashboard')
    return { success: true }
}

// Return the most frequently logged meals for the current user
export async function getFrequentMeals(limit = 5) {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        return { error: 'Not authenticated' }
    }

    // Fetch recent meals (bounded) and compute frequencies in memory
    const { data, error } = await supabase
        .from('meals')
        .select('text_content, meal_type')
        .eq('user_id', user.id)
        .not('text_content', 'is', null)
        .order('created_at', { ascending: false })
        .limit(200) // safety cap

    if (error) {
        console.error('Error fetching frequent meals:', error)
        return { error: error.message }
    }

    const freqMap = new Map<string, { textContent: string; mealType: string | null; count: number }>()
    for (const row of data || []) {
        const key = `${row.text_content}::${row.meal_type || 'any'}`
        if (!freqMap.has(key)) {
            freqMap.set(key, { textContent: row.text_content as string, mealType: row.meal_type, count: 0 })
        }
        const entry = freqMap.get(key)!
        entry.count += 1
    }

    const meals = Array.from(freqMap.values())
        .sort((a, b) => b.count - a.count)
        .slice(0, limit)
        .map((m) => ({
            textContent: m.textContent,
            mealType: m.mealType as 'breakfast' | 'lunch' | 'dinner' | 'snack' | null,
            count: m.count,
        }))

    return { meals }
}
