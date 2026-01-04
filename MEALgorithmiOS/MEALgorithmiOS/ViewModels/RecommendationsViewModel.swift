import SwiftUI

// MARK: - Recommendations View Model
/// Manages AI-powered meal recommendations and day planning
@MainActor
final class RecommendationsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var viewMode: ViewMode = .nextMeal
    @Published var isLoadingNextMeal = false
    @Published var isLoadingDayPlan = false
    @Published var recommendations: [Recommendation] = []
    @Published var recommendationContext: RecommendationContext?
    @Published var dayPlan: [DayPlanMeal] = []
    @Published var daySummary: DayPlanSummary?
    @Published var dayContext: DayPlanContext?
    @Published var error: String?
    
    // Track if data has been loaded to prevent unnecessary refreshes
    private var nextMealLoaded = false
    private var dayPlanLoaded = false
    
    enum ViewMode {
        case nextMeal
        case dayPlan
    }
    
    // MARK: - Services
    private let geminiService: GeminiServiceProtocol
    private let profileService: ProfileServiceProtocol
    private let mealService: MealServiceProtocol
    
    init(
        geminiService: GeminiServiceProtocol = GeminiService(),
        profileService: ProfileServiceProtocol = ProfileService(),
        mealService: MealServiceProtocol = MealService()
    ) {
        self.geminiService = geminiService
        self.profileService = profileService
        self.mealService = mealService
    }
    
    // MARK: - Load on View Mode Change
    func onViewModeChange() async {
        switch viewMode {
        case .nextMeal:
            if !nextMealLoaded {
                await loadNextMeal()
            }
        case .dayPlan:
            if !dayPlanLoaded {
                await loadDayPlan()
            }
        }
    }
    
    // MARK: - Load Next Meal Recommendations
    func loadNextMeal(forceRefresh: Bool = false) async {
        if forceRefresh {
            nextMealLoaded = false
        }
        
        // Check persistent cache
        if !forceRefresh {
            if let cached: CachedRecommendations = loadFromCache(key: cacheKeyNextMeal) {
                print("DEBUG: Using cached recommendations")
                self.recommendations = cached.recommendations
                self.recommendationContext = cached.context
                self.nextMealLoaded = true
                return
            }
        }
        
        isLoadingNextMeal = true
        error = nil
        
        do {
            let profile = try await profileService.getProfile()
            let weeklyMeals = try await mealService.getWeeklyMeals()
            
            // Calculate context
            let targets = NutritionCalculator.getTargets(from: profile)
            let weeklyAvg = weeklyMeals.isEmpty ? 0 :
                weeklyMeals.reduce(0) { $0 + ($1.analysis?.summary.calories ?? 0) } / weeklyMeals.count
            
            recommendationContext = RecommendationContext(
                targetCalories: targets.calories,
                recentAvgCalories: weeklyAvg,
                goal: profile.goalDescription
            )
            
            // Build preferences from profile (matching Web implementation)
            var preferences: [String] = []
            if let foodPrefs = profile.foodPreferences, !foodPrefs.isEmpty {
                preferences.append("Favorite: \(foodPrefs)")
            }
            if let dislikes = profile.foodDislikes, !dislikes.isEmpty {
                preferences.append("Avoid: \(dislikes)")
            }
            if let restrictions = profile.dietaryRestrictions, !restrictions.isEmpty {
                preferences.append("Restrictions: \(restrictions)")
            }
            if let notes = profile.customNotes, !notes.isEmpty {
                preferences.append("Notes: \(notes)")
            }
            
            // Extract frequent ingredients from meal history (matching Web implementation)
            let mealDescriptions = weeklyMeals.compactMap { $0.textContent }
            let frequentIngredients = extractFrequentIngredients(from: mealDescriptions)
            if !frequentIngredients.isEmpty {
                preferences.append("Often eats: \(frequentIngredients.joined(separator: ", "))")
            }
            
            // Generate recommendations with full context
            recommendations = try await geminiService.generateRecommendations(
                targetCalories: targets.calories,
                recentAvgCalories: weeklyAvg,
                goal: profile.goalDescription,
                preferences: preferences.isEmpty ? nil : preferences
            )
            
            nextMealLoaded = true
            
            // Save to cache
            saveToCache(CachedRecommendations(recommendations: recommendations, context: recommendationContext), key: cacheKeyNextMeal)
            
        } catch {
            self.error = "Failed to load recommendations"
        }
        
        isLoadingNextMeal = false
    }
    
    // MARK: - Load Day Plan
    func loadDayPlan(forceRefresh: Bool = false) async {
        if forceRefresh {
            dayPlanLoaded = false
        }
        
        // Check persistent cache
        if !forceRefresh {
            if let cached: CachedDayPlan = loadFromCache(key: cacheKeyDayPlan) {
                print("DEBUG: Using cached day plan")
                self.dayPlan = cached.plan
                self.daySummary = cached.summary
                self.dayContext = cached.context
                self.dayPlanLoaded = true
                return
            }
        }
        
        isLoadingDayPlan = true
        error = nil
        
        do {
            let profile = try await profileService.getProfile()
            let todayMeals = try await mealService.getTodayMeals()
            
            // Calculate context
            let targets = NutritionCalculator.getTargets(from: profile)
            let consumedCalories = todayMeals.reduce(0) { $0 + ($1.analysis?.summary.calories ?? 0) }
            let eatenMealTypes = todayMeals.compactMap { $0.mealType?.rawValue }
            
            // Time-based meal filtering (matching Web implementation)
            let currentHour = Calendar.current.component(.hour, from: Date())
            let mealTimeWindows: [String: (start: Int, end: Int)] = [
                "breakfast": (5, 10),
                "lunch": (11, 14),
                "dinner": (17, 21),
                "snack": (0, 24)
            ]
            
            let remainingMealTypes = mealTimeWindows.compactMap { (mealType, window) -> String? in
                if eatenMealTypes.contains(mealType) { return nil }
                if mealType == "snack" { return mealType }
                return currentHour < window.end ? mealType : nil
            }
            
            dayContext = DayPlanContext(
                targetCalories: targets.calories,
                consumedCalories: consumedCalories,
                remainingCalories: max(0, targets.calories - consumedCalories),
                eatenMealTypes: eatenMealTypes,
                remainingMealTypes: remainingMealTypes
            )
            
            // Build preferences from profile
            var preferences: [String] = []
            if let foodPrefs = profile.foodPreferences, !foodPrefs.isEmpty {
                preferences.append("Favorite: \(foodPrefs)")
            }
            if let dislikes = profile.foodDislikes, !dislikes.isEmpty {
                preferences.append("Avoid: \(dislikes)")
            }
            if let restrictions = profile.dietaryRestrictions, !restrictions.isEmpty {
                preferences.append("Restrictions: \(restrictions)")
            }
            
            // Generate day plan with preferences
            let result = try await geminiService.generateDayPlan(
                targetCalories: targets.calories,
                consumedCalories: consumedCalories,
                eatenMealTypes: eatenMealTypes,
                goal: profile.goalDescription,
                preferences: preferences.isEmpty ? nil : preferences
            )
            
            dayPlan = result.meals
            daySummary = result.summary
            dayPlanLoaded = true
            
            // Save to cache
            saveToCache(CachedDayPlan(plan: dayPlan, summary: daySummary, context: dayContext), key: cacheKeyDayPlan)
            
        } catch {
            self.error = "Failed to load day plan"
        }
        
        isLoadingDayPlan = false
    }
    
    // MARK: - Refresh Handlers
    func refreshNextMeal() async {
        await loadNextMeal(forceRefresh: true)
    }
    
    func refreshDayPlan() async {
        await loadDayPlan(forceRefresh: true)
    }
    
    // MARK: - Reset Cache (for preferences update)
    func resetCache() {
        nextMealLoaded = false
        dayPlanLoaded = false
        userDefaults.removeObject(forKey: cacheKeyNextMeal)
        userDefaults.removeObject(forKey: cacheKeyDayPlan)
    }
    
    // MARK: - Caching
    private let userDefaults = UserDefaults.standard
    private let cacheKeyNextMeal = "meal_recommendations_cache_v1"
    private let cacheKeyDayPlan = "day_plan_cache_v1"
    private let cacheValidityDuration: TimeInterval = 4 * 3600 // 4 hours

    struct CachedData<T: Codable>: Codable {
        let items: T
        let timestamp: Date
        let cacheDate: String  // "yyyy-MM-dd" format for day-based cache invalidation
        let userId: String?    // User ID for cache isolation between users
    }
    
    struct CachedDayPlan: Codable {
        let plan: [DayPlanMeal]
        let summary: DayPlanSummary?
        let context: DayPlanContext?
    }
    
    struct CachedRecommendations: Codable {
        let recommendations: [Recommendation]
        let context: RecommendationContext?
    }

    private func saveToCache<T: Codable>(_ data: T, key: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        
        // Get current user ID for cache isolation
        let userId = getCurrentUserId()
        
        let cached = CachedData(items: data, timestamp: Date(), cacheDate: todayString, userId: userId)
        if let encoded = try? JSONEncoder().encode(cached) {
            userDefaults.set(encoded, forKey: key)
        }
    }

    private func loadFromCache<T: Codable>(key: String) -> T? {
        guard let data = userDefaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(CachedData<T>.self, from: data) else {
            return nil
        }
        
        // Time-based invalidation
        if Date().timeIntervalSince(decoded.timestamp) >= cacheValidityDuration {
            return nil
        }
        
        // User ID validation - ensure cache belongs to current user
        let currentUserId = getCurrentUserId()
        if let cachedUserId = decoded.userId, cachedUserId != currentUserId {
            return nil
        }
        
        // Date-based invalidation for Day Plan cache (invalidate if day changed)
        if key == cacheKeyDayPlan {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayString = dateFormatter.string(from: Date())
            if decoded.cacheDate != todayString {
                print("DEBUG: Day plan cache invalidated - date changed")
                return nil
            }
        }
        
        return decoded.items
    }
    
    /// Get current user ID for cache isolation (synchronous using local storage)
    private func getCurrentUserId() -> String? {
        // Use the auth session from local storage (synchronous)
        // The Supabase SDK stores the session locally, so we can try to read it directly
        // For simplicity, we use the auth listener's cached user or return nil
        if let session = try? SupabaseManager.shared.client.auth.currentSession {
            return session.user.id.uuidString
        }
        return nil
    }
    
    // MARK: - Helper: Extract Frequent Ingredients
    /// Analyzes meal descriptions to find commonly mentioned ingredients (matching Web implementation)
    private func extractFrequentIngredients(from descriptions: [String]) -> [String] {
        let combinedText = descriptions.joined(separator: " ").lowercased()
        
        // Common food keywords to look for (matching Web)
        let foodKeywords = [
            "chicken", "beef", "pork", "fish", "salmon", "tuna", "shrimp",
            "rice", "pasta", "noodles", "bread", "potato",
            "salad", "vegetables", "broccoli", "spinach", "tomato",
            "eggs", "cheese", "yogurt", "milk",
            "apple", "banana", "berries", "orange",
            "tofu", "beans", "lentils",
            "avocado", "nuts", "almonds",
            "soup", "sandwich", "burger", "pizza", "sushi",
            "coffee", "tea", "smoothie",
            // Chinese food keywords
            "鸡肉", "牛肉", "猪肉", "鱼", "虾",
            "米饭", "面条", "面包",
            "沙拉", "蔬菜", "西兰花", "菠菜",
            "鸡蛋", "奶酪", "酸奶",
            "苹果", "香蕉", "橙子",
            "豆腐", "豆类"
        ]
        
        var found: [String] = []
        for keyword in foodKeywords {
            if combinedText.contains(keyword) {
                found.append(keyword)
            }
        }
        
        return Array(found.prefix(8)) // Return top 8 ingredients
    }
}
