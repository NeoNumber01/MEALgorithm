import Foundation

// MARK: - Cache Service
/// Local caching service using UserDefaults (matching Web localStorage implementation)
/// This is a simple cache for dashboard data to reduce network requests
final class CacheService {
    static let shared = CacheService()
    
    private let defaults = UserDefaults.standard
    
    // Cache keys (matching Web CACHE_KEYS)
    private enum Keys {
        static let dashboardTimestamp = "dashboard_cache_timestamp"
        static let dashboardTodayDate = "dashboard_today_date"
        static let dashboardTotals = "dashboard_totals"
        static let dashboardTargets = "dashboard_targets"
        static let dashboardFeedback = "dashboard_feedback"
        static let lastDataUpdate = "last_data_update"
    }
    
    // Cache duration: 1 hour (matching Web implementation)
    private let cacheDuration: TimeInterval = 3600
    
    private init() {}
    
    // MARK: - Dashboard Cache
    
    /// Check if dashboard cache is valid
    func isDashboardCacheValid() -> Bool {
        guard let timestamp = defaults.object(forKey: Keys.dashboardTimestamp) as? Date else {
            return false
        }
        
        // Check if cache is from today
        let cachedDate = defaults.string(forKey: Keys.dashboardTodayDate) ?? ""
        let today = formatDate(Date())
        if cachedDate != today {
            return false
        }
        
        // Check if cache is fresh (within 1 hour)
        let lastUpdate = defaults.object(forKey: Keys.lastDataUpdate) as? Date ?? Date.distantPast
        if timestamp < lastUpdate {
            return false
        }
        
        // Check if cache hasn't expired
        return Date().timeIntervalSince(timestamp) < cacheDuration
    }
    
    /// Cache dashboard data
    func cacheDashboardData(
        totals: NutritionInfo,
        targets: NutritionInfo,
        feedback: String
    ) {
        defaults.set(Date(), forKey: Keys.dashboardTimestamp)
        defaults.set(formatDate(Date()), forKey: Keys.dashboardTodayDate)
        
        // Encode and cache
        if let totalsData = try? JSONEncoder().encode(totals) {
            defaults.set(totalsData, forKey: Keys.dashboardTotals)
        }
        if let targetsData = try? JSONEncoder().encode(targets) {
            defaults.set(targetsData, forKey: Keys.dashboardTargets)
        }
        defaults.set(feedback, forKey: Keys.dashboardFeedback)
    }
    
    /// Get cached dashboard data
    func getCachedDashboardData() -> (totals: NutritionInfo, targets: NutritionInfo, feedback: String)? {
        guard isDashboardCacheValid() else { return nil }
        
        guard let totalsData = defaults.data(forKey: Keys.dashboardTotals),
              let targetsData = defaults.data(forKey: Keys.dashboardTargets),
              let totals = try? JSONDecoder().decode(NutritionInfo.self, from: totalsData),
              let targets = try? JSONDecoder().decode(NutritionInfo.self, from: targetsData) else {
            return nil
        }
        
        let feedback = defaults.string(forKey: Keys.dashboardFeedback) ?? ""
        return (totals, targets, feedback)
    }
    
    // MARK: - Data Update Notification
    
    /// Notify that data has been updated (invalidates cache)
    func notifyDataUpdated() {
        defaults.set(Date(), forKey: Keys.lastDataUpdate)
    }
    
    /// Clear all cache
    func clearCache() {
        defaults.removeObject(forKey: Keys.dashboardTimestamp)
        defaults.removeObject(forKey: Keys.dashboardTodayDate)
        defaults.removeObject(forKey: Keys.dashboardTotals)
        defaults.removeObject(forKey: Keys.dashboardTargets)
        defaults.removeObject(forKey: Keys.dashboardFeedback)
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
