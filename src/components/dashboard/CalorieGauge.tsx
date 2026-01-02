'use client'

interface CalorieGaugeProps {
    current: number
    target: number
    label?: string
}

export default function CalorieGauge({ current, target, label = "Today's Calories" }: CalorieGaugeProps) {
    const percentage = Math.min(150, (current / target) * 100) // Cap at 150% for display
    const displayPercent = Math.round((current / target) * 100)

    // Calculate the angle for the needle (from -135 to 135 degrees = 270 degree arc)
    const angle = -135 + (percentage / 150) * 270

    // Color based on percentage
    const getColor = () => {
        if (percentage < 70) return '#22c55e' // Green - under
        if (percentage < 90) return '#eab308' // Yellow - approaching
        if (percentage <= 110) return '#22c55e' // Green - on target
        if (percentage <= 130) return '#f97316' // Orange - slightly over
        return '#ef4444' // Red - over
    }

    const color = getColor()

    return (
        <div className="relative w-full max-w-xs mx-auto">
            {/* Gauge Background */}
            <svg viewBox="0 0 200 120" className="w-full">
                {/* Background arc */}
                <path
                    d="M 20 100 A 80 80 0 0 1 180 100"
                    fill="none"
                    stroke="#e5e7eb"
                    strokeWidth="16"
                    strokeLinecap="round"
                />

                {/* Colored progress arc - using gradient stops */}
                <defs>
                    <linearGradient id="gaugeGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                        <stop offset="0%" stopColor="#22c55e" />
                        <stop offset="50%" stopColor="#eab308" />
                        <stop offset="75%" stopColor="#f97316" />
                        <stop offset="100%" stopColor="#ef4444" />
                    </linearGradient>
                </defs>

                {/* Progress arc */}
                <path
                    d="M 20 100 A 80 80 0 0 1 180 100"
                    fill="none"
                    stroke="url(#gaugeGradient)"
                    strokeWidth="16"
                    strokeLinecap="round"
                    strokeDasharray={`${(percentage / 150) * 251.2} 251.2`}
                />

                {/* Needle */}
                <g transform={`rotate(${angle}, 100, 100)`}>
                    <line
                        x1="100"
                        y1="100"
                        x2="100"
                        y2="35"
                        stroke={color}
                        strokeWidth="3"
                        strokeLinecap="round"
                    />
                    <circle cx="100" cy="100" r="8" fill={color} />
                    <circle cx="100" cy="100" r="4" fill="white" />
                </g>

                {/* Scale labels */}
                <text x="15" y="115" fontSize="10" fill="#9ca3af">0</text>
                <text x="90" y="20" fontSize="10" fill="#9ca3af">Target</text>
                <text x="175" y="115" fontSize="10" fill="#9ca3af">150%</text>
            </svg>

            {/* Center display */}
            <div className="absolute bottom-0 left-0 right-0 text-center pb-2">
                <div className="text-4xl font-bold" style={{ color }}>
                    {current.toLocaleString()}
                </div>
                <div className="text-sm text-gray-500">
                    / {target.toLocaleString()} kcal
                </div>
                <div className="text-xs text-gray-400 mt-1">
                    {label} • {displayPercent}%
                </div>
            </div>
        </div>
    )
}
