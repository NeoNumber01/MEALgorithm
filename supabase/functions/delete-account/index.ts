import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get user from JWT token
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header provided')
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')

    if (!supabaseUrl || !serviceRoleKey || !anonKey) {
      throw new Error('Missing Supabase environment variables')
    }

    // Create client with user's JWT to verify identity
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } }
    })

    // Get the authenticated user
    const { data: { user }, error: userError } = await userClient.auth.getUser()
    if (userError || !user) {
      console.error('User verification failed:', userError)
      throw new Error('Invalid or expired user token')
    }

    console.log(`🗑️ Deleting user: ${user.id} (${user.email})`)

    // Create admin client with service role key for deletion
    const adminClient = createClient(supabaseUrl, serviceRoleKey)
    
    // ============================================================
    // STEP 1: Explicitly delete user data from all tables
    // This ensures data is cleaned up even if cascade fails
    // ============================================================
    
    // 1a. Delete user's meal images from storage
    try {
      const { data: files } = await adminClient.storage
        .from('meal_images')
        .list(user.id)
      
      if (files && files.length > 0) {
        const filePaths = files.map(f => `${user.id}/${f.name}`)
        await adminClient.storage
          .from('meal_images')
          .remove(filePaths)
        console.log(`📦 Deleted ${filePaths.length} images from storage`)
      }
    } catch (storageError) {
      console.warn('Storage cleanup warning:', storageError)
      // Continue even if storage cleanup fails
    }
    
    // 1b. Delete all meals for this user
    const { error: mealsError, count: mealsCount } = await adminClient
      .from('meals')
      .delete()
      .eq('user_id', user.id)
    
    if (mealsError) {
      console.error('Failed to delete meals:', mealsError)
      throw new Error(`Failed to delete user meals: ${mealsError.message}`)
    }
    console.log(`🍽️ Deleted meals for user (count query may not reflect actual)`)
    
    // 1c. Delete user's profile
    const { error: profileError } = await adminClient
      .from('profiles')
      .delete()
      .eq('id', user.id)
    
    if (profileError) {
      console.error('Failed to delete profile:', profileError)
      throw new Error(`Failed to delete user profile: ${profileError.message}`)
    }
    console.log(`👤 Deleted profile for user`)
    
    // ============================================================
    // STEP 2: Delete the user from auth.users
    // ============================================================
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id)
    
    if (deleteError) {
      console.error('Delete user failed:', deleteError)
      throw new Error(`Failed to delete user: ${deleteError.message}`)
    }

    console.log(`✅ User ${user.id} and all related data deleted successfully`)

    return new Response(
      JSON.stringify({ success: true, message: 'Account and all data deleted successfully' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('Error in delete-account function:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message || 'An unexpected error occurred' 
      }),
      {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

