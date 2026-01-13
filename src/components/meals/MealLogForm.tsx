'use client'

import { useEffect, useState } from 'react'
import { analyzeMeal } from '@/lib/ai/actions'
import { saveMeal } from '@/lib/meals/actions'
import { MealAnalysis } from '@/lib/ai/schema'
import { notifyDataUpdated } from '@/lib/cache-utils'
import { formatNumber } from '@/lib/format-utils'

type Step = 'input' | 'preview' | 'saving' | 'done'

type FrequentMeal = {
    textContent: string
    mealType: 'breakfast' | 'lunch' | 'dinner' | 'snack' | null
    count: number
}

export default function MealLogForm() {
    const [step, setStep] = useState<Step>('input')
    const [inputMode, setInputMode] = useState<'text' | 'image'>('text')
    const [textInput, setTextInput] = useState('')
    const [imageFile, setImageFile] = useState<File | null>(null)
    const [imagePreview, setImagePreview] = useState<string | null>(null)
    const [imageDescription, setImageDescription] = useState('') // Additional text for image mode
    const [analysis, setAnalysis] = useState<MealAnalysis | null>(null)
    const [error, setError] = useState<string | null>(null)
    const [mealType, setMealType] = useState<'breakfast' | 'lunch' | 'dinner' | 'snack'>('lunch')
    const [frequentMeals, setFrequentMeals] = useState<FrequentMeal[]>([])
    const [loadingFrequent, setLoadingFrequent] = useState(false)

    // Food detection states
    const [isCheckingFood, setIsCheckingFood] = useState(false)
    const [isFoodValid, setIsFoodValid] = useState(false)
    const [detectedFoodClass, setDetectedFoodClass] = useState<string | null>(null)

    // Date/Time state (defaults to now)
    const now = new Date()
    const [date, setDate] = useState(now.toLocaleDateString('en-CA')) // YYYY-MM-DD local
    const [time, setTime] = useState(`${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`)

    // Fetch frequently logged meals for quick-add
    useEffect(() => {
        const fetchFrequent = async () => {
            setLoadingFrequent(true)
            try {
                const res = await fetch('/api/meals/frequent')
                if (!res.ok) throw new Error('Failed to load frequent meals')
                const data = await res.json()
                setFrequentMeals(data.meals || [])
            } catch (err) {
                console.warn('Frequent meals fetch error:', err)
            } finally {
                setLoadingFrequent(false)
            }
        }

        fetchFrequent()
    }, [])

    const handleImageChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]
        if (!file) return

        setImageFile(file)
        setError(null)
        setIsFoodValid(false)
        setDetectedFoodClass(null)
        setIsCheckingFood(true)

        const reader = new FileReader()
        reader.onloadend = async () => {
            const dataUrl = reader.result as string
            setImagePreview(dataUrl)

            // Immediately check if image contains food
            try {
                const base64Data = dataUrl.split(',')[1]

                const response = await fetch('/api/classify-food', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ image: base64Data, threshold: 0.15 }),
                })

                const result = await response.json()

                if (result.isFood || result.failOpen) {
                    setIsFoodValid(true)
                    setDetectedFoodClass(result.detectedClass || null)
                    if (result.detectedClass) {
                        console.log(`[MealLogForm] Detected food: ${result.detectedClass}`)
                    }
                } else {
                    setIsFoodValid(false)
                    setError('This image does not appear to contain food. Please upload a photo of your meal.')
                }
            } catch (err) {
                // Fail-open: allow if detection fails
                console.warn('[MealLogForm] Food detection error:', err)
                setIsFoodValid(true)
            } finally {
                setIsCheckingFood(false)
            }
        }
        reader.readAsDataURL(file)
    }

    const handleSetToNow = () => {
        const now = new Date()
        setDate(now.toLocaleDateString('en-CA'))
        setTime(`${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`)
    }

    const handleAnalyze = async () => {
        setError(null)
        setStep('preview')

        // Food detection already done on image upload - just proceed with analysis
        const formData = new FormData()
        if (inputMode === 'text') {
            formData.append('text', textInput)
        } else if (imageFile) {
            formData.append('image', imageFile)
            // Include additional description if provided
            if (imageDescription.trim()) {
                formData.append('imageDescription', imageDescription.trim())
            }
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

        // Images are only used for AI analysis and not stored
        const saveResult = await saveMeal({
            textContent: inputMode === 'text' ? textInput : undefined,
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
        setImageDescription('')
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
                            onClick={() => {
                                if (inputMode !== 'text') {
                                    setInputMode('text')
                                    // Clear previous analysis when switching modes
                                    setAnalysis(null)
                                    setError(null)
                                }
                            }}
                            className={`flex-1 py-3 rounded-lg font-medium transition ${inputMode === 'text'
                                ? 'bg-blue-600 text-white'
                                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                                }`}
                        >
                            📝 Text
                        </button>
                        <button
                            onClick={() => {
                                if (inputMode !== 'image') {
                                    setInputMode('image')
                                    // Clear previous analysis when switching modes
                                    setAnalysis(null)
                                    setError(null)
                                }
                            }}
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
                        <div className="space-y-4">
                            <div className="border-2 border-dashed rounded-lg p-8 text-center">
                                {imagePreview ? (
                                    <div className="space-y-4">
                                        <img
                                            src={imagePreview}
                                            alt="Meal preview"
                                            className="max-h-64 mx-auto rounded-lg"
                                        />

                                        {/* Food detection status indicator */}
                                        <div className="flex flex-col items-center gap-2">
                                            {isCheckingFood ? (
                                                <span className="text-blue-600 animate-pulse">
                                                    ⏳ Checking if image contains food...
                                                </span>
                                            ) : isFoodValid ? (
                                                <span className="text-green-600">
                                                    ✅ Food detected
                                                </span>
                                            ) : (
                                                <div className="flex flex-col items-center gap-2">
                                                    <span className="text-red-600">
                                                        ❌ Not recognized as food
                                                    </span>
                                                    <button
                                                        onClick={() => {
                                                            setIsFoodValid(true)
                                                            setError(null)
                                                        }}
                                                        className="text-sm text-blue-600 hover:text-blue-800 hover:underline"
                                                    >
                                                        🔓 This is food, analyze anyway
                                                    </button>
                                                </div>
                                            )}
                                        </div>

                                        <button
                                            onClick={() => {
                                                setImageFile(null)
                                                setImagePreview(null)
                                                setIsFoodValid(false)
                                                setDetectedFoodClass(null)
                                                setError(null)
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

                            {/* Additional description input for photo mode */}
                            <div className="bg-gradient-to-r from-blue-50 to-purple-50 rounded-xl p-4 border border-blue-100">
                                <label className="block text-sm font-medium text-gray-700 mb-2">
                                    <span className="mr-2">✍️</span>
                                    Additional Details (Optional)
                                </label>
                                <textarea
                                    value={imageDescription}
                                    onChange={(e) => setImageDescription(e.target.value)}
                                    placeholder="Add any details about your meal... e.g., 'I only ate 1/4 of the pizza' or 'This is a small portion, about 100g'"
                                    className="w-full h-24 p-3 border border-gray-200 rounded-lg resize-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm bg-white/80"
                                />
                                <p className="text-xs text-gray-500 mt-2">
                                    💡 Tip: Mention portion sizes, what you didn&apos;t eat, or any modifications for more accurate analysis.
                                </p>
                            </div>
                        </div>
                    )}

                    {step === 'input' && (
                        <div className="space-y-3">
                            <div className="flex items-center gap-2 text-sm text-gray-600">
                                <span>⚡ Quick add</span>
                                {loadingFrequent && <span className="text-xs text-gray-500">Loading...</span>}
                            </div>
                            <div className="flex flex-wrap gap-2">
                                {frequentMeals.length === 0 && !loadingFrequent && (
                                    <span className="text-xs text-gray-500">No frequent meals yet</span>
                                )}
                                {frequentMeals.map((meal) => {
                                    const icon = meal.mealType === 'breakfast'
                                        ? '🌅'
                                        : meal.mealType === 'lunch'
                                            ? '☀️'
                                            : meal.mealType === 'dinner'
                                                ? '🌙'
                                                : '🍿'
                                    return (
                                        <button
                                            key={`${meal.textContent}-${meal.mealType || 'any'}`}
                                            onClick={() => {
                                                setInputMode('text')
                                                setTextInput(meal.textContent)
                                                if (meal.mealType) setMealType(meal.mealType)
                                                setError(null)
                                                setAnalysis(null)
                                            }}
                                            className="px-3 py-2 rounded-lg border border-gray-200 bg-white/80 hover:bg-white shadow-sm text-left text-sm transition"
                                        >
                                            <div className="flex items-center gap-2">
                                                <span>{icon}</span>
                                                <span className="font-medium truncate max-w-[200px]">{meal.textContent}</span>
                                            </div>
                                            <div className="text-xs text-gray-500 mt-1">Logged {meal.count}×</div>
                                        </button>
                                    )
                                })}
                            </div>
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
                        disabled={
                            inputMode === 'text'
                                ? !textInput
                                : (!imageFile || isCheckingFood || !isFoodValid)
                        }
                        className="w-full py-3 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-lg font-medium disabled:opacity-50 hover:opacity-90 transition"
                    >
                        {isCheckingFood ? '⏳ Checking...' : '🔍 Analyze with AI'}
                    </button>
                </div>
            )}

            {step === 'preview' && !analysis && (
                <div className="text-center py-12">
                    <div
                        className="text-5xl mb-4 inline-block"
                        style={{
                            animation: 'hourglassJumpSpin 3s ease-in-out infinite'
                        }}
                    >⏳</div>
                    <style>{`
                        @keyframes hourglassJumpSpin {
                            0% {
                                transform: translateY(0) rotate(0deg);
                            }
                            /* 平滑旋转半圈 */
                            25% {
                                transform: translateY(0) rotate(180deg);
                            }
                            /* 保持半圈，准备弹跳 */
                            30% {
                                transform: translateY(0) rotate(180deg);
                            }
                            /* 弹跳上升 */
                            40% {
                                transform: translateY(-15px) rotate(180deg);
                            }
                            /* 弹跳落下 */
                            50% {
                                transform: translateY(0) rotate(180deg);
                            }
                            /* 再旋转半圈 */
                            75% {
                                transform: translateY(0) rotate(360deg);
                            }
                            /* 保持一圈，准备弹跳 */
                            80% {
                                transform: translateY(0) rotate(360deg);
                            }
                            /* 弹跳上升 */
                            90% {
                                transform: translateY(-15px) rotate(360deg);
                            }
                            /* 弹跳落下，回到起点 */
                            100% {
                                transform: translateY(0) rotate(360deg);
                            }
                        }
                    `}</style>
                    <p className="text-lg text-gray-600 font-medium">AI is analyzing your meal...</p>
                    <p className="text-sm text-gray-400 mt-2">This may take a few seconds</p>
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
                                    <div className="flex-1">
                                        <div className="flex items-center gap-2">
                                            <span className="font-medium">{item.name}</span>
                                            <span className="text-gray-500">({item.quantity})</span>
                                        </div>
                                        <div className="flex gap-3 mt-1 text-xs">
                                            <span className="text-red-500 font-medium">P: {formatNumber(item.nutrition.protein)}g</span>
                                            <span className="text-yellow-600 font-medium">C: {formatNumber(item.nutrition.carbs)}g</span>
                                            <span className="text-blue-500 font-medium">F: {formatNumber(item.nutrition.fat)}g</span>
                                        </div>
                                    </div>
                                    <span className="text-green-600 font-semibold whitespace-nowrap ml-3">
                                        {formatNumber(item.nutrition.calories)} kcal
                                    </span>
                                </div>
                            ))}
                        </div>
                    </div>

                    <div className="grid grid-cols-4 gap-4">
                        <div className="bg-orange-100 rounded-lg p-4 text-center">
                            <div className="text-2xl font-bold text-orange-600">
                                {formatNumber(analysis.summary.calories)}
                            </div>
                            <div className="text-sm text-gray-600">Calories</div>
                        </div>
                        <div className="bg-red-100 rounded-lg p-4 text-center">
                            <div className="text-2xl font-bold text-red-600">
                                {formatNumber(analysis.summary.protein)}g
                            </div>
                            <div className="text-sm text-gray-600">Protein</div>
                        </div>
                        <div className="bg-yellow-100 rounded-lg p-4 text-center">
                            <div className="text-2xl font-bold text-yellow-600">
                                {formatNumber(analysis.summary.carbs)}g
                            </div>
                            <div className="text-sm text-gray-600">Carbs</div>
                        </div>
                        <div className="bg-blue-100 rounded-lg p-4 text-center">
                            <div className="text-2xl font-bold text-blue-600">
                                {formatNumber(analysis.summary.fat)}g
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
