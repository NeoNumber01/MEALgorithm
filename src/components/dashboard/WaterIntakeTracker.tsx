'use client'

import { useState } from 'react'
import { logWaterIntake } from '@/lib/water/actions'

interface WaterIntakeTrackerProps {
    currentIntake: number  // in ml
    target?: number        // in ml, default 2000
    onWaterLogged?: () => void  // Callback to refresh dashboard
}

export default function WaterIntakeTracker({ currentIntake, target = 2000, onWaterLogged }: WaterIntakeTrackerProps) {
    const [isLogging, setIsLogging] = useState(false)
    const percentage = Math.min((currentIntake / target) * 100, 100)
    const glasses = Math.round(currentIntake / 250) // 250ml per glass

    const quickAddOptions = [250, 500, 750, 1000] // ml

    const handleAddWater = async (amount: number) => {
        setIsLogging(true)
        try {
            const result = await logWaterIntake(amount)
            if ('success' in result && result.success) {
                onWaterLogged?.()
            }
        } catch (error) {
            console.error('Error logging water:', error)
        } finally {
            setIsLogging(false)
        }
    }

    return (
        <div className="bg-white/15 backdrop-blur-2xl rounded-xl border border-white/20 p-6 transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20">
            <h3 className="text-lg font-bold mb-4">💧 Water Intake</h3>

            {/* Pitcher Visualization */}
            <div className="flex flex-col items-center mb-6">
                {/* Pitcher Container */}
                <div className="relative w-24 h-40 border-4 border-gray-400 rounded-b-3xl rounded-t-lg bg-white/20 overflow-hidden shadow-lg">
                    {/* Water Fill */}
                    <div
                        className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-blue-400 to-blue-300 transition-all duration-500"
                        style={{ height: `${percentage}%` }}
                    >
                        {/* Water Wave Effect */}
                        <div className="absolute top-0 left-0 right-0 h-1 bg-white/50 opacity-75"></div>
                    </div>

                    {/* Pitcher Handle */}
                    <div className="absolute -right-2 top-8 w-6 h-12 border-4 border-gray-400 rounded-full"></div>

                    {/* Percentage Text */}
                    <div className="absolute inset-0 flex items-center justify-center">
                        <span className="text-xl font-bold text-gray-800 drop-shadow-lg">
                            {Math.round(percentage)}%
                        </span>
                    </div>
                </div>

                {/* Water Amount Info */}
                <div className="mt-4 text-center">
                    <p className="text-sm text-gray-600 mb-1">
                        {currentIntake} / {target} ml
                    </p>
                    <p className="text-xs text-gray-500">
                        {glasses} glass{glasses !== 1 ? 'es' : ''} of water
                    </p>
                </div>
            </div>

            {/* Quick Add Buttons */}
            <div className="grid grid-cols-2 gap-2">
                {quickAddOptions.map((amount) => (
                    <button
                        key={amount}
                        onClick={() => handleAddWater(amount)}
                        disabled={isLogging}
                        className="px-3 py-2 bg-blue-400/80 hover:bg-blue-500 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-lg text-sm font-medium transition-colors duration-200"
                    >
                        {isLogging ? '...' : `+${amount}ml`}
                    </button>
                ))}
            </div>

            {/* Encouragement Message */}
            {percentage < 100 && (
                <p className="mt-4 text-xs text-gray-600 text-center">
                    {percentage < 50 ? '💪 Keep hydrating!' : percentage < 75 ? '🟦 Almost there!' : '🎯 Nearly done!'}
                </p>
            )}
            {percentage >= 100 && (
                <p className="mt-4 text-xs text-green-600 text-center font-medium">
                    ✅ Great job! Daily goal reached!
                </p>
            )}
        </div>
    )
}
