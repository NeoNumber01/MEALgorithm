import SwiftUI

// MARK: - Dashboard View Model
/// Manages dashboard data including meals, nutrition totals, and AI feedback
@MainActor
final class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = true
    @Published var todayMeals: [Meal] = []
    @Published var todayTotals: NutritionInfo = .zero
    @Published var targets: NutritionInfo = NutritionInfo(
        calories: 2000,
        protein: 150,
        carbs: 200,
        fat: 65
    )
    @Published var aiFeedback: String = ""
    @Published var isFeedbackLoading = false
    @Published var error: String?
    @Published var selectedMeal: Meal?
    @Published var mealToDelete: Meal?
    @Published var isDeletingMeal = false
    
    // View mode: today or statistics
    @Published var viewMode: ViewMode = .today
    
    enum ViewMode {
        case today
        case statistics
    }
    
    // MARK: - Services
    private let mealService = MealService()
    private let profileService = ProfileService()
    private let geminiService = GeminiService()
    
    // MARK: - Load Data
    /// Load all dashboard data
    func loadData() async {
        isLoading = true
        error = nil
        
        do {
            // Load profile and meals in parallel
            async let profileTask = profileService.getProfile()
            async let mealsTask = mealService.getTodayMeals()
            async let weeklyMealsTask = mealService.getWeeklyMeals()
            
            let (profile, todayMeals, weeklyMeals) = try await (profileTask, mealsTask, weeklyMealsTask)
            
            // Update state
            self.todayMeals = todayMeals
            self.todayTotals = todayMeals.totalNutrition
            self.targets = NutritionCalculator.getTargets(from: profile)
            
            isLoading = false
            
            // Generate AI feedback in background
            await generateFeedback(
                todayCalories: todayTotals.calories,
                weeklyMeals: weeklyMeals,
                profile: profile
            )
            
        } catch {
            self.error = "Failed to load dashboard data"
            isLoading = false
        }
    }
    
    // MARK: - Generate AI Feedback
    private func generateFeedback(todayCalories: Int, weeklyMeals: [Meal], profile: Profile) async {
        isFeedbackLoading = true
        
        // Calculate weekly average
        let weeklyTotal = weeklyMeals.reduce(0) { $0 + ($1.analysis?.summary.calories ?? 0) }
        let weeklyAvg = weeklyMeals.isEmpty ? 0 : weeklyTotal / weeklyMeals.count
        
        do {
            let feedback = try await geminiService.generateFeedback(
                todayCalories: todayCalories,
                weeklyAvgCalories: weeklyAvg,
                targetCalories: targets.calories,
                goal: profile.goalDescription
            )
            self.aiFeedback = feedback
            
            // Cache the feedback
            try? await profileService.updateCachedFeedback(feedback)
        } catch {
            // Use cached feedback or default
            self.aiFeedback = profile.cachedFeedback ?? "Keep tracking your meals to get personalized insights!"
        }
        
        isFeedbackLoading = false
    }
    
    // MARK: - Delete Meal
    func deleteMeal(_ meal: Meal) async {
        isDeletingMeal = true
        
        do {
            try await mealService.deleteMeal(id: meal.id)
            
            // Remove from local state
            todayMeals.removeAll { $0.id == meal.id }
            todayTotals = todayMeals.totalNutrition
            
            // Close modal if this meal was selected
            if selectedMeal?.id == meal.id {
                selectedMeal = nil
            }
        } catch {
            self.error = "Failed to delete meal"
        }
        
        isDeletingMeal = false
        mealToDelete = nil
    }
    
    // MARK: - Refresh
    func refresh() async {
        await loadData()
    }
}
