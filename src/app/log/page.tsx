import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import MealLogForm from '@/components/meals/MealLogForm'
import MealCalendar from '@/components/meals/MealCalendar'

export default async function LogMealPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        redirect('/login')
    }

    return (
        <main className="min-h-screen relative overflow-hidden bg-gradient-to-br from-gray-50 via-white to-orange-50">
            {/* Background Composition */}
            <div
                className="fixed inset-0 z-0 pointer-events-none"
                style={{
                    backgroundImage: "url('/images/log-meal-bg-fresh.png')",
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                    backgroundRepeat: 'no-repeat',
                    opacity: 0.8
                }}
            />

            <div className="relative max-w-6xl mx-auto px-4 py-8">
                {/* Header */}
                <div className="mb-8 text-center">
                    <div className="inline-flex items-center gap-2 bg-orange-100 text-orange-700 px-4 py-2 rounded-full text-sm font-medium mb-4">
                        <span className="text-lg">📸</span> AI-Powered Analysis
                    </div>
                    <h1 className="text-4xl font-extrabold text-gray-900 mb-3">
                        Log Your Meal
                    </h1>
                    <p className="text-lg text-gray-600 max-w-xl mx-auto">
                        Snap a photo or describe what you ate. Our AI will instantly analyze
                        the nutritional content and track it for you.
                    </p>
                </div>

                {/* Form Card */}
                <div className="bg-white/15 backdrop-blur-2xl rounded-2xl shadow-xl border border-white/20 p-8 transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20">
                    <MealLogForm />
                </div>

                {/* Two Column Layout */}
                <div className="mt-8 grid lg:grid-cols-3 gap-6">
                    {/* Left: Tips Section */}
                    <div className="lg:col-span-1 space-y-4">
                        <div className="bg-white/15 backdrop-blur-xl rounded-xl p-4 border border-white/20 transition-all duration-300 hover:-translate-y-2 hover:shadow-xl hover:bg-white/20">
                            <div className="text-2xl mb-2">📷</div>
                            <h3 className="font-semibold text-gray-900 mb-1">Photo Tips</h3>
                            <p className="text-sm text-gray-500">
                                Take a clear, well-lit photo showing all food items for best results.
                            </p>
                        </div>
                        <div className="bg-white/15 backdrop-blur-xl rounded-xl p-4 border border-white/20 transition-all duration-300 hover:-translate-y-2 hover:shadow-xl hover:bg-white/20">
                            <div className="text-2xl mb-2">✍️</div>
                            <h3 className="font-semibold text-gray-900 mb-1">Be Specific</h3>
                            <p className="text-sm text-gray-500">
                                Include portion sizes like &quot;2 eggs&quot; or &quot;1 cup of rice&quot; for accuracy.
                            </p>
                        </div>
                        <div className="bg-white/15 backdrop-blur-xl rounded-xl p-4 border border-white/20 transition-all duration-300 hover:-translate-y-2 hover:shadow-xl hover:bg-white/20">
                            <div className="text-2xl mb-2">🎯</div>
                            <h3 className="font-semibold text-gray-900 mb-1">Stay Consistent</h3>
                            <p className="text-sm text-gray-500">
                                Log all meals to get accurate daily totals and personalized insights.
                            </p>
                        </div>
                    </div>

                    {/* Right: Calendar */}
                    <div className="lg:col-span-2">
                        <div className="mb-4">
                            <h2 className="text-2xl font-bold text-gray-900 mb-2">📅 Meal History</h2>
                            <p className="text-gray-600">Click on a date to view your meals for that day</p>
                        </div>
                        <MealCalendar />
                    </div>
                </div>
            </div>
        </main>
    )
}
