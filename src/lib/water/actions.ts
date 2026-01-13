'use server'

import { createClient } from '@/lib/supabase/server'

export async function logWaterIntake(amountMl: number) {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return { error: 'Not authenticated' }

    if (amountMl <= 0) {
        return { error: 'Water amount must be greater than 0' }
    }

    // Get today's date in user's local timezone
    const today = new Date()
    const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate())
    const todayEnd = new Date(todayStart)
    todayEnd.setDate(todayEnd.getDate() + 1)

    const { error: insertError } = await supabase
        .from('water_logs')
        .insert({
            user_id: user.id,
            amount_ml: amountMl,
            logged_at: new Date().toISOString(),
        })

    if (insertError) {
        return { error: insertError.message }
    }

    // Get total water intake for today
    const { data: todayLogs, error: queryError } = await supabase
        .from('water_logs')
        .select('amount_ml')
        .eq('user_id', user.id)
        .gte('logged_at', todayStart.toISOString())
        .lt('logged_at', todayEnd.toISOString())

    if (queryError) {
        return { error: queryError.message }
    }

    const totalIntake = todayLogs.reduce((sum, log) => sum + log.amount_ml, 0)

    // Update profile with daily total
    const { error: updateError } = await supabase
        .from('profiles')
        .update({ daily_water_intake: totalIntake })
        .eq('id', user.id)

    if (updateError) {
        return { error: updateError.message }
    }

    return { success: true, totalIntake }
}

export async function getDailyWaterIntake() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return { error: 'Not authenticated' }

    // Get today's date
    const today = new Date()
    const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate())
    const todayEnd = new Date(todayStart)
    todayEnd.setDate(todayEnd.getDate() + 1)

    const { data: todayLogs, error } = await supabase
        .from('water_logs')
        .select('amount_ml')
        .eq('user_id', user.id)
        .gte('logged_at', todayStart.toISOString())
        .lt('logged_at', todayEnd.toISOString())

    if (error) {
        return { error: error.message }
    }

    const totalIntake = todayLogs.reduce((sum, log) => sum + log.amount_ml, 0)

    return { totalIntake }
}
