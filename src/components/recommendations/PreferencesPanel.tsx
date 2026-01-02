'use client'

import { useState, useEffect } from 'react'
import { getPreferences, updatePreferences } from '@/lib/preferences/actions'

export default function PreferencesPanel({ onUpdate }: { onUpdate?: () => void }) {
    const [preferences, setPreferences] = useState('')
    const [dislikes, setDislikes] = useState('')
    const [restrictions, setRestrictions] = useState('')
    const [customNotes, setCustomNotes] = useState('')
    const [saving, setSaving] = useState(false)
    const [expanded, setExpanded] = useState(false)
    const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

    useEffect(() => {
        loadPreferences()
    }, [])

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
            setMessage({ type: 'success', text: 'Preferences saved! Regenerate suggestions to apply.' })
            if (onUpdate) onUpdate()
        }

        setSaving(false)
    }

    return (
        <div className="bg-white/15 backdrop-blur-2xl border border-white/20 rounded-xl overflow-hidden mb-6 transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20">
            <button
                onClick={() => setExpanded(!expanded)}
                className="w-full px-6 py-4 flex justify-between items-center hover:bg-white/10 transition"
            >
                <div className="flex items-center gap-3">
                    <span className="text-2xl">🍽️</span>
                    <div className="text-left">
                        <h3 className="font-semibold text-gray-900">Food Preferences</h3>
                        <p className="text-sm text-gray-500">
                            {preferences || dislikes || restrictions
                                ? 'Click to edit your preferences'
                                : 'Tell us what you like and don\'t like'}
                        </p>
                    </div>
                </div>
                <span className={`transition-transform ${expanded ? 'rotate-180' : ''}`}>
                    ▼
                </span>
            </button>

            {expanded && (
                <div className="px-6 pb-6 border-t">
                    {message && (
                        <div className={`mt-4 p-3 rounded-lg text-sm ${message.type === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                            }`}>
                            {message.text}
                        </div>
                    )}

                    <div className="mt-4 space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">
                                ❤️ Foods I Love
                            </label>
                            <textarea
                                value={preferences}
                                onChange={(e) => setPreferences(e.target.value)}
                                placeholder="e.g., I love chicken wings, spicy food, Japanese cuisine, avocado toast..."
                                className="w-full p-3 border rounded-lg text-sm resize-none"
                                rows={2}
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">
                                👎 Foods I Dislike
                            </label>
                            <textarea
                                value={dislikes}
                                onChange={(e) => setDislikes(e.target.value)}
                                placeholder="e.g., I don't like cilantro, raw onions, very sour foods..."
                                className="w-full p-3 border rounded-lg text-sm resize-none"
                                rows={2}
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">
                                ⚠️ Dietary Restrictions
                            </label>
                            <textarea
                                value={restrictions}
                                onChange={(e) => setRestrictions(e.target.value)}
                                placeholder="e.g., Vegetarian, Gluten-free, Lactose intolerant, Nut allergy..."
                                className="w-full p-3 border rounded-lg text-sm resize-none"
                                rows={2}
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">
                                💬 Special Requests
                            </label>
                            <textarea
                                value={customNotes}
                                onChange={(e) => setCustomNotes(e.target.value)}
                                placeholder="e.g., I want healthier eating, more variety, help me lose weight, suggest meals I can cook quickly..."
                                className="w-full p-3 border rounded-lg text-sm resize-none"
                                rows={3}
                            />
                            <p className="text-xs text-gray-400 mt-1">Write anything you want the AI to consider</p>
                        </div>

                        <button
                            onClick={handleSave}
                            disabled={saving}
                            className="w-full py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 transition"
                        >
                            {saving ? 'Saving...' : 'Save Preferences'}
                        </button>
                    </div>
                </div>
            )}
        </div>
    )
}
