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
    private let geminiService = GeminiService()
    private let profileService = ProfileService()
    private let mealService = MealService()
    
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
            
            // Generate recommendations
            recommendations = try await geminiService.generateRecommendations(
                targetCalories: targets.calories,
                recentAvgCalories: weeklyAvg,
                goal: profile.goalDescription,
                preferences: nil // TODO: Add food preferences
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
            let remainingMealTypes = ["breakfast", "lunch", "dinner", "snack"]
                .filter { !eatenMealTypes.contains($0) }
            
            dayContext = DayPlanContext(
                targetCalories: targets.calories,
                consumedCalories: consumedCalories,
                remainingCalories: max(0, targets.calories - consumedCalories),
                eatenMealTypes: eatenMealTypes,
                remainingMealTypes: remainingMealTypes
            )
            
            // Generate day plan
            let result = try await geminiService.generateDayPlan(
                targetCalories: targets.calories,
                consumedCalories: consumedCalories,
                eatenMealTypes: eatenMealTypes,
                goal: profile.goalDescription,
                preferences: nil
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
}
