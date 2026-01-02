'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export async function saveMeal(data: {
    textContent?: string
    imagePath?: string
    analysis: unknown
    mealType?: 'breakfast' | 'lunch' | 'dinner' | 'snack'
}) {
    const supabase = createClient()

    const { data: { user }, error: authError } = await supabase.auth.getUser()

    if (authError || !user) {
        return { error: 'Not authenticated' }
    }

    const { error } = await supabase.from('meals').insert({
        user_id: user.id,
        text_content: data.textContent || null,
        image_path: data.imagePath || null,
        analysis: data.analysis,
        meal_type: data.mealType || null,
    })

    if (error) {
        console.error('Error saving meal:', error)
        return { error: error.message }
    }

    revalidatePath('/dashboard')
    return { success: true }
}

export async function uploadMealImage(formData: FormData) {
    const supabase = createClient()

    const { data: { user }, error: authError } = await supabase.auth.getUser()

    if (authError || !user) {
        return { error: 'Not authenticated' }
    }

    const file = formData.get('image') as File
    if (!file) {
        return { error: 'No file provided' }
    }

    const fileExt = file.name.split('.').pop()
    const fileName = `${user.id}/${Date.now()}.${fileExt}`

    const { error: uploadError } = await supabase.storage
        .from('meal_images')
        .upload(fileName, file)

    if (uploadError) {
        console.error('Upload error:', uploadError)
        return { error: uploadError.message }
    }

    const { data: urlData } = supabase.storage
        .from('meal_images')
        .getPublicUrl(fileName)

    return { path: fileName, url: urlData.publicUrl }
}
