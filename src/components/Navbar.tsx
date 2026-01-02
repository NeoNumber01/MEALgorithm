'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'

export default function Navbar({ userEmail }: { userEmail?: string | null }) {
    const pathname = usePathname()

    const navLinks = [
        { name: 'Dashboard', href: '/dashboard' },
        { name: 'Log Meal', href: '/log' },
        { name: 'Suggestions', href: '/recommendations' },
        { name: 'Settings', href: '/settings' },
    ]

    return (
        <nav className="bg-white/70 backdrop-blur-lg border-b border-gray-200/50 sticky top-0 z-50 transition-all">
            <div className="max-w-6xl mx-auto px-4">
                <div className="flex justify-between h-16">
                    <div className="flex">
                        {/* Logo */}
                        <div className="flex-shrink-0 flex items-center">
                            <Link href="/" className="text-xl font-bold bg-gradient-to-r from-cyan-500 via-sky-500 to-lime-500 bg-clip-text text-transparent">
                                MEALgorithm
                            </Link>
                        </div>

                        {/* Desktop Nav Links */}
                        <div className="hidden sm:ml-8 sm:flex sm:space-x-8">
                            {navLinks.map((link) => (
                                <Link
                                    key={link.href}
                                    href={link.href}
                                    className={`inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors ${pathname === link.href
                                        ? 'border-blue-500 text-gray-900'
                                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
                                        }`}
                                >
                                    {link.name}
                                </Link>
                            ))}
                        </div>
                    </div>

                    <div className="flex items-center gap-4">
                        {userEmail && (
                            <span className="hidden md:block text-sm text-gray-500">
                                {userEmail}
                            </span>
                        )}
                        <form action="/auth/signout" method="post">
                            <button className="text-sm font-medium text-red-600 hover:text-red-800 transition-colors">
                                Sign Out
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </nav>
    )
}
