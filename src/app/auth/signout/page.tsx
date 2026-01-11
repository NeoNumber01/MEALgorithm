'use client'

import { useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

export default function SignOutPage() {
    const router = useRouter()
    const supabase = createClient()

    useEffect(() => {
        const handleSignOut = async () => {
            // Clear all local storage (dashboard cache, user data, etc.)
            localStorage.clear()

            // Sign out from Supabase
            await supabase.auth.signOut()

            // Redirect to login
            router.push('/login')
            router.refresh()
        }

        handleSignOut()
    }, [router, supabase.auth])

    return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
            <div className="text-center">
                <div className="w-16 h-16 border-4 border-blue-600 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
                <p className="text-gray-600">Signing out...</p>
            </div>
        </div>
    )
}
