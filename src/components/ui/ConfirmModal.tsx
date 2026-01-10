'use client'

import { useEffect, useState } from 'react'

interface ConfirmModalProps {
    isOpen: boolean
    title: string
    message: string
    confirmText?: string
    cancelText?: string
    onConfirm: () => void
    onCancel: () => void
    isLoading?: boolean
    icon?: string
    variant?: 'danger' | 'warning' | 'info'
}

export default function ConfirmModal({
    isOpen,
    title,
    message,
    confirmText = 'Confirm',
    cancelText = 'Cancel',
    onConfirm,
    onCancel,
    isLoading = false,
    icon = '🗑️',
    variant = 'danger',
}: ConfirmModalProps) {
    const [animationState, setAnimationState] = useState<'entering' | 'visible' | 'exiting' | 'hidden'>('hidden')

    useEffect(() => {
        if (isOpen) {
            setAnimationState('entering')
            document.body.style.overflow = 'hidden'
            // Transition to visible after animation starts
            const timer = setTimeout(() => setAnimationState('visible'), 50)
            return () => clearTimeout(timer)
        } else if (animationState !== 'hidden') {
            setAnimationState('exiting')
            const timer = setTimeout(() => {
                setAnimationState('hidden')
                document.body.style.overflow = 'unset'
            }, 250)
            return () => clearTimeout(timer)
        }
    }, [isOpen])

    useEffect(() => {
        return () => {
            document.body.style.overflow = 'unset'
        }
    }, [])

    const handleCancel = () => {
        if (isLoading) return
        onCancel()
    }

    if (animationState === 'hidden' && !isOpen) return null

    const variantStyles = {
        danger: {
            iconBg: 'from-red-100 via-rose-100 to-orange-100',
            iconShadow: 'shadow-red-200/50',
            buttonBg: 'from-red-500 via-rose-500 to-red-600',
            buttonHover: 'hover:from-red-600 hover:via-rose-600 hover:to-red-700',
            buttonShadow: 'shadow-red-500/30 hover:shadow-red-500/40',
        },
        warning: {
            iconBg: 'from-amber-100 via-yellow-100 to-orange-100',
            iconShadow: 'shadow-amber-200/50',
            buttonBg: 'from-amber-500 via-orange-500 to-amber-600',
            buttonHover: 'hover:from-amber-600 hover:via-orange-600 hover:to-amber-700',
            buttonShadow: 'shadow-amber-500/30 hover:shadow-amber-500/40',
        },
        info: {
            iconBg: 'from-blue-100 via-indigo-100 to-purple-100',
            iconShadow: 'shadow-blue-200/50',
            buttonBg: 'from-blue-500 via-indigo-500 to-blue-600',
            buttonHover: 'hover:from-blue-600 hover:via-indigo-600 hover:to-blue-700',
            buttonShadow: 'shadow-blue-500/30 hover:shadow-blue-500/40',
        },
    }

    const styles = variantStyles[variant]

    return (
        <div
            className={`fixed inset-0 z-[100] flex items-center justify-center p-4 ${animationState === 'entering' || animationState === 'visible'
                    ? 'modal-backdrop-enter'
                    : 'modal-backdrop-exit'
                }`}
            style={{ backgroundColor: 'rgba(0, 0, 0, 0.4)' }}
            onClick={handleCancel}
        >
            <div
                className={`w-full max-w-sm overflow-hidden rounded-3xl ${animationState === 'entering' || animationState === 'visible'
                        ? 'modal-content-enter'
                        : 'modal-content-exit'
                    }`}
                style={{
                    background: 'rgba(255, 255, 255, 0.85)',
                    backdropFilter: 'blur(24px) saturate(180%)',
                    WebkitBackdropFilter: 'blur(24px) saturate(180%)',
                    border: '1px solid rgba(255, 255, 255, 0.5)',
                    boxShadow: `
                        0 25px 50px -12px rgba(0, 0, 0, 0.25),
                        0 0 0 1px rgba(255, 255, 255, 0.2) inset,
                        0 0 60px rgba(255, 255, 255, 0.15) inset
                    `,
                }}
                onClick={(e) => e.stopPropagation()}
            >
                {/* Gradient overlay for glass effect */}
                <div className="absolute inset-0 bg-gradient-to-br from-white/40 via-transparent to-gray-50/30 pointer-events-none rounded-3xl" />

                {/* Icon with enhanced animation */}
                <div className="relative pt-8 pb-4 flex justify-center">
                    <div
                        className={`w-18 h-18 rounded-2xl bg-gradient-to-br ${styles.iconBg} flex items-center justify-center text-4xl shadow-lg ${styles.iconShadow} transform transition-transform duration-300 hover:scale-110`}
                        style={{ width: '72px', height: '72px' }}
                    >
                        {icon}
                    </div>
                </div>

                {/* Content */}
                <div className="relative px-6 pb-6 text-center">
                    <h3 className="text-xl font-bold text-gray-900 mb-2">{title}</h3>
                    <p className="text-gray-500 text-sm leading-relaxed">{message}</p>
                </div>

                {/* Actions with glass effect */}
                <div className="relative px-6 pb-6 flex gap-3">
                    <button
                        onClick={handleCancel}
                        disabled={isLoading}
                        className="flex-1 px-4 py-3.5 bg-white/60 backdrop-blur-sm text-gray-700 font-semibold rounded-xl border border-gray-200/50 hover:bg-white/80 hover:border-gray-300/50 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm hover:shadow-md"
                    >
                        {cancelText}
                    </button>
                    <button
                        onClick={onConfirm}
                        disabled={isLoading}
                        className={`flex-1 px-4 py-3.5 bg-gradient-to-r ${styles.buttonBg} text-white font-semibold rounded-xl ${styles.buttonHover} transition-all duration-200 shadow-lg ${styles.buttonShadow} hover:-translate-y-0.5 hover:shadow-xl disabled:opacity-50 disabled:hover:translate-y-0 disabled:cursor-not-allowed`}
                    >
                        {isLoading ? (
                            <span className="flex items-center justify-center gap-2">
                                <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                处理中...
                            </span>
                        ) : (
                            confirmText
                        )}
                    </button>
                </div>
            </div>
        </div>
    )
}
