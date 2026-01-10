'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useState } from 'react'
import AccountModal from './account/AccountModal'

export default function Navbar({ userEmail }: { userEmail?: string | null }) {
    const pathname = usePathname()
    const [hoveredLink, setHoveredLink] = useState<string | null>(null)
    const [isAccountModalOpen, setIsAccountModalOpen] = useState(false)

    const navLinks = [
        { name: 'Dashboard', href: '/dashboard' },
        { name: 'Log Meal', href: '/log' },
        { name: 'Suggestions', href: '/recommendations' },
        { name: 'Settings', href: '/settings' },
    ]

    return (
        <>
            <nav className="bg-white/70 backdrop-blur-lg border-b border-gray-200/50 sticky top-0 z-50 transition-all duration-500 ease-out">
                <div className="max-w-6xl mx-auto px-4">
                    <div className="flex justify-between h-16">
                        <div className="flex">
                            {/* Logo - with left margin to avoid fullscreen button */}
                            <div className="flex-shrink-0 flex items-center ml-12">
                                <Link
                                    href="/"
                                    className="text-xl font-bold bg-gradient-to-r from-cyan-500 via-sky-500 to-lime-500 bg-clip-text text-transparent
                                        transition-all duration-300 hover:scale-105 hover:from-cyan-400 hover:via-sky-400 hover:to-lime-400"
                                >
                                    MEALgorithm
                                </Link>
                            </div>

                            {/* Desktop Nav Links */}
                            <div className="hidden sm:ml-8 sm:flex sm:space-x-8">
                                {navLinks.map((link) => (
                                    <Link
                                        key={link.href}
                                        href={link.href}
                                        onMouseEnter={() => setHoveredLink(link.href)}
                                        onMouseLeave={() => setHoveredLink(null)}
                                        className={`
                                            relative inline-flex items-center px-1 pt-1 text-sm font-medium 
                                            transition-all duration-300 ease-out
                                            ${pathname === link.href
                                                ? 'text-gray-900'
                                                : 'text-gray-500 hover:text-gray-700'
                                            }
                                        `}
                                    >
                                        {link.name}
                                        {/* Animated underline */}
                                        <span
                                            className={`
                                                absolute bottom-0 left-0 h-0.5 bg-gradient-to-r from-cyan-500 to-lime-500
                                                transition-all duration-300 ease-out
                                                ${pathname === link.href
                                                    ? 'w-full'
                                                    : hoveredLink === link.href
                                                        ? 'w-full opacity-50'
                                                        : 'w-0'
                                                }
                                            `}
                                        />
                                    </Link>
                                ))}
                            </div>
                        </div>

                        <div className="flex items-center gap-4">
                            {userEmail && (
                                <button
                                    onClick={() => setIsAccountModalOpen(true)}
                                    className="hidden md:block text-sm text-gray-500 transition-all duration-300 hover:text-blue-600 hover:underline cursor-pointer"
                                >
                                    {userEmail}
                                </button>
                            )}
                            <form action="/auth/signout" method="post">
                                <button className="
                                    text-sm font-medium text-red-600 
                                    transition-all duration-300 ease-out
                                    hover:text-red-800 hover:scale-105
                                    active:scale-95
                                ">
                                    Sign Out
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            </nav>

            {/* Account Modal */}
            {userEmail && (
                <AccountModal
                    isOpen={isAccountModalOpen}
                    onClose={() => setIsAccountModalOpen(false)}
                    userEmail={userEmail}
                />
            )}
        </>
    )
}
