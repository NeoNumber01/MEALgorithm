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
