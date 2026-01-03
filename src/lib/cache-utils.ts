export const CACHE_KEYS = {
    LAST_DB_UPDATE: 'meal_db_last_update',
    LAST_GOAL_UPDATE: 'goal_last_update',
    DASHBOARD_TODAY: 'dashboard_today_data',
    DASHBOARD_TARGETS: 'dashboard_targets',
    DASHBOARD_FEEDBACK: 'dashboard_feedback',
    DASHBOARD_TIMESTAMP: 'dashboard_timestamp',
    DASHBOARD_FEEDBACK_HASH: 'dashboard_feedback_hash', // Hash of data used to generate feedback
    STATS_INSIGHT_PREFIX: 'stats_insight_', // Prefix for stats insights
}

export function notifyDataUpdated() {
    if (typeof window === 'undefined') return
    localStorage.setItem(CACHE_KEYS.LAST_DB_UPDATE, Date.now().toString())
}

export function notifyGoalUpdated() {
    if (typeof window === 'undefined') return
    localStorage.setItem(CACHE_KEYS.LAST_GOAL_UPDATE, Date.now().toString())
}

export function getLastDataUpdateTime(): number {
    if (typeof window === 'undefined') return 0
    const stored = localStorage.getItem(CACHE_KEYS.LAST_DB_UPDATE)
    return stored ? parseInt(stored) : 0
}

export function getLastGoalUpdateTime(): number {
    if (typeof window === 'undefined') return 0
    const stored = localStorage.getItem(CACHE_KEYS.LAST_GOAL_UPDATE)
    return stored ? parseInt(stored) : 0
}

export function clearDashboardCache() {
    if (typeof window === 'undefined') return
    localStorage.removeItem(CACHE_KEYS.DASHBOARD_TODAY)
    localStorage.removeItem(CACHE_KEYS.DASHBOARD_TIMESTAMP)
}

// Generate a hash string for comparing if data has changed
// Used to determine if AI feedback needs to be regenerated
export function generateDataHash(data: Record<string, unknown>): string {
    return JSON.stringify(data)
}

// Check if AI feedback should be regenerated based on data changes
export function shouldRegenerateAIFeedback(
    currentDataHash: string, 
    cachedDataHash: string | null,
    lastFeedbackTime: number
): boolean {
    if (typeof window === 'undefined') return true
    
    // No cached hash = need to generate
    if (!cachedDataHash) return true
    
    // Data changed = need to regenerate
    if (currentDataHash !== cachedDataHash) return true
    
    // Check if goal was updated after last feedback
    const lastGoalUpdate = getLastGoalUpdateTime()
    if (lastGoalUpdate > lastFeedbackTime) return true
    
    return false
}
