'use server'

import { createClient } from '@/lib/supabase/server'
import { createClient as createStatelessClient } from '@supabase/supabase-js'
import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

/**
 * Get user display information
 */
export async function getUserDisplayInfo() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        console.error('SERVER ACTION getUserDisplayInfo: Not authenticated')
        return { error: 'Not authenticated' }
    }

    const { data: profile } = await supabase
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .single()

    return {
        email: user.email,
        displayName: profile?.full_name || user.user_metadata?.full_name || '',
    }
}

/**
 * Update user display name
 */
export async function updateDisplayName(displayName: string) {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        console.error('SERVER ACTION updateDisplayName: Not authenticated')
        return { error: 'Not authenticated' }
    }

    // Validate display name
    if (displayName.length > 100) {
        return { error: 'Display name must be less than 100 characters' }
    }

    const { error } = await supabase
        .from('profiles')
        .upsert({
            id: user.id,
            full_name: displayName.trim(),
            updated_at: new Date().toISOString(),
        })

    if (error) {
        console.error('SERVER ACTION updateDisplayName: DB Error', error)
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

    if (!user) {
        console.error('SERVER ACTION updateUserEmail: Not authenticated')
        return { error: 'Not authenticated' }
    }

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
    }, {
        emailRedirectTo: `${process.env.NEXT_PUBLIC_SITE_URL || ''}/settings`,
    })

    if (error) {
        console.error('SERVER ACTION updateUserEmail: Auth Update Error', error)
        return { error: error.message }
    }
    console.log('SERVER ACTION updateUserEmail: Success for', newEmail)

    return { success: true }
}

/**
 * Send password reset link (stateless, cross-device compatible)
 */
export async function sendPasswordResetLink(email: string) {
    const supabase = createStatelessClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    )

    const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/callback?next=/settings`,
    })

    if (error) {
        console.error('SERVER ACTION sendPasswordResetLink: Error', error)
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

    if (!user) {
        console.error('SERVER ACTION deleteAccount: Not authenticated')
        return { error: 'Not authenticated' }
    }

    try {
        // Delete user's meal logs
        const { error: mealLogsError } = await supabase
            .from('meals')
            .delete()
            .eq('user_id', user.id)

        if (mealLogsError) {
            console.error('SERVER ACTION: Error deleting meal logs:', mealLogsError)
            return { error: 'Failed to delete meal logs: ' + mealLogsError.message }
        }
        console.log('SERVER ACTION: Meal logs deleted successfully')

        // Delete user's profile
        const { error: profileError } = await supabase
            .from('profiles')
            .delete()
            .eq('id', user.id)

        if (profileError) {
            console.error('SERVER ACTION: Error deleting profile:', profileError)
            return { error: 'Failed to delete profile: ' + profileError.message }
        }
        console.log('SERVER ACTION: Profile deleted successfully')

        // Sign out the user first
        await supabase.auth.signOut()

        // Note: To fully delete the auth user, we need to use the admin API
        // This requires a server-side API route with service role key
        // For now, we'll call the delete API route
        const apiUrl = `${process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000'}/api/account/delete`
        console.log('SERVER ACTION deleteAccount: Calling API', apiUrl)

        const response = await fetch(apiUrl, {
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
