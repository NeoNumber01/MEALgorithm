'use client'

import { useEffect, useState } from 'react'
import { formatNumberLocale } from '@/lib/format-utils'

interface CalorieGaugeProps {
    current: number
    target: number
    label?: string
}

export default function CalorieGauge({ current, target, label = "Today's Calories" }: CalorieGaugeProps) {
    // Animation state
    const [animatedPercentage, setAnimatedPercentage] = useState(0)

    useEffect(() => {
        // Simple entry animation
        const percentage = Math.min(100, (current / target) * 100)
        const timer = setTimeout(() => {
            setAnimatedPercentage(percentage)
        }, 100)
        return () => clearTimeout(timer)
    }, [current, target])

    const percentage = Math.min(100, (current / target) * 100)
    // SVG properties
    // SVG properties
    const radius = 80
    const strokeWidth = 12

    // We want a 220-degree arc, from -200deg to -20deg? Or symmetric opening at bottom.
    // Let's do a symmetric arc open at the bottom.
    // Length of the arc
    const arcLength = Math.PI * radius // Semi-circle for now (180 deg) to keep it simple but refine the look
    // A standard semi-circle is 180 degrees. Let's stick to the semi-circle layout but make it look premium.

    // Calculate color based on percentage
    const getStatusColor = () => {
        if (percentage > 110) return "text-red-500"
        if (percentage > 90) return "text-lime-500" // On target
        return "text-cyan-600" // In progress
    }

    const statusColorClass = getStatusColor()

    return (
        <div className="relative w-full max-w-xs mx-auto flex flex-col items-center justify-center">
            <div className="relative w-full aspect-[2/1.2] flex items-end justify-center">
                <svg viewBox="0 0 200 110" className="w-full h-full overflow-visible">
                    {/* Definitions for Gradients and Glows */}
                    <defs>
                        {/* The main progress gradient */}
                        <linearGradient id="progressGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                            <stop offset="0%" stopColor="#06b6d4" />   {/* Cyan-500 */}
                            <stop offset="50%" stopColor="#3b82f6" />   {/* Blue-500 */}
                            <stop offset="100%" stopColor="#84cc16" />  {/* Lime-500 */}
                        </linearGradient>

                        {/* Soft Glow Filter */}
                        <filter id="glow-shadow" x="-50%" y="-50%" width="200%" height="200%">
                            <feGaussianBlur stdDeviation="4" result="coloredBlur" />
                            <feMerge>
                                <feMergeNode in="coloredBlur" />
                                <feMergeNode in="SourceGraphic" />
                            </feMerge>
                        </filter>
                    </defs>

                    {/* Background Track */}
                    <path
                        d="M 20 100 A 80 80 0 0 1 180 100"
                        fill="none"
                        stroke="#e2e8f0" // Slate-200
                        strokeWidth={strokeWidth}
                        strokeLinecap="round"
                        className="opacity-50"
                    />

                    {/* Progress Arc */}
                    <path
                        d="M 20 100 A 80 80 0 0 1 180 100"
                        fill="none"
                        stroke="url(#progressGradient)"
                        strokeWidth={strokeWidth}
                        strokeLinecap="round"
                        strokeDasharray={arcLength}
                        strokeDashoffset={arcLength - (animatedPercentage / 100) * arcLength}
                        filter="url(#glow-shadow)"
                        className="transition-all duration-1000 ease-out"
                        style={{
                            transitionProperty: 'stroke-dashoffset',
                        }}
                    />

                    {/* Tick Marks (Optional Decoration) */}
                    <g className="opacity-30">
                        <line x1="20" y1="100" x2="30" y2="100" stroke="currentColor" strokeWidth="2" />
                        <line x1="180" y1="100" x2="170" y2="100" stroke="currentColor" strokeWidth="2" />
                        <line x1="100" y1="20" x2="100" y2="30" stroke="currentColor" strokeWidth="2" />
                    </g>
                </svg>

                {/* Center Content Overlay */}
                <div className="absolute inset-0 flex flex-col items-center justify-end pb-0">
                    {/* Goal Label */}
                    <div className="text-xs font-semibold text-gray-400 tracking-wider uppercase mb-1">
                        {label}
                    </div>

                    {/* Main Number */}
                    <div className={`text-5xl font-extrabold tracking-tight ${statusColorClass} drop-shadow-sm`}>
                        {formatNumberLocale(current)}
                    </div>

                    {/* Subtext */}
                    <div className="flex items-center gap-2 mt-2 mb-1">
                        <span className="text-sm font-medium text-gray-400">
                            / {formatNumberLocale(target)} kcal
                        </span>
                        <span className={`text-xs font-bold px-2 py-0.5 rounded-full bg-gray-100 ${statusColorClass}`}>
                            {Math.round(percentage)}%
                        </span>
                    </div>
                </div>
            </div>
        </div>
    )
}
