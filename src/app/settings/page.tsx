import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProfileSettings from '@/components/profile/ProfileSettings'
import AccountSection from '@/components/profile/AccountSection'

export default async function SettingsPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        redirect('/login')
    }

    return (
        <main className="min-h-screen relative">
            {/* Global Background */}
            <div
                className="fixed inset-0 z-0 pointer-events-none"
                style={{
                    backgroundImage: "url('/images/settings-bg-sparse.png')",
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                    backgroundRepeat: 'no-repeat',
                    opacity: 0.95
                }}
            />

            <div className="relative max-w-3xl mx-auto px-4 py-8">
                {/* Header */}
                <div className="text-center mb-8">
                    <div className="inline-flex items-center gap-2 bg-purple-100 text-purple-700 px-4 py-2 rounded-full text-sm font-medium mb-4">
                        <span className="text-lg">⚙️</span> Profile Configuration
                    </div>
                    <h1 className="text-4xl font-extrabold text-gray-900 mb-3">
                        Settings
                    </h1>
                    <p className="text-lg text-gray-600">
                        Configure your profile, set nutritional targets, and personalize your experience
                    </p>
                </div>

                <ProfileSettings />

                {/* Account Section - Client Component */}
                <AccountSection userEmail={user.email || ''} />
            </div>

            {/* Falling Helicopter Left Top */}
            <div className="hidden 2xl:block fixed top-24 left-10 z-10 pointer-events-none animate-helicopter">
                <img
                    src="/images/FallingHelicopter.png"
                    alt="Helicopter"
                    className="w-[300px] h-auto drop-shadow-xl opacity-90 transition-all duration-300"
                />
            </div>

            {/* Kobe Floating Image */}
            <div className="hidden 2xl:block fixed bottom-0 right-12 z-10 pointer-events-none">
                <img
                    src="/images/kobe.png"
                    alt="Kobe"
                    className="w-[500px] h-auto drop-shadow-2xl opacity-90 hover:opacity-100 transition-all duration-500"
                    style={{
                        filter: 'drop-shadow(0 20px 30px rgba(0,0,0,0.3))'
                    }}
                />
            </div>
        </main>
    )
}
