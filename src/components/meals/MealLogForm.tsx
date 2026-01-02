'use client'

import { useState } from 'react'
import { analyzeMeal } from '@/lib/ai/actions'
import { saveMeal, uploadMealImage } from '@/lib/meals/actions'
import { MealAnalysis } from '@/lib/ai/schema'
import { notifyDataUpdated } from '@/lib/cache-utils'

type Step = 'input' | 'preview' | 'saving' | 'done'

export default function MealLogForm() {
    const [step, setStep] = useState<Step>('input')
    const [inputMode, setInputMode] = useState<'text' | 'image'>('text')
    const [textInput, setTextInput] = useState('')
    const [imageFile, setImageFile] = useState<File | null>(null)
    const [imagePreview, setImagePreview] = useState<string | null>(null)
    const [analysis, setAnalysis] = useState<MealAnalysis | null>(null)
    const [error, setError] = useState<string | null>(null)
    const [mealType, setMealType] = useState<'breakfast' | 'lunch' | 'dinner' | 'snack'>('lunch')

    // Date/Time state (defaults to now)
    const now = new Date()
    const [date, setDate] = useState(now.toLocaleDateString('en-CA')) // YYYY-MM-DD local
    const [time, setTime] = useState(`${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`)

    const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]
        if (file) {
            setImageFile(file)
            const reader = new FileReader()
            reader.onloadend = () => {
                setImagePreview(reader.result as string)
            }
            reader.readAsDataURL(file)
        }
    }

    const handleSetToNow = () => {
        const now = new Date()
        setDate(now.toLocaleDateString('en-CA'))
        setTime(`${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`)
    }

    const handleAnalyze = async () => {
        setError(null)
        setStep('preview')

        const formData = new FormData()
        if (inputMode === 'text') {
            formData.append('text', textInput)
        } else if (imageFile) {
            formData.append('image', imageFile)
        }

        const result = await analyzeMeal(formData)

        if ('error' in result) {
            setError(result.error || 'Unknown error')
            setStep('input')
            return
        }

        if (result.data) {
            setAnalysis(result.data)
        }
    }

    const handleConfirm = async () => {
        if (!analysis) return

        setStep('saving')

        let imagePath: string | undefined

        if (imageFile) {
            const uploadForm = new FormData()
            uploadForm.append('image', imageFile)
            const uploadResult = await uploadMealImage(uploadForm)
            if ('error' in uploadResult) {
                setError(uploadResult.error || 'Upload failed')
                setStep('preview')
                return
            }
            imagePath = uploadResult.path
        }

        const saveResult = await saveMeal({
            textContent: inputMode === 'text' ? textInput : undefined,
            imagePath,
            analysis,
            mealType,
            createdAt: new Date(`${date}T${time}`).toISOString(),
        })

        if ('error' in saveResult) {
            setError(saveResult.error || 'Save failed')
            setStep('preview')
            return
        }

        notifyDataUpdated()
        setStep('done')
    }

    const handleReset = () => {
        setStep('input')
        setTextInput('')
        setImageFile(null)
        setImagePreview(null)
        setAnalysis(null)
        setError(null)
        // Reset time to now on new entry
        const now = new Date()
        setDate(now.toLocaleDateString('en-CA'))
        setTime(`${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`)
    }

    if (step === 'done') {
        return (
            <div className="text-center py-12">
                <div className="text-5xl mb-4">✅</div>
                <h2 className="text-2xl font-bold text-green-600 mb-4">Meal Logged!</h2>
                <p className="text-gray-600 mb-6">Your meal has been saved successfully.</p>
                <button
                    onClick={handleReset}
                    className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700"
                >
                    Log Another Meal
                </button>
            </div>
        )
    }

    return (
        <div className="max-w-2xl mx-auto">
            {error && (
                <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                    {error}
                </div>
            )}

            {step === 'input' && (
                <div className="space-y-6">
                    <div className="flex gap-4 mb-6">
                        <button
                            onClick={() => setInputMode('text')}
                            className={`flex-1 py-3 rounded-lg font-medium transition ${inputMode === 'text'
                                ? 'bg-blue-600 text-white'
                                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                                }`}
                        >
                            📝 Text
                        </button>
                        <button
                            onClick={() => setInputMode('image')}
                            className={`flex-1 py-3 rounded-lg font-medium transition ${inputMode === 'image'
                                ? 'bg-blue-600 text-white'
                                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                                }`}
                        >
                            📷 Photo
                        </button>
                    </div>

                    {inputMode === 'text' ? (
                        <textarea
                            value={textInput}
                            onChange={(e) => setTextInput(e.target.value)}
                            placeholder="Describe your meal... e.g., 'I had a grilled chicken salad with olive oil dressing and a glass of orange juice'"
                            className="w-full h-32 p-4 border rounded-lg resize-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        />
                    ) : (
                        <div className="border-2 border-dashed rounded-lg p-8 text-center">
                            {imagePreview ? (
                                <div className="space-y-4">
                                    <img
                                        src={imagePreview}
                                        alt="Meal preview"
                                        className="max-h-64 mx-auto rounded-lg"
                                    />
                                    <button
                                        onClick={() => {
                                            setImageFile(null)
                                            setImagePreview(null)
                                        }}
                                        className="text-red-600 hover:underline"
                                    >
                                        Remove
                                    </button>
                                </div>
                            ) : (
                                <label className="cursor-pointer">
                                    <div className="text-4xl mb-2">📷</div>
                                    <p className="text-gray-600">Click to upload a photo of your meal</p>
                                    <input
                                        type="file"
                                        accept="image/*"
                                        onChange={handleImageChange}
                                        className="hidden"
                                    />
                                </label>
                            )}
                        </div>
                    )}

                    <div className="grid grid-cols-2 gap-6 bg-white/40 p-5 rounded-3xl border border-white/60 shadow-sm backdrop-blur-sm">
                        <div className="relative group">
                            <label className="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-2 ml-1 group-hover:text-purple-600 transition-colors">
                                Date
                            </label>
                            <div className="relative transition-transform duration-200 group-hover:-translate-y-0.5">
                                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none z-10">
                                    <span className="text-lg opacity-70 grayscale group-hover:grayscale-0 transition-all duration-300">📅</span>
                                </div>
                                <input
                                    type="date"
                                    value={date}
                                    max={new Date().toLocaleDateString('en-CA')}
                                    onChange={(e) => setDate(e.target.value)}
                                    className="w-full pl-11 pr-4 py-3 bg-white/80 border-2 border-transparent focus:border-purple-300 rounded-2xl focus:ring-4 focus:ring-purple-100/50 transition-all outline-none text-gray-700 font-medium hover:bg-white hover:shadow-md cursor-pointer appearance-none"
                                />
                            </div>
                        </div>
                        <div className="relative group">
                            <label className="block text-xs font-bold text-gray-500 uppercase tracking-wider mb-2 ml-1 group-hover:text-blue-600 transition-colors">
                                Time
                            </label>
                            <div className="relative transition-transform duration-200 group-hover:-translate-y-0.5">
                                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none z-10">
                                    <span className="text-lg opacity-70 grayscale group-hover:grayscale-0 transition-all duration-300">⏰</span>
                                </div>
                                <input
                                    type="time"
                                    value={time}
                                    onChange={(e) => setTime(e.target.value)}
                                    className="w-full pl-11 pr-12 py-3 bg-white/80 border-2 border-transparent focus:border-blue-300 rounded-2xl focus:ring-4 focus:ring-blue-100/50 transition-all outline-none text-gray-700 font-medium hover:bg-white hover:shadow-md cursor-pointer appearance-none"
                                />
                                <button
                                    onClick={handleSetToNow}
                                    className="absolute inset-y-0 right-0 pr-3 flex items-center justify-center text-gray-400 hover:text-blue-600 transition-colors z-20 group/btn"
                                    title="Set to now"
                                >
                                    <span className="text-xl transform group-hover/btn:rotate-180 transition-transform duration-500">🔄</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                            Meal Type
                        </label>
                        <select
                            value={mealType}
                            onChange={(e) => setMealType(e.target.value as typeof mealType)}
                            className="w-full p-3 border rounded-lg"
                        >
                            <option value="breakfast">🌅 Breakfast</option>
                            <option value="lunch">☀️ Lunch</option>
                            <option value="dinner">🌙 Dinner</option>
                            <option value="snack">🍿 Snack</option>
                        </select>
                    </div>

                    <button
                        onClick={handleAnalyze}
                        disabled={inputMode === 'text' ? !textInput : !imageFile}
                        className="w-full py-3 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-lg font-medium disabled:opacity-50 hover:opacity-90 transition"
                    >
                        🔍 Analyze with AI
                    </button>
                </div>
            )}

            {step === 'preview' && analysis && (
                <div className="space-y-6">
                    <h2 className="text-xl font-bold">Analysis Preview</h2>

                    <div className="bg-gray-50 rounded-lg p-6">
                        <h3 className="font-semibold mb-4">Food Items</h3>
                        <div className="space-y-3">
                            {analysis.items.map((item, idx) => (
                                <div key={idx} className="flex justify-between items-center bg-white p-3 rounded">
                                    <div>
                                        <span className="font-medium">{item.name}</span>
                                        <span className="text-gray-500 ml-2">({item.quantity})</span>
                                    </div>
                                    <span className="text-blue-600 font-semibold">
                                        {item.nutrition.calories} kcal
                                    </span>
                                </div>
                            ))}
                        </div>
                    </div>

                    <div className="grid grid-cols-4 gap-4">
                        <div className="bg-orange-100 rounded-lg p-4 text-center">
                            <div className="text-2xl font-bold text-orange-600">
                                {analysis.summary.calories}
                            </div>
                            <div className="text-sm text-gray-600">Calories</div>
                        </div>
                        <div className="bg-red-100 rounded-lg p-4 text-center">
                            <div className="text-2xl font-bold text-red-600">
                                {analysis.summary.protein}g
                            </div>
                            <div className="text-sm text-gray-600">Protein</div>
                        </div>
                        <div className="bg-yellow-100 rounded-lg p-4 text-center">
                            <div className="text-2xl font-bold text-yellow-600">
                                {analysis.summary.carbs}g
                            </div>
                            <div className="text-sm text-gray-600">Carbs</div>
                        </div>
                        <div className="bg-blue-100 rounded-lg p-4 text-center">
                            <div className="text-2xl font-bold text-blue-600">
                                {analysis.summary.fat}g
                            </div>
                            <div className="text-sm text-gray-600">Fat</div>
                        </div>
                    </div>

                    <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                        <p className="text-green-800">💡 {analysis.feedback}</p>
                    </div>

                    <div className="flex gap-4">
                        <button
                            onClick={() => setStep('input')}
                            className="flex-1 py-3 border border-gray-300 rounded-lg font-medium hover:bg-gray-50"
                        >
                            ← Edit
                        </button>
                        <button
                            onClick={handleConfirm}
                            className="flex-1 py-3 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700"
                        >
                            ✓ Confirm & Save
                        </button>
                    </div>
                </div>
            )
            }

            {
                step === 'saving' && (
                    <div className="text-center py-12">
                        <div className="animate-spin text-4xl mb-4">⏳</div>
                        <p className="text-gray-600">Saving your meal...</p>
                    </div>
                )
            }
        </div >
    )
}
