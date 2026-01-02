'use client'

import { createClient } from '@/lib/supabase/client'

export default function LoginButton(props: { provider: 'google' | 'github', next?: string }) {
    const supabase = createClient()

    const handleLogin = async () => {
        const { error } = await supabase.auth.signInWithOAuth({
            provider: props.provider,
            options: {
                redirectTo: `${location.origin}/auth/callback?next=${props.next || '/'}`,
            },
        })
        if (error) {
            console.error('Login error:', error)
        }
    }

    return (
        <button
            onClick={handleLogin}
            className="px-4 py-2 bg-black text-white rounded hover:bg-gray-800 transition capitalize"
        >
            Login with {props.provider}
        </button>
    )
}
