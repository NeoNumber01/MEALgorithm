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
