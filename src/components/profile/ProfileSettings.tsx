'use client'

import { useState, useEffect } from 'react'
import { getProfile, updateProfile } from '@/lib/profile/actions'
import { calculateTDEE, calculateMacroTargets, Gender, ActivityLevel } from '@/lib/nutrition/calculator'
import { notifyGoalUpdated, notifyDataUpdated } from '@/lib/cache-utils'

type Goal = 'maintenance' | 'weight-loss' | 'muscle-gain'

export default function ProfileSettings() {
    const [loading, setLoading] = useState(true)
    const [saving, setSaving] = useState(false)
    const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

    // Physical stats
    const [heightCm, setHeightCm] = useState<number | ''>('')
    const [weightKg, setWeightKg] = useState<number | ''>('')
    const [age, setAge] = useState<number | ''>('')
    const [gender, setGender] = useState<Gender>('male')
    const [activityLevel, setActivityLevel] = useState<ActivityLevel>('moderate')
    const [goal, setGoal] = useState<Goal>('maintenance')
    const [showBodyCompositionWarning, setShowBodyCompositionWarning] = useState(false)

    // Calculated/Custom targets
    const [calorieTarget, setCalorieTarget] = useState(2000)
    const [proteinTarget, setProteinTarget] = useState(150)
    const [carbsTarget, setCarbsTarget] = useState(200)
    const [fatTarget, setFatTarget] = useState(65)
    const [useCustomTargets, setUseCustomTargets] = useState(false)

    useEffect(() => {
        loadProfile()
    }, [])

    useEffect(() => {
        // Recalculate when stats or goal changes
        if (!useCustomTargets && heightCm && weightKg && age) {
            let tdee = calculateTDEE(Number(weightKg), Number(heightCm), Number(age), gender, activityLevel)
            
            // Adjust TDEE based on goal
            if (goal === 'weight-loss') {
                // 15% deficit for sustainable weight loss
                tdee = Math.round(tdee * 0.85)
            } else if (goal === 'muscle-gain') {
                // 15% surplus for lean bulk (moderate surplus for general lifters)
                tdee = Math.round(tdee * 1.15)
            }
            // For maintenance, use TDEE as-is
            
            const macros = calculateMacroTargets(tdee)
            setCalorieTarget(tdee)
            setProteinTarget(macros.protein)
            setCarbsTarget(macros.carbs)
            setFatTarget(macros.fat)
        }
    }, [heightCm, weightKg, age, gender, activityLevel, useCustomTargets, goal])

    const loadProfile = async () => {
        setLoading(true)
        const result = await getProfile()

        if (!('error' in result) && result.profile) {
            const p = result.profile
            if (p.height_cm) setHeightCm(p.height_cm)
            if (p.weight_kg) setWeightKg(p.weight_kg)
            if (p.age) setAge(p.age)
            if (p.gender) setGender(p.gender)
            if (p.activity_level) setActivityLevel(p.activity_level)
            // Parse goal from profile or default to maintenance
            if (p.goal) {
                const goalValue = p.goal as Goal
                if (['maintenance', 'weight-loss', 'muscle-gain'].includes(goalValue)) {
                    setGoal(goalValue)
                }
            }
            if (p.calorie_target) setCalorieTarget(p.calorie_target)
            if (p.protein_target) setProteinTarget(p.protein_target)
            if (p.carbs_target) setCarbsTarget(p.carbs_target)
            if (p.fat_target) setFatTarget(p.fat_target)
        }

        setLoading(false)
    }

    const handleSave = async () => {
        setSaving(true)
        setMessage(null)

        const result = await updateProfile({
            height_cm: heightCm ? Number(heightCm) : undefined,
            weight_kg: weightKg ? Number(weightKg) : undefined,
            age: age ? Number(age) : undefined,
            gender,
            activity_level: activityLevel,
            goal,
            calorie_target: calorieTarget,
            protein_target: proteinTarget,
            carbs_target: carbsTarget,
            fat_target: fatTarget,
        })

        if ('error' in result) {
            setMessage({ type: 'error', text: result.error || 'Unknown error' })
        } else {
            setMessage({ type: 'success', text: 'Profile saved successfully!' })
            // Notify that goals/targets have been updated - this will invalidate AI caches
            notifyGoalUpdated()
            notifyDataUpdated()
        }

        setSaving(false)
    }

    if (loading) {
        return (
            <div className="flex items-center justify-center py-20">
                <div className="animate-spin text-4xl">⏳</div>
            </div>
        )
    }

    return (
        <div className="space-y-8">
            {message && (
                <div className={`p-4 rounded-lg ${message.type === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                    }`}>
                    {message.text}
                </div>
            )}

            {/* Physical Stats */}
            <div className="bg-white/15 backdrop-blur-2xl rounded-xl border border-white/20 p-6 transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20">
                <h2 className="text-xl font-bold mb-4">📏 Physical Stats</h2>
                <p className="text-gray-500 text-sm mb-4">
                    We use the Mifflin-St Jeor equation to calculate your daily calorie needs.
                </p>

                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Height (cm)</label>
                        <input
                            type="number"
                            value={heightCm}
                            onChange={(e) => setHeightCm(e.target.value ? Number(e.target.value) : '')}
                            className="w-full p-2 border border-white/30 rounded-lg bg-white/50 focus:bg-white/80 transition-all font-medium"
                            placeholder="170"
                        />
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Weight (kg)</label>
                        <input
                            type="number"
                            value={weightKg}
                            onChange={(e) => setWeightKg(e.target.value ? Number(e.target.value) : '')}
                            className="w-full p-2 border border-white/30 rounded-lg bg-white/50 focus:bg-white/80 transition-all font-medium"
                            placeholder="70"
                        />
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Age</label>
                        <input
                            type="number"
                            value={age}
                            onChange={(e) => setAge(e.target.value ? Number(e.target.value) : '')}
                            className="w-full p-2 border border-white/30 rounded-lg bg-white/50 focus:bg-white/80 transition-all font-medium"
                            placeholder="25"
                        />
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Gender</label>
                        <select
                            value={gender}
                            onChange={(e) => setGender(e.target.value as Gender)}
                            className="w-full p-2 border border-white/30 rounded-lg bg-white/50 focus:bg-white/80 transition-all font-medium"
                        >
                            <option value="male">Male</option>
                            <option value="female">Female</option>
                            <option value="other">Other</option>
                        </select>
                    </div>
                </div>

                <div className="mt-4">
                    <label className="block text-sm font-medium text-gray-700 mb-1">Activity Level</label>
                    <select
                        value={activityLevel}
                        onChange={(e) => setActivityLevel(e.target.value as ActivityLevel)}
                        className="w-full p-2 border border-white/30 rounded-lg bg-white/50 focus:bg-white/80 transition-all font-medium"
                    >
                        <option value="sedentary">Sedentary (little or no exercise)</option>
                        <option value="light">Light (exercise 1-3 days/week)</option>
                        <option value="moderate">Moderate (exercise 3-5 days/week)</option>
                        <option value="active">Active (exercise 6-7 days/week)</option>
                        <option value="very_active">Very Active (intense exercise + physical job)</option>
                    </select>
                </div>
            </div>

            {/* Goals */}
            <div className="bg-white/15 backdrop-blur-2xl rounded-xl border border-white/20 p-6 transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20">
                <h2 className="text-xl font-bold mb-4">🎯 Goals</h2>

                <div className="mb-4">
                    <label className="block text-sm font-medium text-gray-700 mb-1">Your Goal</label>
                    <select
                        value={goal}
                        onChange={(e) => {
                            const newGoal = e.target.value as Goal
                            setGoal(newGoal)
                            // Show warning if selecting muscle-gain
                            if (newGoal === 'muscle-gain') {
                                setShowBodyCompositionWarning(true)
                            }
                        }}
                        className="w-full p-2 border border-white/30 rounded-lg bg-white/50 focus:bg-white/80 transition-all font-medium"
                    >
                        <option value="maintenance">⚖️ Maintain Current Weight</option>
                        <option value="weight-loss">📉 Lose Weight</option>
                        <option value="muscle-gain">💪 Build Muscle</option>
                    </select>
                    <p className="text-xs text-gray-600 mt-2">
                        {goal === 'weight-loss' && 'Your calorie target will be reduced by ~15% for sustainable weight loss'}
                        {goal === 'muscle-gain' && 'Your calorie target will be increased by ~15% for lean muscle gain'}
                        {goal === 'maintenance' && 'Your calorie target will be set to your daily energy expenditure'}
                    </p>
                </div>

                <div className="flex items-center gap-2 mb-4">
                    <input
                        type="checkbox"
                        id="customTargets"
                        checked={useCustomTargets}
                        onChange={(e) => setUseCustomTargets(e.target.checked)}
                        className="rounded"
                    />
                    <label htmlFor="customTargets" className="text-sm text-gray-700">
                        Use custom targets instead of calculated values
                    </label>
                </div>
            </div>

            {/* Body Composition Warning Modal */}
            {showBodyCompositionWarning && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                    <div className="bg-white rounded-lg p-6 max-w-md shadow-2xl">
                        <h3 className="text-lg font-bold mb-4 text-gray-900">⚠️ Body Composition Check</h3>
                        <p className="text-gray-700 mb-4">
                            Building muscle works best when you have room to gain. Before selecting "Build Muscle," consider:
                        </p>
                        <ul className="text-sm text-gray-700 space-y-2 mb-4">
                            <li>✓ You have <strong>less than 25% body fat</strong> (estimated)</li>
                            <li>✓ You're doing <strong>strength training</strong> regularly</li>
                            <li>✓ You're getting <strong>adequate protein</strong> (~0.8-1g per lb)</li>
                        </ul>
                        <p className="text-sm text-gray-600 mb-4">
                            If you have high body fat, consider weight loss first to preserve muscle during the cut.
                        </p>
                        <div className="flex gap-3">
                            <button
                                onClick={() => setShowBodyCompositionWarning(false)}
                                className="flex-1 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors font-medium"
                            >
                                I'm Ready 💪
                            </button>
                            <button
                                onClick={() => {
                                    setShowBodyCompositionWarning(false)
                                    setGoal('maintenance')
                                }}
                                className="flex-1 px-4 py-2 bg-gray-300 text-gray-900 rounded-lg hover:bg-gray-400 transition-colors font-medium"
                            >
                                Choose Different Goal
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Nutritional Targets */}
            <div className="bg-gradient-to-r from-orange-500/90 to-red-500/90 backdrop-blur-xl rounded-xl p-6 text-white shadow-lg transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl">
                <h2 className="text-xl font-bold mb-4">🔥 Daily Targets</h2>

                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div className="bg-white/20 rounded-lg p-4">
                        <label className="block text-sm opacity-80 mb-1">Calories</label>
                        <input
                            type="number"
                            value={calorieTarget}
                            onChange={(e) => setCalorieTarget(Number(e.target.value))}
                            disabled={!useCustomTargets}
                            className="w-full p-2 rounded bg-white/30 text-white placeholder-white/60 disabled:opacity-70"
                        />
                        <span className="text-xs opacity-80">kcal</span>
                    </div>
                    <div className="bg-white/20 rounded-lg p-4">
                        <label className="block text-sm opacity-80 mb-1">Protein</label>
                        <input
                            type="number"
                            value={proteinTarget}
                            onChange={(e) => setProteinTarget(Number(e.target.value))}
                            disabled={!useCustomTargets}
                            className="w-full p-2 rounded bg-white/30 text-white placeholder-white/60 disabled:opacity-70"
                        />
                        <span className="text-xs opacity-80">grams</span>
                    </div>
                    <div className="bg-white/20 rounded-lg p-4">
                        <label className="block text-sm opacity-80 mb-1">Carbs</label>
                        <input
                            type="number"
                            value={carbsTarget}
                            onChange={(e) => setCarbsTarget(Number(e.target.value))}
                            disabled={!useCustomTargets}
                            className="w-full p-2 rounded bg-white/30 text-white placeholder-white/60 disabled:opacity-70"
                        />
                        <span className="text-xs opacity-80">grams</span>
                    </div>
                    <div className="bg-white/20 rounded-lg p-4">
                        <label className="block text-sm opacity-80 mb-1">Fat</label>
                        <input
                            type="number"
                            value={fatTarget}
                            onChange={(e) => setFatTarget(Number(e.target.value))}
                            disabled={!useCustomTargets}
                            className="w-full p-2 rounded bg-white/30 text-white placeholder-white/60 disabled:opacity-70"
                        />
                        <span className="text-xs opacity-80">grams</span>
                    </div>
                </div>

                {!useCustomTargets && heightCm && weightKg && age && (
                    <p className="text-sm mt-4 opacity-80">
                        💡 Based on your stats, your estimated TDEE is {calorieTarget} kcal/day
                    </p>
                )}
            </div>

            {/* Save Button */}
            <button
                onClick={handleSave}
                disabled={saving}
                className="w-full py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50"
            >
                {saving ? 'Saving...' : 'Save Profile'}
            </button>
        </div>
    )
}
