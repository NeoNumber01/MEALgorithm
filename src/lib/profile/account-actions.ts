'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

/**
 * Get user display information
 */
export async function getUserDisplayInfo() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return { error: 'Not authenticated' }

    const { data: profile } = await supabase
        .from('profiles')
        .select('display_name')
        .eq('id', user.id)
        .single()

    return {
        email: user.email,
        displayName: profile?.display_name || user.user_metadata?.full_name || '',
    }
}

/**
 * Update user display name
 */
export async function updateDisplayName(displayName: string) {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return { error: 'Not authenticated' }

    // Validate display name
    if (displayName.length > 100) {
        return { error: 'Display name must be less than 100 characters' }
    }

    const { error } = await supabase
        .from('profiles')
        .upsert({
            id: user.id,
            display_name: displayName.trim(),
            updated_at: new Date().toISOString(),
        })

    if (error) {
        return { error: error.message }
    }

    revalidatePath('/settings')
    revalidatePath('/dashboard')
    return { success: true }
}

/**
 * Update user email - sends verification email to new address
 */
export async function updateUserEmail(newEmail: string) {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return { error: 'Not authenticated' }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(newEmail)) {
        return { error: 'Invalid email format' }
    }

    if (newEmail === user.email) {
        return { error: 'New email is the same as current email' }
    }

    const { error } = await supabase.auth.updateUser({
        email: newEmail,
    })

    if (error) {
        return { error: error.message }
    }

    return { success: true }
}

/**
 * Delete user account and all associated data
 */
export async function deleteAccount() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return { error: 'Not authenticated' }

    try {
        // Delete user's meal logs
        const { error: mealLogsError } = await supabase
            .from('meal_logs')
            .delete()
            .eq('user_id', user.id)

        if (mealLogsError) {
            console.error('Error deleting meal logs:', mealLogsError)
            // Continue anyway - we'll try to delete the profile and user
        }

        // Delete user's profile
        const { error: profileError } = await supabase
            .from('profiles')
            .delete()
            .eq('id', user.id)

        if (profileError) {
            console.error('Error deleting profile:', profileError)
            // Continue anyway
        }

        // Sign out the user first
        await supabase.auth.signOut()

        // Note: To fully delete the auth user, we need to use the admin API
        // This requires a server-side API route with service role key
        // For now, we'll call the delete API route
        const response = await fetch(`${process.env.NEXT_PUBLIC_SITE_URL || ''}/api/account/delete`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ userId: user.id }),
        })

        if (!response.ok) {
            const data = await response.json()
            return { error: data.error || 'Failed to delete account' }
        }

        return { success: true }
    } catch (error) {
        console.error('Error deleting account:', error)
        return { error: 'An unexpected error occurred while deleting account' }
    }
}
