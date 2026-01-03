import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'

export default async function Home() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  // Get some quick stats for the user
  const { data: profile } = await supabase
    .from('profiles')
    .select('calorie_target, goal_description')
    .eq('id', user.id)
    .single()

  const today = new Date()
  const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate()).toISOString()

  const { count: todayMealsCount } = await supabase
    .from('meals')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', user.id)
    .gte('created_at', startOfDay)

  return (
    <main className="min-h-screen relative">
      {/* Global Background */}
      <div
        className="fixed inset-0 z-0 pointer-events-none"
        style={{
          backgroundImage: "url('/images/food-hero-bg.png')",
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundRepeat: 'no-repeat',
          opacity: 0.9
        }}
      />

      {/* Hero Section */}
      <section className="relative overflow-hidden min-h-[90vh] flex items-center justify-center z-10">

        <div className="relative max-w-5xl mx-auto px-4 py-20 text-center">
          {/* The "Board" Card with Glassmorphism */}
          <div className="bg-white/50 backdrop-blur-xl rounded-3xl p-8 md:p-14 shadow-2xl border border-white/40 relative overflow-hidden">


            <div className="relative z-10">
              <div className="inline-flex items-center gap-2 bg-white px-4 py-2 rounded-full text-sm font-medium text-cyan-700 mb-8 shadow-sm border border-cyan-100">
                <span className="animate-pulse">🟢</span> AI-Powered Nutrition Tracking
              </div>

              <h1 className="text-5xl md:text-7xl font-extrabold mb-6 tracking-tight">
                <span className="relative inline-block hover:-translate-y-2 transition-transform duration-500 cursor-default">
                  <span className="absolute inset-0 bg-gradient-to-r from-cyan-600/20 via-sky-500/20 to-lime-500/20 bg-clip-text text-transparent blur-sm translate-y-4 scale-y-[-0.3] opacity-50">
                    Welcome to MEALgorithm
                  </span>
                  <span className="relative z-10 bg-gradient-to-r from-cyan-600 via-sky-500 to-lime-500 bg-clip-text text-transparent drop-shadow-[4px_4px_0_rgba(14,116,144,0.5)] [-webkit-text-stroke:1px_rgba(255,255,255,0.8)]">
                    Welcome to MEALgorithm
                  </span>
                </span>
              </h1>

              <p className="text-xl md:text-2xl text-gray-700 mb-10 max-w-3xl mx-auto leading-relaxed">
                Your personal AI nutritionist in your pocket. Track meals, get insights,
                and receive personalized recommendations powered by advanced AI.
              </p>

              <div className="flex flex-wrap justify-center gap-4">
                <Link
                  href="/log"
                  className="px-8 py-4 bg-gradient-to-r from-cyan-500 via-sky-500 to-lime-500 text-white font-semibold rounded-xl hover:shadow-lg hover:shadow-cyan-500/25 transition-all hover:-translate-y-0.5"
                >
                  📝 Log Your Meal
                </Link>
                <Link
                  href="/dashboard"
                  className="px-8 py-4 bg-white border-2 border-gray-200 text-gray-700 font-semibold rounded-xl hover:border-cyan-300 hover:shadow-lg transition-all hover:-translate-y-0.5"
                >
                  📊 View Dashboard
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Quick Stats */}
      <section className="max-w-6xl mx-auto px-4 -mt-8">
        <div className="bg-white/60 backdrop-blur-md rounded-2xl shadow-xl border border-white/40 p-6 grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="text-center p-4">
            <div className="text-4xl mb-2">🎯</div>
            <div className="text-3xl font-bold text-gray-900">
              {profile?.calorie_target || 2000}
            </div>
            <div className="text-sm text-gray-500">Daily Calorie Target</div>
          </div>
          <div className="text-center p-4 border-x border-gray-100">
            <div className="text-4xl mb-2">🍽️</div>
            <div className="text-3xl font-bold text-gray-900">
              {todayMealsCount || 0}
            </div>
            <div className="text-sm text-gray-500">Meals Logged Today</div>
          </div>
          <div className="text-center p-4">
            <div className="text-4xl mb-2">💪</div>
            <div className="text-xl font-bold text-gray-900 truncate">
              {profile?.goal_description || 'Set your goal'}
            </div>
            <div className="text-sm text-gray-500">Current Goal</div>
          </div>
        </div>
      </section>

      {/* Feature Cards */}
      <section className="max-w-6xl mx-auto px-4 py-16">
        <h2 className="text-2xl font-bold text-center mb-8 text-gray-800">
          What would you like to do?
        </h2>

        <div className="grid md:grid-cols-3 gap-6">
          <Link href="/log" className="group">
            <div className="bg-white/60 backdrop-blur-md border border-orange-100/50 rounded-2xl p-8 h-full transition-all hover:shadow-xl hover:-translate-y-1">
              <div className="text-5xl mb-4 group-hover:scale-110 transition-transform">📸</div>
              <h3 className="text-xl font-bold text-gray-900 mb-2">Log a Meal</h3>
              <p className="text-gray-600 mb-4">
                Snap a photo or describe your meal. Our AI will analyze the nutrition instantly.
              </p>
              <div className="flex items-center text-orange-600 font-medium group-hover:translate-x-2 transition-transform">
                Get started <span className="ml-2">→</span>
              </div>
            </div>
          </Link>

          <Link href="/dashboard" className="group">
            <div className="bg-white/60 backdrop-blur-md border border-blue-100/50 rounded-2xl p-8 h-full transition-all hover:shadow-xl hover:-translate-y-1">
              <div className="text-5xl mb-4 group-hover:scale-110 transition-transform">📊</div>
              <h3 className="text-xl font-bold text-gray-900 mb-2">View Dashboard</h3>
              <p className="text-gray-600 mb-4">
                Track your progress with beautiful charts and AI-powered insights.
              </p>
              <div className="flex items-center text-blue-600 font-medium group-hover:translate-x-2 transition-transform">
                See insights <span className="ml-2">→</span>
              </div>
            </div>
          </Link>

          <Link href="/recommendations" className="group">
            <div className="bg-white/60 backdrop-blur-md border border-green-100/50 rounded-2xl p-8 h-full transition-all hover:shadow-xl hover:-translate-y-1">
              <div className="text-5xl mb-4 group-hover:scale-110 transition-transform">💡</div>
              <h3 className="text-xl font-bold text-gray-900 mb-2">Get Suggestions</h3>
              <p className="text-gray-600 mb-4">
                Personalized meal recommendations based on your preferences and goals.
              </p>
              <div className="flex items-center text-green-600 font-medium group-hover:translate-x-2 transition-transform">
                Explore ideas <span className="ml-2">→</span>
              </div>
            </div>
          </Link>
        </div>
      </section>

      {/* How It Works */}
      {/* How It Works */}
      <section className="relative py-16">
        <div className="relative max-w-6xl mx-auto px-4">
          <div className="bg-white/60 backdrop-blur-md rounded-3xl p-8 md:p-12 shadow-xl border border-white/40">
            <h2 className="text-2xl font-bold text-center mb-12 text-gray-800">
              How MEALgorithm Works
            </h2>

            <div className="grid md:grid-cols-4 gap-8">
              <div className="text-center">
                <div className="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4 text-2xl">
                  1️⃣
                </div>
                <h3 className="font-semibold mb-2">Log Your Meal</h3>
                <p className="text-sm text-gray-500">Take a photo or describe what you ate</p>
              </div>

              <div className="text-center">
                <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4 text-2xl">
                  2️⃣
                </div>
                <h3 className="font-semibold mb-2">AI Analyzes</h3>
                <p className="text-sm text-gray-500">Gemini AI breaks down the nutrition</p>
              </div>

              <div className="text-center">
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4 text-2xl">
                  3️⃣
                </div>
                <h3 className="font-semibold mb-2">Track Progress</h3>
                <p className="text-sm text-gray-500">See trends and get personalized feedback</p>
              </div>

              <div className="text-center">
                <div className="w-16 h-16 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-4 text-2xl">
                  4️⃣
                </div>
                <h3 className="font-semibold mb-2">Get Suggestions</h3>
                <p className="text-sm text-gray-500">Receive tailored meal recommendations</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="relative z-10 bg-white/10 backdrop-blur-xl border-t border-white/20 py-12 mt-12">
        <div className="max-w-6xl mx-auto px-4 text-center">
          <p className="text-gray-800 font-medium">
            Built with ❤️ using Next.js, Supabase & Gemini AI
          </p>
          <p className="text-gray-500 text-sm mt-2">
            MEALgorithm © 2026 - Your AI Nutrition Companion
          </p>
        </div>
      </footer>
    </main >
  )
}
