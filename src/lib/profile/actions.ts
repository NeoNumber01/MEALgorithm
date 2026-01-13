'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import { calculateTDEE, calculateMacroTargets, Gender, ActivityLevel } from '@/lib/nutrition/calculator'

export async function getProfile() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return { error: 'Not authenticated' }

    const { data: profile, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single()

    if (error && error.code !== 'PGRST116') {
        return { error: error.message }
    }

    return { profile }
}

export async function updateProfile(data: {
    height_cm?: number
    weight_kg?: number
    age?: number
    gender?: Gender
    activity_level?: ActivityLevel
    goal?: 'maintenance' | 'weight-loss' | 'muscle-gain'
    calorie_target?: number
    protein_target?: number
    carbs_target?: number
    fat_target?: number
}) {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return { error: 'Not authenticated' }

    // Validate physical stats with reasonable ranges
    const validationErrors: string[] = []

    if (data.height_cm !== undefined) {
        if (data.height_cm < 50 || data.height_cm > 250) {
            validationErrors.push('Height must be between 50 and 250 cm')
        }
    }

    if (data.weight_kg !== undefined) {
        if (data.weight_kg < 10 || data.weight_kg > 500) {
            validationErrors.push('Weight must be between 10 and 500 kg')
        }
    }

    if (data.age !== undefined) {
        if (data.age < 1 || data.age > 120) {
            validationErrors.push('Age must be between 1 and 120 years')
        }
    }

    if (data.calorie_target !== undefined) {
        if (data.calorie_target < 500 || data.calorie_target > 10000) {
            validationErrors.push('Calorie target must be between 500 and 10,000 kcal')
        }
    }

    if (data.protein_target !== undefined) {
        if (data.protein_target < 0 || data.protein_target > 500) {
            validationErrors.push('Protein target must be between 0 and 500g')
        }
    }

    if (data.carbs_target !== undefined) {
        if (data.carbs_target < 0 || data.carbs_target > 1000) {
            validationErrors.push('Carbs target must be between 0 and 1,000g')
        }
    }

    if (data.fat_target !== undefined) {
        if (data.fat_target < 0 || data.fat_target > 500) {
            validationErrors.push('Fat target must be between 0 and 500g')
        }
    }

    if (validationErrors.length > 0) {
        return { error: validationErrors.join('. ') }
    }

    // Calculate targets if physical stats are provided
    let calorieTarget = data.calorie_target
    let proteinTarget = data.protein_target
    let carbsTarget = data.carbs_target
    let fatTarget = data.fat_target

    if (data.height_cm && data.weight_kg && data.age && data.gender) {
        calorieTarget = calculateTDEE(
            data.weight_kg,
            data.height_cm,
            data.age,
            data.gender,
            data.activity_level || 'moderate'
        )

        const macros = calculateMacroTargets(calorieTarget)
        proteinTarget = proteinTarget || macros.protein
        carbsTarget = carbsTarget || macros.carbs
        fatTarget = fatTarget || macros.fat
    }

    const { error } = await supabase
        .from('profiles')
        .upsert({
            id: user.id,
            ...data,
            calorie_target: calorieTarget,
            protein_target: proteinTarget,
            carbs_target: carbsTarget,
            fat_target: fatTarget,
            updated_at: new Date().toISOString(),
            profile_updated_at: new Date().toISOString(), // Invalidates suggestions cache
        })

    if (error) {
        return { error: error.message }
    }

    revalidatePath('/dashboard')
    revalidatePath('/settings')
    return { success: true }
}

export async function getCachedFeedback() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return { error: 'Not authenticated' }

    const { data: profile } = await supabase
        .from('profiles')
        .select('cached_feedback, feedback_updated_at, last_meal_at')
        .eq('id', user.id)
        .single()

    return {
        feedback: profile?.cached_feedback,
        updatedAt: profile?.feedback_updated_at,
        lastMealAt: profile?.last_meal_at,
    }
}

export async function updateCachedFeedback(feedback: string) {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return { error: 'Not authenticated' }

    await supabase
        .from('profiles')
        .update({
            cached_feedback: feedback,
            feedback_updated_at: new Date().toISOString(),
        })
        .eq('id', user.id)

    return { success: true }
}

export async function updateLastMealTime() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return

    await supabase
        .from('profiles')
        .update({
            last_meal_at: new Date().toISOString(),
        })
        .eq('id', user.id)
}
