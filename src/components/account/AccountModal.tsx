'use client'

import { useState, useEffect, useRef } from 'react'
import { updateUserEmail, deleteAccount, getUserDisplayInfo, updateDisplayName } from '@/lib/profile/account-actions'

interface AccountModalProps {
    isOpen: boolean
    onClose: () => void
    userEmail: string
}

type TabType = 'profile' | 'security' | 'danger'

export default function AccountModal({ isOpen, onClose, userEmail }: AccountModalProps) {
    const [activeTab, setActiveTab] = useState<TabType>('profile')
    const [loading, setLoading] = useState(false)
    const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)
    const dialogRef = useRef<HTMLDialogElement>(null)

    // Profile tab state
    const [displayName, setDisplayName] = useState('')
    const [originalDisplayName, setOriginalDisplayName] = useState('')

    // Security tab state
    const [newEmail, setNewEmail] = useState('')

    // Danger tab state
    const [confirmEmail, setConfirmEmail] = useState('')
    const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)

    useEffect(() => {
        if (isOpen) {
            dialogRef.current?.showModal()
            loadUserInfo()
        } else {
            dialogRef.current?.close()
        }
    }, [isOpen])

    useEffect(() => {
        const dialog = dialogRef.current
        if (!dialog) return

        const handleKeyDown = (e: KeyboardEvent) => {
            if (e.key === 'Escape') {
                onClose()
            }
        }

        dialog.addEventListener('keydown', handleKeyDown)
        return () => dialog.removeEventListener('keydown', handleKeyDown)
    }, [onClose])

    const loadUserInfo = async () => {
        const result = await getUserDisplayInfo()
        if (!('error' in result) && result.displayName) {
            setDisplayName(result.displayName)
            setOriginalDisplayName(result.displayName)
        }
    }

    const handleBackdropClick = (e: React.MouseEvent<HTMLDialogElement>) => {
        if (e.target === dialogRef.current) {
            onClose()
        }
    }

    const handleSaveProfile = async () => {
        if (displayName === originalDisplayName) return

        setLoading(true)
        setMessage(null)

        const result = await updateDisplayName(displayName)

        if ('error' in result && result.error) {
            setMessage({ type: 'error', text: result.error })
        } else {
            setMessage({ type: 'success', text: 'Profile saved successfully!' })
            setOriginalDisplayName(displayName)
        }

        setLoading(false)
    }

    const handleUpdateEmail = async () => {
        if (!newEmail || newEmail === userEmail) {
            setMessage({ type: 'error', text: 'Please enter a new email address' })
            return
        }

        setLoading(true)
        setMessage(null)

        const result = await updateUserEmail(newEmail)

        if ('error' in result && result.error) {
            setMessage({ type: 'error', text: result.error })
        } else {
            setMessage({ type: 'success', text: 'Verification email sent! Please check your inbox and click the confirmation link.' })
            setNewEmail('')
        }

        setLoading(false)
    }

    const handleDeleteAccount = async () => {
        if (confirmEmail !== userEmail) {
            setMessage({ type: 'error', text: 'Email address does not match' })
            return
        }

        setLoading(true)
        setMessage(null)

        const result = await deleteAccount()

        if ('error' in result && result.error) {
            setMessage({ type: 'error', text: result.error })
            setLoading(false)
        } else {
            // Clear all local storage to remove cached data (dashboard, stats, etc.)
            localStorage.clear()
            // Redirect to login page after successful deletion
            window.location.href = '/login'
        }
    }

    const tabs = [
        { id: 'profile' as TabType, name: '👤 Profile', icon: '👤' },
        { id: 'security' as TabType, name: '🔐 Security', icon: '🔐' },
        { id: 'danger' as TabType, name: '⚠️ Danger Zone', icon: '⚠️' },
    ]

    if (!isOpen) return null

    return (
        <dialog
            ref={dialogRef}
            onClick={handleBackdropClick}
            className="fixed inset-0 z-50 bg-transparent p-0 m-0 max-w-none max-h-none w-full h-full modal-backdrop-enter backdrop:bg-black/40 backdrop:backdrop-blur-md"
        >
            <div className="flex items-center justify-center min-h-full p-4">
                <div
                    className="modal-content-enter rounded-3xl w-full max-w-lg overflow-hidden relative"
                    style={{
                        background: 'rgba(255, 255, 255, 0.8)',
                        backdropFilter: 'blur(24px) saturate(180%)',
                        WebkitBackdropFilter: 'blur(24px) saturate(180%)',
                        border: '1px solid rgba(255, 255, 255, 0.4)',
                        boxShadow: `
                            0 25px 50px -12px rgba(0, 0, 0, 0.25),
                            0 0 0 1px rgba(255, 255, 255, 0.15) inset,
                            0 0 60px rgba(255, 255, 255, 0.1) inset
                        `,
                    }}
                >
                    {/* Gradient overlay for glass effect */}
                    <div className="absolute inset-0 bg-gradient-to-br from-white/30 via-transparent to-blue-50/20 pointer-events-none rounded-3xl" />

                    {/* Header */}
                    <div className="relative px-6 py-5 border-b border-white/30 flex justify-between items-center bg-gradient-to-r from-blue-500/15 via-purple-500/10 to-pink-500/10">
                        <h2 className="text-xl font-bold text-gray-900">Account Settings</h2>
                        <button
                            onClick={onClose}
                            className="w-10 h-10 rounded-full bg-white/40 backdrop-blur-sm hover:bg-white/60 text-gray-500 hover:text-gray-700 flex items-center justify-center transition-all duration-200 text-xl border border-white/30 hover:border-gray-200/50 shadow-sm hover:shadow-md"
                        >
                            ×
                        </button>
                    </div>

                    {/* Tabs */}
                    <div className="relative flex border-b border-white/30 bg-white/20">
                        {tabs.map((tab) => (
                            <button
                                key={tab.id}
                                onClick={() => {
                                    setActiveTab(tab.id)
                                    setMessage(null)
                                    setShowDeleteConfirm(false)
                                }}
                                className={`flex-1 py-3.5 text-sm font-medium transition-all duration-200 ${activeTab === tab.id
                                    ? 'text-blue-600 border-b-2 border-blue-500 bg-white/40'
                                    : 'text-gray-500 hover:text-gray-700 hover:bg-white/30'
                                    }`}
                            >
                                {tab.name}
                            </button>
                        ))}
                    </div>

                    {/* Content */}
                    <div className="relative p-6 min-h-[300px] custom-scrollbar">
                        {message && (
                            <div className={`mb-4 p-3 rounded-xl text-sm font-medium backdrop-blur-sm ${message.type === 'success'
                                ? 'bg-green-100/80 text-green-800 border border-green-200/50'
                                : 'bg-red-100/80 text-red-800 border border-red-200/50'
                                }`}>
                                {message.type === 'success' ? '✅' : '❌'} {message.text}
                            </div>
                        )}

                        {/* Profile Tab */}
                        {activeTab === 'profile' && (
                            <div className="space-y-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        Email Address
                                    </label>
                                    <input
                                        type="email"
                                        value={userEmail}
                                        disabled
                                        className="w-full p-3 border border-gray-200 rounded-lg bg-gray-100 text-gray-500"
                                    />
                                    <p className="text-xs text-gray-400 mt-1">
                                        To change your email, go to &quot;Security&quot; tab
                                    </p>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">
                                        Display Name
                                    </label>
                                    <input
                                        type="text"
                                        value={displayName}
                                        onChange={(e) => setDisplayName(e.target.value)}
                                        placeholder="Enter your display name"
                                        className="w-full p-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                                    />
                                </div>

                                <button
                                    onClick={handleSaveProfile}
                                    disabled={loading || displayName === originalDisplayName}
                                    className="w-full py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                                >
                                    {loading ? 'Saving...' : 'Save Changes'}
                                </button>
                            </div>
                        )}

                        {/* Security Tab */}
                        {activeTab === 'security' && (
                            <div className="space-y-4">
                                <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                                    <h3 className="font-medium text-blue-900 mb-2">📧 Change Email Address</h3>
                                    <p className="text-sm text-blue-700 mb-4">
                                        After updating, a verification link will be sent to your new email. Click the link to complete the change.
                                    </p>

                                    <div className="mb-3">
                                        <label className="block text-sm font-medium text-gray-700 mb-1">
                                            Current Email
                                        </label>
                                        <input
                                            type="email"
                                            value={userEmail}
                                            disabled
                                            className="w-full p-3 border border-gray-200 rounded-lg bg-gray-100 text-gray-500"
                                        />
                                    </div>

                                    <div className="mb-4">
                                        <label className="block text-sm font-medium text-gray-700 mb-1">
                                            New Email Address
                                        </label>
                                        <input
                                            type="email"
                                            value={newEmail}
                                            onChange={(e) => setNewEmail(e.target.value)}
                                            placeholder="Enter new email address"
                                            className="w-full p-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                                        />
                                    </div>

                                    <button
                                        onClick={handleUpdateEmail}
                                        disabled={loading || !newEmail}
                                        className="w-full py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                                    >
                                        {loading ? 'Sending...' : 'Send Verification Email'}
                                    </button>
                                </div>
                            </div>
                        )}

                        {/* Danger Tab */}
                        {activeTab === 'danger' && (
                            <div className="space-y-4">
                                <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                                    <h3 className="font-medium text-red-900 mb-2">🚨 Delete Account</h3>
                                    <p className="text-sm text-red-700 mb-4">
                                        This will permanently delete your account and all associated data, including meal logs and profile information.
                                        <strong className="block mt-2">This action cannot be undone!</strong>
                                    </p>

                                    {!showDeleteConfirm ? (
                                        <button
                                            onClick={() => setShowDeleteConfirm(true)}
                                            className="w-full py-3 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700 transition-all"
                                        >
                                            Delete My Account
                                        </button>
                                    ) : (
                                        <div className="space-y-3 pt-2 border-t border-red-200 mt-4">
                                            <p className="text-sm text-red-800 font-medium">
                                                Please enter your email address to confirm:
                                            </p>
                                            <input
                                                type="email"
                                                value={confirmEmail}
                                                onChange={(e) => setConfirmEmail(e.target.value)}
                                                placeholder={userEmail}
                                                className="w-full p-3 border border-red-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
                                            />
                                            <div className="flex gap-3">
                                                <button
                                                    onClick={() => {
                                                        setShowDeleteConfirm(false)
                                                        setConfirmEmail('')
                                                    }}
                                                    className="flex-1 py-3 bg-gray-200 text-gray-700 rounded-lg font-medium hover:bg-gray-300 transition-all"
                                                >
                                                    Cancel
                                                </button>
                                                <button
                                                    onClick={handleDeleteAccount}
                                                    disabled={loading || confirmEmail !== userEmail}
                                                    className="flex-1 py-3 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                                                >
                                                    {loading ? 'Deleting...' : 'Confirm Delete'}
                                                </button>
                                            </div>
                                        </div>
                                    )}
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </dialog>
    )
}
