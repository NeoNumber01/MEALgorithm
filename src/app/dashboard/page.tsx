import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import DashboardContent from '@/components/dashboard/DashboardContent'
import Link from 'next/link'

export default async function DashboardPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        redirect('/login')
    }

    return (
        <main className="min-h-screen relative overflow-hidden bg-gradient-to-br from-gray-50 via-white to-blue-50">
            <div
                className="fixed inset-0 opacity-50 pointer-events-none"
                style={{ backgroundImage: "url('/images/dashboard-classic-diagonal.png')", backgroundSize: 'cover', backgroundPosition: 'center', backgroundRepeat: 'no-repeat' }}
            />

            <div className="relative max-w-5xl mx-auto px-4 py-8">
                {/* Quick Action Bar */}
                <div className="flex flex-wrap justify-center gap-3 mb-8">
                    <Link
                        href="/log"
                        className="inline-flex items-center gap-2 bg-gradient-to-r from-orange-500 to-red-500 text-white px-5 py-2.5 rounded-xl font-medium hover:shadow-lg hover:shadow-orange-500/25 transition-all hover:-translate-y-0.5"
                    >
                        📝 Log Meal
                    </Link>
                    <Link
                        href="/recommendations"
                        className="inline-flex items-center gap-2 bg-gradient-to-r from-green-500 to-teal-500 text-white px-5 py-2.5 rounded-xl font-medium hover:shadow-lg hover:shadow-green-500/25 transition-all hover:-translate-y-0.5"
                    >
                        💡 Get Ideas
                    </Link>
                    <Link
                        href="/settings"
                        className="inline-flex items-center gap-2 bg-white border-2 border-gray-200 text-gray-700 px-5 py-2.5 rounded-xl font-medium hover:border-purple-300 transition-all"
                    >
                        ⚙️ Settings
                    </Link>
                </div>

                <DashboardContent />
            </div>
        </main>
    )
}
