import SwiftUI

// MARK: - Dashboard View Model
/// Manages dashboard data including meals, nutrition totals, and AI feedback
@MainActor
final class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = true
    @Published var todayMeals: [Meal] = []
    @Published var weeklyMeals: [Meal] = []
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
    @Published var selectedDayMeals: [Meal]?
    @Published var selectedDate: Date?
    
    // Statistics AI Insight (matching Web implementation)
    @Published var statisticsInsight: String = ""
    @Published var isStatisticsInsightLoading = false
    
    // Profile for goal description
    private var currentProfile: Profile?
    
    // View mode: today or statistics
    @Published var viewMode: ViewMode = .today
    
    enum ViewMode {
        case today
        case statistics
    }
    
    // MARK: - Computed Properties for Statistics
    var weeklyCalorieData: [(date: Date, calories: Int)] {
        let calendar = Calendar.current
        var data: [(Date, Int)] = []
        
        // Group meals by day
        let grouped = Dictionary(grouping: weeklyMeals) { meal in
            calendar.startOfDay(for: meal.createdAt)
        }
        
        // Create data for last 7 days
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let startOfDay = calendar.startOfDay(for: date)
                let dayMeals = grouped[startOfDay] ?? []
                let calories = dayMeals.reduce(0) { $0 + ($1.analysis?.summary.calories ?? 0) }
                data.append((startOfDay, calories))
            }
        }
        
        return data.reversed()
    }
    
    var weeklyAverage: Int {
        guard !weeklyMeals.isEmpty else { return 0 }
        let total = weeklyMeals.reduce(0) { $0 + ($1.analysis?.summary.calories ?? 0) }
        
        // Calculate based on number of unique days with meals
        let calendar = Calendar.current
        let uniqueDays = Set(weeklyMeals.map { calendar.startOfDay(for: $0.createdAt) })
        return uniqueDays.isEmpty ? 0 : total / uniqueDays.count
    }
    
    var weeklyTotal: NutritionInfo {
        weeklyMeals.totalNutrition
    }
    
    // MARK: - Services
    // MARK: - Services
    private let mealService: MealServiceProtocol
    private let profileService: ProfileServiceProtocol
    private let geminiService: GeminiServiceProtocol
    private let cacheService = CacheService.shared // Singleton, tough to mock unless we wrap it or protocol it.
    
    init(
        mealService: MealServiceProtocol = MealService(),
        profileService: ProfileServiceProtocol = ProfileService(),
        geminiService: GeminiServiceProtocol = GeminiService()
    ) {
        self.mealService = mealService
        self.profileService = profileService
        self.geminiService = geminiService
    }
    
    // MARK: - Load Data
    /// Load all dashboard data (with caching for faster loads)
    func loadData() async {
        isLoading = true
        error = nil
        
        // Try to use cache first (matching Web localStorage pattern)
        if let cached = cacheService.getCachedDashboardData() {
            self.todayTotals = cached.totals
            self.targets = cached.targets
            self.aiFeedback = cached.feedback
            isLoading = false
            
            // Background refresh if cache is used
            Task {
                await loadFreshData()
            }
            return
        }
        
        await loadFreshData()
    }
    
    /// Load fresh data from network
    private func loadFreshData() async {
        do {
            // Load profile and meals in parallel
            async let profileTask = profileService.getProfile()
            async let mealsTask = mealService.getTodayMeals()
            async let weeklyMealsTask = mealService.getWeeklyMeals()
            
            let (profile, todayMeals, weeklyMeals) = try await (profileTask, mealsTask, weeklyMealsTask)
            
            // Update state
            self.todayMeals = todayMeals
            self.weeklyMeals = weeklyMeals
            self.todayTotals = todayMeals.totalNutrition
            self.targets = NutritionCalculator.getTargets(from: profile)
            self.currentProfile = profile
            
            isLoading = false
            
            // Generate AI feedback in background
            await generateFeedback(
                todayCalories: todayTotals.calories,
                weeklyMeals: weeklyMeals,
                profile: profile
            )
            
            // Cache the data after successful load
            cacheService.cacheDashboardData(
                totals: todayTotals,
                targets: targets,
                feedback: aiFeedback
            )
            
        } catch {
            self.error = AppError.from(error).localizedDescription
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
    
    // MARK: - Day Detail
    func selectDay(_ date: Date) {
        selectedDate = date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        selectedDayMeals = weeklyMeals.filter {
            calendar.startOfDay(for: $0.createdAt) == startOfDay
        }
    }
    
    func getMealsForDate(_ date: Date) -> [Meal] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return weeklyMeals.filter {
            calendar.startOfDay(for: $0.createdAt) == startOfDay
        }
    }
    
    func getCaloriesForDate(_ date: Date) -> Int {
        getMealsForDate(date).reduce(0) { $0 + ($1.analysis?.summary.calories ?? 0) }
    }
    
    func closeDayDetail() {
        selectedDate = nil
        selectedDayMeals = nil
    }
    
    // MARK: - Statistics Insight (matching Web implementation)
    /// Load AI insight for statistics view
    func loadStatisticsInsight() async {
        guard !isStatisticsInsightLoading else { return }
        guard !weeklyMeals.isEmpty else {
            statisticsInsight = "📊 Start logging meals to see personalized insights!"
            return
        }
        
        isStatisticsInsightLoading = true
        
        // Calculate statistics
        let calendar = Calendar.current
        let uniqueDays = Set(weeklyMeals.map { calendar.startOfDay(for: $0.createdAt) })
        let daysWithMeals = uniqueDays.count
        let totalMeals = weeklyMeals.count
        
        let totalNutrition = weeklyTotal
        let avgCalories = daysWithMeals > 0 ? totalNutrition.calories / daysWithMeals : 0
        let avgProtein = daysWithMeals > 0 ? totalNutrition.protein / daysWithMeals : 0
        let avgCarbs = daysWithMeals > 0 ? totalNutrition.carbs / daysWithMeals : 0
        let avgFat = daysWithMeals > 0 ? totalNutrition.fat / daysWithMeals : 0
        
        do {
            let insight = try await geminiService.generateStatisticsInsight(
                periodLabel: "Last 7 days",
                totalDays: 7,
                daysWithMeals: daysWithMeals,
                totalMeals: totalMeals,
                avgCalories: avgCalories,
                avgProtein: avgProtein,
                avgCarbs: avgCarbs,
                avgFat: avgFat,
                targetCalories: targets.calories,
                goalDescription: currentProfile?.goalDescription
            )
            statisticsInsight = insight
        } catch {
            statisticsInsight = "📊 Keep logging your meals consistently to get detailed insights!"
        }
        
        isStatisticsInsightLoading = false
    }
}
