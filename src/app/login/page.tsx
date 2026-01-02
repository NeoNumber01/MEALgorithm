import LoginButton from '@/components/auth/LoginButton'

export default function LoginPage() {
    return (
        <main className="min-h-screen relative flex items-center justify-center">
            {/* Global Background */}
            <div
                className="fixed inset-0 z-0 pointer-events-none"
                style={{
                    backgroundImage: "url('/images/dashboard-fresh-elegant-v2.png')",
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                    backgroundRepeat: 'no-repeat',
                    opacity: 0.8
                }}
            />

            <div className="relative z-10 p-8 bg-white/70 backdrop-blur-xl shadow-2xl border border-white/40 rounded-3xl text-center w-full max-w-sm">
                <div className="text-4xl mb-4">🫐</div>
                <h1 className="text-3xl font-bold mb-2 text-gray-900">MEALgorithm</h1>
                <p className="text-gray-600 mb-8">Sign in to track your nutrition</p>
                <div className="flex flex-col gap-4">
                    <LoginButton provider="google" />
                    <LoginButton provider="github" />
                </div>
            </div>
        </main>
    )
}
