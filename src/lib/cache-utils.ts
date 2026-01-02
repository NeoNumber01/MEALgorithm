export const CACHE_KEYS = {
    LAST_DB_UPDATE: 'meal_db_last_update',
    DASHBOARD_TODAY: 'dashboard_today_data',
    DASHBOARD_TARGETS: 'dashboard_targets',
    DASHBOARD_FEEDBACK: 'dashboard_feedback',
    DASHBOARD_TIMESTAMP: 'dashboard_timestamp',
}

export function notifyDataUpdated() {
    if (typeof window === 'undefined') return
    localStorage.setItem(CACHE_KEYS.LAST_DB_UPDATE, Date.now().toString())
}

export function getLastDataUpdateTime(): number {
    if (typeof window === 'undefined') return 0
    const stored = localStorage.getItem(CACHE_KEYS.LAST_DB_UPDATE)
    return stored ? parseInt(stored) : 0
}

export function clearDashboardCache() {
    if (typeof window === 'undefined') return
    localStorage.removeItem(CACHE_KEYS.DASHBOARD_TODAY)
    localStorage.removeItem(CACHE_KEYS.DASHBOARD_TIMESTAMP)
}
