'use client'

import { useState } from 'react'
import { analyzeMeal } from '@/lib/ai/actions'

export default function AiTestPage() {
    const [input, setInput] = useState('')
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const [result, setResult] = useState<any>(null)
    const [loading, setLoading] = useState(false)

    const handleTest = async () => {
        console.log('Test button clicked. Input:', input)
        setLoading(true)
        try {
            const formData = new FormData()
            formData.append('text', input)

            console.log('Invoking server action analyzeMeal...')
            const res = await analyzeMeal(formData)

            console.log('Server action returned:', res)
            setResult(res)
        } catch (error) {
            console.error('Error invoking server action:', error)
            setResult({ error: 'Client-side exception caught: ' + String(error) })
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="p-8 max-w-2xl mx-auto">
            <h1 className="text-2xl font-bold mb-4">AI Integration Test</h1>

            <div className="flex gap-2 mb-4">
                <input
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    placeholder="e.g. I ate 2 eggs and toast"
                    className="border p-2 flex-1 rounded"
                />
                <button
                    onClick={handleTest}
                    disabled={loading}
                    className="bg-blue-600 text-white px-4 py-2 rounded disabled:opacity-50"
                >
                    {loading ? 'Analyzing...' : 'Test'}
                </button>
            </div>

            {result && (
                <pre className="bg-gray-100 p-4 rounded overflow-auto text-sm">
                    {JSON.stringify(result, null, 2)}
                </pre>
            )}
        </div>
    )
}
