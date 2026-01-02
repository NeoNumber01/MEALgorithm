import LoginButton from '@/components/auth/LoginButton'

export default function LoginPage() {
    return (
        <div className="flex min-h-screen items-center justify-center bg-gray-50">
            <div className="p-8 bg-white shadow-lg rounded-xl text-center w-full max-w-sm">
                <h1 className="text-3xl font-bold mb-2">MEALgorithm</h1>
                <p className="text-gray-500 mb-8">Sign in to track your meals</p>
                <div className="flex flex-col gap-4">
                    <LoginButton provider="google" />
                    <LoginButton provider="github" />
                </div>
            </div>
        </div>
    )
}
