'use client'

import { useState } from 'react'
import Link from 'next/link'
import AccountModal from '../account/AccountModal'

interface AccountSectionProps {
    userEmail: string
}

export default function AccountSection({ userEmail }: AccountSectionProps) {
    const [isAccountModalOpen, setIsAccountModalOpen] = useState(false)

    return (
        <>
            <div
                className="mt-8 bg-white/15 backdrop-blur-2xl rounded-xl border border-white/20 p-6 transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl hover:bg-white/20 cursor-pointer group"
                onClick={() => setIsAccountModalOpen(true)}
            >
                <h3 className="font-semibold text-gray-900 mb-3 flex items-center gap-2">
                    <span className="text-xl">👤</span> Account
                    <span className="ml-auto text-sm text-gray-400 group-hover:text-blue-500 transition-colors">
                        Click to manage →
                    </span>
                </h3>
                <div className="flex justify-between items-center">
                    <div>
                        <p className="text-gray-600 text-sm">Signed in as</p>
                        <p className="font-medium text-gray-900">{userEmail}</p>
                    </div>
                    <Link
                        href="/auth/signout"
                        onClick={(e) => e.stopPropagation()}
                        className="px-4 py-2 text-red-600 hover:bg-red-50 rounded-lg font-medium transition"
                    >
                        Sign Out
                    </Link>
                </div>
            </div>

            <AccountModal
                isOpen={isAccountModalOpen}
                onClose={() => setIsAccountModalOpen(false)}
                userEmail={userEmail}
            />
        </>
    )
}
