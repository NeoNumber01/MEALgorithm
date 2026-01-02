import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import MealLogForm from '@/components/meals/MealLogForm'

export default async function LogMealPage() {
    const supabase = createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        redirect('/login')
    }

    return (
        <main className="min-h-screen bg-gray-50">
            <div className="max-w-4xl mx-auto px-4 py-8">
                <div className="mb-8">
                    <h1 className="text-3xl font-bold text-gray-900">Log a Meal</h1>
                    <p className="text-gray-600 mt-2">
                        Describe your meal or upload a photo, and let AI analyze its nutritional content.
                    </p>
                </div>

                <div className="bg-white rounded-xl shadow-sm p-6">
                    <MealLogForm />
                </div>
            </div>
        </main>
    )
}
