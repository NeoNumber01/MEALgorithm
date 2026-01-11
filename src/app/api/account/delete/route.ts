import { createClient } from '@supabase/supabase-js'
import { NextRequest, NextResponse } from 'next/server'

// This route uses the service role key to delete auth users
// It should only be called from server-side code with proper authentication

export async function POST(request: NextRequest) {
    try {
        const { userId } = await request.json()

        if (!userId) {
            return NextResponse.json(
                { error: 'User ID is required' },
                { status: 400 }
            )
        }

        // Verify environment variables
        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
        const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

        if (!supabaseUrl || !supabaseServiceKey) {
            console.error('Missing Supabase environment variables')
            return NextResponse.json(
                { error: 'Server configuration error' },
                { status: 500 }
            )
        }

        // Create admin client with service role key
        const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
            auth: {
                autoRefreshToken: false,
                persistSession: false,
            },
        })

        // Delete the auth user using admin API
        const { error } = await supabaseAdmin.auth.admin.deleteUser(userId)

        if (error) {
            console.error('Error deleting user FULL OBJECT:', JSON.stringify(error, null, 2))
            return NextResponse.json(
                { error: error.message, details: error },
                { status: 500 }
            )
        }

        // Verify deletion by trying to get the user again
        const { data: { user: checkUser }, error: checkError } = await supabaseAdmin.auth.admin.getUserById(userId)

        if (checkUser) {
            console.error('CRITICAL: Delete reported success but user still exists!', checkUser)
            return NextResponse.json(
                { error: 'Zombie Account: Server reported deletion but user still exists. Please contact support.' },
                { status: 500 }
            )
        }

        console.log('SUCCESS: User verified as deleted')
        return NextResponse.json({ success: true })
    } catch (error) {
        console.error('API /api/account/delete: Unexpected error', error)
        return NextResponse.json(
            { error: 'An unexpected error occurred' },
            { status: 500 }
        )
    }
}
