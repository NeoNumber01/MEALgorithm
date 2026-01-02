import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function Home() {
  const supabase = createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  return (
    <main className="flex min-h-screen flex-col items-center p-24">
      <div className="w-full flex justify-between items-center mb-12">
        <h1 className="text-2xl font-bold">MEALgorithm</h1>
        <div className="flex gap-4 items-center">
          <span className="text-sm text-gray-600">{user.email}</span>
          <form action="/auth/signout" method="post">
            <button className="text-sm text-red-600 hover:underline">Sign Out</button>
          </form>
        </div>
      </div>

      <div className="grid text-center lg:mb-0 lg:w-full lg:max-w-5xl lg:grid-cols-3 lg:text-left gap-4">
        <div className="group rounded-lg border border-transparent px-5 py-4 transition-colors hover:border-gray-300 hover:bg-gray-100 hover:dark:border-neutral-700 hover:dark:bg-neutral-800/30">
          <h2 className="mb-3 text-2xl font-semibold">Log Meal</h2>
          <p className="m-0 max-w-[30ch] text-sm opacity-50">
            Log your meal with text or photo (Coming in M4).
          </p>
        </div>
      </div>
    </main>
  )
}
