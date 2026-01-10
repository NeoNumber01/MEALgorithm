'use client'

import { useState, useEffect } from 'react'
import { getPreferences, updatePreferences } from '@/lib/preferences/actions'

interface PreferencesModalProps {
    isOpen: boolean
    onClose: () => void
}

export default function PreferencesModal({ isOpen, onClose }: PreferencesModalProps) {
    const [preferences, setPreferences] = useState('')
    const [dislikes, setDislikes] = useState('')
    const [restrictions, setRestrictions] = useState('')
    const [customNotes, setCustomNotes] = useState('')
    const [saving, setSaving] = useState(false)
    const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

    useEffect(() => {
        if (isOpen) {
            loadPreferences()
        }
    }, [isOpen])

    const loadPreferences = async () => {
        const result = await getPreferences()
        if (!('error' in result)) {
            setPreferences(result.preferences)
            setDislikes(result.dislikes)
            setRestrictions(result.restrictions)
            setCustomNotes(result.customNotes)
        }
    }

    const handleSave = async () => {
        setSaving(true)
        setMessage(null)

        const result = await updatePreferences({
            food_preferences: preferences,
            food_dislikes: dislikes,
            dietary_restrictions: restrictions,
            custom_notes: customNotes,
        })

        if ('error' in result) {
            setMessage({ type: 'error', text: result.error || 'Failed to save' })
        } else {
            setMessage({ type: 'success', text: 'Saved successfully!' })
        }

        setSaving(false)
    }

    if (!isOpen) return null

    return (
        <>
            {/* Backdrop with enhanced blur */}
            <div
                className="fixed inset-0 z-50 modal-backdrop-enter"
                style={{ backgroundColor: 'rgba(0, 0, 0, 0.4)' }}
                onClick={onClose}
            />

            {/* Modal */}
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4 pointer-events-none">
                <div
                    className="relative modal-content-enter rounded-3xl w-full max-w-lg max-h-[90vh] overflow-hidden pointer-events-auto"
                    style={{
                        background: 'rgba(255, 255, 255, 0.88)',
                        backdropFilter: 'blur(24px) saturate(180%)',
                        WebkitBackdropFilter: 'blur(24px) saturate(180%)',
                        border: '1px solid rgba(255, 255, 255, 0.5)',
                        boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25), 0 0 40px rgba(16, 185, 129, 0.15), inset 0 0 80px rgba(255, 255, 255, 0.2)'
                    }}
                    onClick={(e) => e.stopPropagation()}
                >
                    {/* Glassmorphism gradient overlay */}
                    <div className="absolute inset-0 bg-gradient-to-br from-white/30 via-transparent to-emerald-50/20 pointer-events-none rounded-3xl" />

                    {/* Header with enhanced gradient */}
                    <div className="relative bg-gradient-to-r from-emerald-500 via-teal-500 to-cyan-500 px-6 py-5 text-white">
                        <div className="absolute inset-0 bg-white/10 backdrop-blur-sm" />
                        <div className="relative flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="w-12 h-12 rounded-2xl bg-white/20 backdrop-blur-sm flex items-center justify-center text-2xl shadow-lg border border-white/30">
                                    🍽️
                                </div>
                                <div>
                                    <h2 className="text-xl font-bold drop-shadow-sm">Food Preferences</h2>
                                    <p className="text-emerald-100 text-sm">Personalize your meal suggestions</p>
                                </div>
                            </div>
                            <button
                                onClick={onClose}
                                className="w-10 h-10 rounded-full bg-white/20 hover:bg-white/30 backdrop-blur-sm flex items-center justify-center transition-all duration-200 hover:scale-110 border border-white/30 hover:border-white/50 shadow-lg"
                            >
                                ✕
                            </button>
                        </div>
                    </div>

                    {/* Content with glass effect */}
                    <div className="relative p-6 overflow-y-auto max-h-[calc(90vh-180px)]">
                        {message && (
                            <div className={`mb-4 p-3 rounded-xl text-sm font-medium backdrop-blur-sm ${message.type === 'success'
                                ? 'bg-green-100/80 text-green-800 border border-green-200/50'
                                : 'bg-red-100/80 text-red-800 border border-red-200/50'
                                }`}>
                                {message.type === 'success' ? '✅' : '❌'} {message.text}
                            </div>
                        )}

                        <div className="space-y-5">
                            <div className="group">
                                <label className="block text-sm font-semibold text-gray-700 mb-2 flex items-center gap-2">
                                    <span className="text-lg drop-shadow">❤️</span> Foods I Love
                                </label>
                                <textarea
                                    value={preferences}
                                    onChange={(e) => setPreferences(e.target.value)}
                                    placeholder="e.g., Chicken wings, spicy food, Japanese cuisine, avocado toast, pasta..."
                                    className="w-full p-4 border border-white/50 rounded-xl text-sm resize-none focus:ring-2 focus:ring-emerald-400 focus:border-transparent transition-all duration-200 bg-white/50 backdrop-blur-sm hover:bg-white/70 shadow-sm hover:shadow-md placeholder:text-gray-400"
                                    rows={2}
                                />
                            </div>

                            <div className="group">
                                <label className="block text-sm font-semibold text-gray-700 mb-2 flex items-center gap-2">
                                    <span className="text-lg drop-shadow">👎</span> Foods I Dislike
                                </label>
                                <textarea
                                    value={dislikes}
                                    onChange={(e) => setDislikes(e.target.value)}
                                    placeholder="e.g., Cilantro, raw onions, very sour foods, liver..."
                                    className="w-full p-4 border border-white/50 rounded-xl text-sm resize-none focus:ring-2 focus:ring-emerald-400 focus:border-transparent transition-all duration-200 bg-white/50 backdrop-blur-sm hover:bg-white/70 shadow-sm hover:shadow-md placeholder:text-gray-400"
                                    rows={2}
                                />
                            </div>

                            <div className="group">
                                <label className="block text-sm font-semibold text-gray-700 mb-2 flex items-center gap-2">
                                    <span className="text-lg drop-shadow">⚠️</span> Dietary Restrictions
                                </label>
                                <textarea
                                    value={restrictions}
                                    onChange={(e) => setRestrictions(e.target.value)}
                                    placeholder="e.g., Vegetarian, Gluten-free, Lactose intolerant, Nut allergy..."
                                    className="w-full p-4 border border-white/50 rounded-xl text-sm resize-none focus:ring-2 focus:ring-emerald-400 focus:border-transparent transition-all duration-200 bg-white/50 backdrop-blur-sm hover:bg-white/70 shadow-sm hover:shadow-md placeholder:text-gray-400"
                                    rows={2}
                                />
                            </div>

                            <div className="group">
                                <label className="block text-sm font-semibold text-gray-700 mb-2 flex items-center gap-2">
                                    <span className="text-lg drop-shadow">💬</span> Special Requests
                                </label>
                                <textarea
                                    value={customNotes}
                                    onChange={(e) => setCustomNotes(e.target.value)}
                                    placeholder="e.g., I want healthier eating, more variety, help me lose weight, quick recipes..."
                                    className="w-full p-4 border border-white/50 rounded-xl text-sm resize-none focus:ring-2 focus:ring-emerald-400 focus:border-transparent transition-all duration-200 bg-white/50 backdrop-blur-sm hover:bg-white/70 shadow-sm hover:shadow-md placeholder:text-gray-400"
                                    rows={3}
                                />
                                <p className="text-xs text-gray-500 mt-2 ml-1">Write anything you want the AI to consider when generating suggestions</p>
                            </div>
                        </div>
                    </div>

                    {/* Footer with glass effect */}
                    <div className="relative px-6 py-4 border-t border-white/30 bg-white/30 backdrop-blur-sm flex gap-3">
                        <button
                            onClick={onClose}
                            className="flex-1 py-3 px-4 border border-gray-300/70 text-gray-600 rounded-xl font-medium hover:bg-white/50 transition-all duration-200 backdrop-blur-sm"
                        >
                            Cancel
                        </button>
                        <button
                            onClick={handleSave}
                            disabled={saving}
                            className="flex-1 py-3 px-4 bg-gradient-to-r from-emerald-500 via-teal-500 to-cyan-500 text-white rounded-xl font-semibold hover:from-emerald-600 hover:via-teal-600 hover:to-cyan-600 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 shadow-lg hover:shadow-xl hover:-translate-y-0.5 border border-white/20"
                        >
                            {saving ? (
                                <span className="flex items-center justify-center gap-2">
                                    <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                    Saving...
                                </span>
                            ) : (
                                '💾 Save Preferences'
                            )}
                        </button>
                    </div>
                </div>
            </div>
        </>
    )
}
