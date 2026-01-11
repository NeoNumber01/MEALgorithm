'use client'

import { useEffect, useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Suspense } from 'react'

function ConfirmContent() {
    const router = useRouter()
    const searchParams = useSearchParams()
    const [status, setStatus] = useState<'processing' | 'success' | 'error'>('processing')
    const [errorMessage, setErrorMessage] = useState<string | null>(null)
    const supabase = createClient()

    useEffect(() => {
        const handleAuth = async () => {
            const next = searchParams.get('next') || '/dashboard'

            // Check for hash fragments (used by email auth flows)
            const hash = window.location.hash
            if (hash) {
                // Parse hash fragment
                const params = new URLSearchParams(hash.substring(1))
                const accessToken = params.get('access_token')
                const refreshToken = params.get('refresh_token')
                const errorDescription = params.get('error_description')

                if (errorDescription) {
                    setStatus('error')
                    setErrorMessage(decodeURIComponent(errorDescription))
                    return
                }

                if (accessToken && refreshToken) {
                    const { error } = await supabase.auth.setSession({
                        access_token: accessToken,
                        refresh_token: refreshToken,
                    })

                    if (error) {
                        setStatus('error')
                        setErrorMessage(error.message)
                        return
                    }

                    setStatus('success')
                    router.push(next)
                    router.refresh()
                    return
                }
            }

            // If no hash, check if already authenticated
            const { data: { user } } = await supabase.auth.getUser()
            if (user) {
                setStatus('success')
                router.push(next)
                router.refresh()
                return
            }

            // No auth info found
            setStatus('error')
            setErrorMessage('No authentication information found. Please try again.')
        }

        handleAuth()
    }, [router, searchParams, supabase.auth])

    if (status === 'processing') {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50">
                <div className="text-center">
                    <div className="w-16 h-16 border-4 border-blue-600 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
                    <p className="text-gray-600">Verifying your identity...</p>
                </div>
            </div>
        )
    }

    if (status === 'error') {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
                <div className="max-w-md w-full bg-white rounded-xl shadow-lg p-8 text-center">
                    <div className="w-16 h-16 bg-red-100 text-red-600 rounded-full flex items-center justify-center mx-auto mb-4">
                        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                        </svg>
                    </div>
                    <h2 className="text-2xl font-bold text-gray-900 mb-2">Authentication Error</h2>
                    {errorMessage && (
                        <p className="text-red-600 mb-6">{errorMessage}</p>
                    )}
                    <button
                        onClick={() => router.push('/login')}
                        className="w-full py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition"
                    >
                        Back to Login
                    </button>
                </div>
            </div>
        )
    }

    return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
            <div className="text-center">
                <p className="text-gray-600">Redirecting...</p>
            </div>
        </div>
    )
}

export default function AuthConfirmPage() {
    return (
        <Suspense fallback={
            <div className="min-h-screen flex items-center justify-center bg-gray-50">
                <div className="w-16 h-16 border-4 border-blue-600 border-t-transparent rounded-full animate-spin"></div>
            </div>
        }>
            <ConfirmContent />
        </Suspense>
    )
}
