export default function AuthErrorPage() {
    return (
        <div className="flex min-h-screen items-center justify-center">
            <div className="text-center p-8">
                <h1 className="text-2xl font-bold text-red-600 mb-4">Authentication Error</h1>
                <p className="mb-4">There was a problem signing you in.</p>
                <a href="/login" className="text-blue-600 underline">Back to Login</a>
            </div>
        </div>
    )
}
