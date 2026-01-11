'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { sendPasswordResetLink } from '@/lib/profile/account-actions'
import { useRouter } from 'next/navigation'

type AuthMode = 'login' | 'register' | 'forgot'

export default function EmailAuthForm() {
    const [mode, setMode] = useState<AuthMode>('login')
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [confirmPassword, setConfirmPassword] = useState('')
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [message, setMessage] = useState<string | null>(null)

    const supabase = createClient()
    const router = useRouter()

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        e.preventDefault()
        console.log('CLIENT: Form submitted', { mode, email })
        setError(null)
        setMessage(null)
        setLoading(true)

        try {
            if (mode === 'register') {
                // Validate passwords match
                if (password !== confirmPassword) {
                    setError('Passwords do not match')
                    setLoading(false)
                    return
                }

                // Validate password strength
                if (password.length < 6) {
                    setError('Password must be at least 6 characters')
                    setLoading(false)
                    return
                }

                const { error } = await supabase.auth.signUp({
                    email,
                    password,
                    options: {
                        emailRedirectTo: `${process.env.NEXT_PUBLIC_SITE_URL || window.location.origin}/auth/callback`,
                    },
                })

                if (error) {
                    setError(error.message)
                } else {
                    setMessage('Check your email for a confirmation link!')
                    setMode('login')
                }
            } else if (mode === 'login') {
                const { error } = await supabase.auth.signInWithPassword({
                    email,
                    password,
                })

                if (error) {
                    console.error('CLIENT: SignIn Error', error)
                    setError(error.message)
                } else {
                    router.push('/dashboard')
                    router.refresh()
                }
            } else if (mode === 'forgot') {
                const { error } = await supabase.auth.resetPasswordForEmail(email, {
                    redirectTo: `${process.env.NEXT_PUBLIC_SITE_URL || location.origin}/auth/callback?next=/settings`,
                })

                if (error) {
                    console.error('CLIENT: Reset Password Error', error)
                    setError(error.message)
                } else {
                    setMessage('Check your email for a password reset link!')
                }
            }
        } catch (err) {
            console.error('CLIENT: Unexpected Error', err)
            setError('An unexpected error occurred')
            console.error(err)
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="w-full">
            <form onSubmit={handleSubmit} className="space-y-4">
                {/* Error/Success Messages */}
                {error && (
                    <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl text-sm">
                        {error}
                    </div>
                )}
                {message && (
                    <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-xl text-sm">
                        {message}
                    </div>
                )}

                {/* Email Input */}
                <div>
                    <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
                        Email
                    </label>
                    <input
                        id="email"
                        type="email"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        placeholder="you@example.com"
                        required
                        className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition bg-white/80"
                    />
                </div>

                {/* Password Input (not shown for forgot mode) */}
                {mode !== 'forgot' && (
                    <div>
                        <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
                            Password
                        </label>
                        <input
                            id="password"
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            placeholder="••••••••"
                            required
                            minLength={6}
                            className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition bg-white/80"
                        />
                    </div>
                )}

                {/* Confirm Password (only for register mode) */}
                {mode === 'register' && (
                    <div>
                        <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 mb-1">
                            Confirm Password
                        </label>
                        <input
                            id="confirmPassword"
                            type="password"
                            value={confirmPassword}
                            onChange={(e) => setConfirmPassword(e.target.value)}
                            placeholder="••••••••"
                            required
                            minLength={6}
                            className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition bg-white/80"
                        />
                    </div>
                )}

                {/* Forgot Password Link (only in login mode) */}
                {mode === 'login' && (
                    <div className="text-right">
                        <button
                            type="button"
                            onClick={() => {
                                setMode('forgot')
                                setError(null)
                                setMessage(null)
                            }}
                            className="text-sm text-blue-600 hover:text-blue-800 hover:underline"
                        >
                            Forgot password?
                        </button>
                    </div>
                )}

                {/* Submit Button */}
                <button
                    type="submit"
                    disabled={loading}
                    className="w-full py-3 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-xl font-medium 
                        hover:from-blue-700 hover:to-purple-700 transition-all disabled:opacity-50 disabled:cursor-not-allowed
                        shadow-lg hover:shadow-xl"
                >
                    {loading ? (
                        <span className="flex items-center justify-center gap-2">
                            <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                            </svg>
                            Processing...
                        </span>
                    ) : mode === 'login' ? (
                        'Sign In'
                    ) : mode === 'register' ? (
                        'Create Account'
                    ) : (
                        'Send Reset Link'
                    )}
                </button>
            </form>

            {/* Mode Toggle */}
            <div className="mt-6 text-center text-sm">
                {mode === 'login' ? (
                    <p className="text-gray-600">
                        Don&apos;t have an account?{' '}
                        <button
                            onClick={() => {
                                setMode('register')
                                setError(null)
                                setMessage(null)
                            }}
                            className="text-blue-600 hover:text-blue-800 font-medium hover:underline"
                        >
                            Sign up
                        </button>
                    </p>
                ) : (
                    <p className="text-gray-600">
                        Already have an account?{' '}
                        <button
                            onClick={() => {
                                setMode('login')
                                setError(null)
                                setMessage(null)
                            }}
                            className="text-blue-600 hover:text-blue-800 font-medium hover:underline"
                        >
                            Sign in
                        </button>
                    </p>
                )}
            </div>
        </div>
    )
}
