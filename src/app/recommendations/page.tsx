import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import RecommendationsContent from '@/components/recommendations/RecommendationsContent'

export default async function RecommendationsPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        redirect('/login')
    }

    return (
        <main className="min-h-screen relative overflow-hidden bg-gradient-to-br from-gray-50 via-white to-green-50">
            {/* Background Watermark */}
            <div
                className="fixed inset-0 z-0 opacity-50 pointer-events-none"
                style={{ backgroundImage: "url('/images/recommendations-classic-diagonal.png')", backgroundSize: 'cover', backgroundPosition: 'center', backgroundRepeat: 'no-repeat' }}
            />

            <div className="relative max-w-5xl mx-auto px-4 py-8">
                {/* Header */}
                <div className="text-center mb-8">
                    <div className="inline-flex items-center gap-2 bg-gradient-to-r from-green-100 to-teal-100 text-green-700 px-4 py-2 rounded-full text-sm font-medium mb-4">
                        <span className="text-lg">💡</span> Powered by Gemini AI
                    </div>
                    <h1 className="text-4xl font-extrabold text-gray-900 mb-3">
                        Meal Suggestions
                    </h1>
                    <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                        Personalized recommendations based on your goals, preferences, and eating history
                    </p>
                </div>

                <RecommendationsContent />
            </div>
        </main>
    )
}
