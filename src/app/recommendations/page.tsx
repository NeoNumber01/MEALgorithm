import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import RecommendationsContent from '@/components/recommendations/RecommendationsContent'

export default async function RecommendationsPage() {
    const supabase = createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        redirect('/login')
    }

    return (
        <main className="min-h-screen bg-gray-50">
            <div className="max-w-4xl mx-auto px-4 py-8">
                <div className="flex justify-between items-center mb-8">
                    <div>
                        <h1 className="text-3xl font-bold text-gray-900">Meal Suggestions</h1>
                        <p className="text-gray-600">AI-powered recommendations based on your goals</p>
                    </div>
                    <a
                        href="/dashboard"
                        className="text-blue-600 hover:underline"
                    >
                        ← Back to Dashboard
                    </a>
                </div>

                <RecommendationsContent />
            </div>
        </main>
    )
}
