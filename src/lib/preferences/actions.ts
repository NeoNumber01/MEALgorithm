'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export async function getPreferences() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return { error: 'Not authenticated' }

    const { data: profile } = await supabase
        .from('profiles')
        .select('food_preferences, food_dislikes, dietary_restrictions, custom_notes')
        .eq('id', user.id)
        .single()

    return {
        preferences: profile?.food_preferences || '',
        dislikes: profile?.food_dislikes || '',
        restrictions: profile?.dietary_restrictions || '',
        customNotes: profile?.custom_notes || '',
    }
}

export async function updatePreferences(data: {
    food_preferences?: string
    food_dislikes?: string
    dietary_restrictions?: string
    custom_notes?: string
}) {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return { error: 'Not authenticated' }

    const { error } = await supabase
        .from('profiles')
        .update({
            food_preferences: data.food_preferences,
            food_dislikes: data.food_dislikes,
            dietary_restrictions: data.dietary_restrictions,
            custom_notes: data.custom_notes,
            profile_updated_at: new Date().toISOString(),
        })
        .eq('id', user.id)

    if (error) {
        return { error: error.message }
    }

    revalidatePath('/recommendations')
    return { success: true }
}
