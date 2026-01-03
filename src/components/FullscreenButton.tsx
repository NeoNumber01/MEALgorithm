'use client'

import { useState, useEffect, useCallback } from 'react'
import { Maximize2, Minimize2 } from 'lucide-react'

// Declare the electron API type
declare global {
    interface Window {
        electronAPI?: {
            toggleFullscreen: () => Promise<boolean>;
            exitFullscreen: () => Promise<boolean>;
            getFullscreenState: () => Promise<boolean>;
            onFullscreenChange: (callback: (isFullscreen: boolean) => void) => void;
            removeFullscreenListener: () => void;
        }
    }
}

export default function FullscreenButton() {
    const [isFullscreen, setIsFullscreen] = useState(false)
    const [isElectron, setIsElectron] = useState(false)
    const [isHovered, setIsHovered] = useState(false)
    const [isTransitioning, setIsTransitioning] = useState(false)

    // Handle ESC key to exit fullscreen
    const handleKeyDown = useCallback((event: KeyboardEvent) => {
        if (event.key === 'Escape' && isFullscreen && window.electronAPI) {
            event.preventDefault()
            setIsTransitioning(true)
            setTimeout(() => {
                window.electronAPI?.exitFullscreen()
            }, 150)
        }
    }, [isFullscreen])

    useEffect(() => {
        // Check if running in Electron
        if (typeof window !== 'undefined' && window.electronAPI) {
            setIsElectron(true)
            // Get initial fullscreen state
            window.electronAPI.getFullscreenState().then(setIsFullscreen)
            
            // Listen for fullscreen changes from main process
            window.electronAPI.onFullscreenChange((newState) => {
                // Delay state update slightly for smoother transition
                setTimeout(() => {
                    setIsFullscreen(newState)
                    setIsTransitioning(false)
                }, 100)
            })
        }

        // Add ESC key listener
        window.addEventListener('keydown', handleKeyDown)

        return () => {
            window.removeEventListener('keydown', handleKeyDown)
            if (window.electronAPI?.removeFullscreenListener) {
                window.electronAPI.removeFullscreenListener()
            }
        }
    }, [handleKeyDown])

    const toggleFullscreen = async () => {
        if (window.electronAPI && !isTransitioning) {
            setIsTransitioning(true)
            // Small delay before triggering fullscreen for smoother transition
            setTimeout(async () => {
                await window.electronAPI!.toggleFullscreen()
                // State will be updated via the fullscreen-change event
            }, 150)
        }
    }

    // Don't render if not in Electron
    if (!isElectron) return null

    return (
        <>
            {/* Fullscreen transition overlay */}
            <div 
                className={`
                    fixed inset-0 z-[9998] pointer-events-none
                    bg-white
                    transition-opacity duration-300 ease-in-out
                    ${isTransitioning ? 'opacity-100' : 'opacity-0'}
                `}
            />
            
            <button
                onClick={toggleFullscreen}
                onMouseEnter={() => setIsHovered(true)}
                onMouseLeave={() => setIsHovered(false)}
                disabled={isTransitioning}
                className={`
                    fixed top-4 left-4 z-[9999]
                    w-10 h-10 rounded-full
                    flex items-center justify-center
                    transition-all duration-500 ease-out
                    ${isTransitioning ? 'opacity-50 cursor-wait' : ''}
                    ${isHovered && !isTransitioning
                        ? 'bg-gradient-to-r from-cyan-500 to-lime-500 shadow-lg shadow-cyan-500/30 scale-110' 
                        : 'bg-white/80 backdrop-blur-sm shadow-md hover:shadow-lg'
                    }
                    border border-gray-200/50
                    group
                `}
                title={isFullscreen ? '退出全屏 (ESC)' : '全屏'}
            >
                <div className={`
                    transition-all duration-300 ease-out
                    ${isHovered && !isTransitioning ? 'text-white' : 'text-gray-600'}
                `}>
                    {isFullscreen ? (
                        <Minimize2 
                            size={18} 
                            className={`transition-transform duration-300 ${isHovered ? 'scale-110' : ''}`}
                        />
                    ) : (
                        <Maximize2 
                            size={18}
                            className={`transition-transform duration-300 ${isHovered ? 'scale-110' : ''}`}
                        />
                    )}
                </div>
            </button>
        </>
    )
}
