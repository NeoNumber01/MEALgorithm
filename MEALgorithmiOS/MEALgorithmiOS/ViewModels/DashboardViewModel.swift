import SwiftUI
import SwiftData

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
    
    // Macro Detail Selection
    @Published var selectedMacroItem: NutritionEducationItem?
    @Published var nutritionEducation: [NutritionEducationItem] = []
    
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
    
    // Stats Card Detail Selection
    enum StatsCardType: String, Identifiable {
        case weeklySummary
        case weeklyChart
        case weeklyNutrition
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .weeklySummary: return "Weekly Summary"
            case .weeklyChart: return "This Week"
            case .weeklyNutrition: return "Weekly Nutrition"
            }
        }
        
        var icon: String {
            switch self {
            case .weeklySummary: return "📊"
            case .weeklyChart: return "📅"
            case .weeklyNutrition: return "📈"
            }
        }
    }
    
    @Published var selectedStatsCard: StatsCardType?
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
    
    func getWeeklyData(for nutrient: String) -> [(date: Date, value: Int)] {
        let calendar = Calendar.current
        var data: [(Date, Int)] = []
        
        let grouped = Dictionary(grouping: weeklyMeals) { meal in
            calendar.startOfDay(for: meal.createdAt)
        }
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let startOfDay = calendar.startOfDay(for: date)
                let dayMeals = grouped[startOfDay] ?? []
                
                let value = dayMeals.reduce(0) { total, meal in
                    let summary = meal.analysis?.summary
                    switch nutrient {
                    case "calories": return total + (summary?.calories ?? 0)
                    case "protein": return total + (summary?.protein ?? 0)
                    case "carbs": return total + (summary?.carbs ?? 0)
                    case "fat": return total + (summary?.fat ?? 0)
                    default: return total
                    }
                }
                data.append((startOfDay, value))
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
    // MARK: - Services
    private let mealService: MealServiceProtocol
    private let profileService: ProfileServiceProtocol
    private let geminiService: GeminiServiceProtocol
    private let cacheService = CacheService.shared
    private var mealRepository: MealRepository?
    
    init(
        mealService: MealServiceProtocol = MealService(),
        profileService: ProfileServiceProtocol = ProfileService(),
        geminiService: GeminiServiceProtocol = GeminiService()
    ) {
        self.mealService = mealService
        self.profileService = profileService
        self.geminiService = geminiService
        
        setupObservers()
    }
    
    /// Configure with ModelContext (called from View)
    func configure(modelContext: ModelContext) {
        self.mealRepository = MealRepository(context: modelContext, mealService: mealService)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupObservers() {
        // Reload when a new meal is saved
        NotificationCenter.default.addObserver(
            forName: .mealDidSave,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.loadData(forceRefresh: true)
            }
        }
        
        // Reload when a meal is deleted (if triggered externally)
        NotificationCenter.default.addObserver(
            forName: .mealDidDelete,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.loadData(forceRefresh: true)
            }
        }
    }
    
    // MARK: - Load Data
    /// Load all dashboard data (with caching for faster loads)
    /// Load all dashboard data (with caching for faster loads)
    func loadData(forceRefresh: Bool = false) async {
        isLoading = true
        error = nil
        
        // Try to use cache first (matching Web localStorage pattern)
        if !forceRefresh, let cached = cacheService.getCachedDashboardData() {
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
        loadEducationData()
    }
    
    private func loadEducationData() {
        // Prepare fallback data
        let fallbackData: [NutritionEducationItem] = [
            NutritionEducationItem(
                id: "calories",
                title: "Calories",
                content: "Calories are a unit of energy that measures how much fuel your body gets from food. Your Total Daily Energy Expenditure (TDEE) accounts for your activity level. Understanding your calorie needs is the first step in weight management."
            ),
            NutritionEducationItem(
                id: "protein",
                title: "Protein",
                content: "Protein is a fundamental building block of cells, tissues, and organs, essential for muscle growth and repair. Quality protein sources include meat, fish, eggs, dairy, and legumes."
            ),
            NutritionEducationItem(
                id: "carbs",
                title: "Carbohydrates",
                content: "Carbohydrates are your body's primary energy source. Complex carbs (whole grains, veggies) provide sustained energy and fiber, while simple carbs provide quick energy."
            ),
            NutritionEducationItem(
                id: "fat",
                title: "Fat",
                content: "Fat is a dense energy source vital for cell health and hormone production. Focus on healthy unsaturated fats like those in avocados, nuts, and olive oil."
            )
        ]
        
        guard let url = Bundle.main.url(forResource: "nutrition_info", withExtension: "json") else {
            print("⚠️ Nutrition info file not found, using fallback data")
            self.nutritionEducation = fallbackData
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([NutritionEducationItem].self, from: data)
            self.nutritionEducation = items
        } catch {
            print("⚠️ Failed to load nutrition education: \(error), using fallback data")
            self.nutritionEducation = fallbackData
        }
    }
    
    func selectMacro(_ id: String) {
        print("📊 selectMacro called with id: \(id)")
        
        // Try to find from loaded JSON first
        if let item = nutritionEducation.first(where: { $0.id == id }) {
            print("📊 Found item from JSON: \(item.title)")
            self.selectedMacroItem = item
            return
        }
        
        print("📊 Using fallback data for: \(id)")
        
        // Fallback data if JSON not loaded
        let fallbackData: [String: NutritionEducationItem] = [
            "calories": NutritionEducationItem(
                id: "calories",
                title: "Calories",
                content: "Calories are a unit of energy that measures how much fuel your body gets from food. When you eat, carbohydrates, fats, and proteins are metabolized to release energy. Your Basal Metabolic Rate (BMR) is the minimum energy needed to maintain basic functions like breathing and circulation at rest. Your Total Daily Energy Expenditure (TDEE) accounts for your activity level. If you consume more calories than you burn, the excess is stored as fat, leading to weight gain; the opposite leads to weight loss. Understanding your calorie needs is the first step in weight management, but quality matters as much as quantity. Calories from whole grains and lean proteins provide sustained energy and better nutrition than those from sugar and processed foods."
            ),
            "protein": NutritionEducationItem(
                id: "protein",
                title: "Protein",
                content: "Protein is a fundamental building block of cells, tissues, and organs, essential for muscle growth and repair. It consists of 20 amino acids, 9 of which are essential and must be obtained through diet. Beyond muscle building, protein plays a core role in immune function, hormone synthesis, and enzyme production. Adequate protein intake promotes satiety, helping control appetite and manage weight. This is why high-protein diets are often recommended for both fat loss and muscle gain. Quality protein sources include meat, fish, eggs, dairy, as well as plant-based options like legumes and nuts. Protein needs vary based on weight, activity level, and health goals, typically ranging from 0.8 to 2.0 grams per kilogram of body weight."
            ),
            "carbs": NutritionEducationItem(
                id: "carbs",
                title: "Carbohydrates",
                content: "Carbohydrates are your body's primary and preferred source of energy, quickly converted to glucose to fuel your brain, nervous system, and muscles. They are divided into simple carbs (like sugar and refined flour) and complex carbs (like whole grains, vegetables, and legumes). Complex carbohydrates are rich in dietary fiber, digested more slowly, providing sustained energy and stable blood sugar levels. While fiber does not provide energy, it is crucial for gut health, promoting digestion and reducing the risk of certain chronic diseases. Many mistakenly believe carbs cause weight gain, but excess total calories and poor-quality refined carbs are the real culprits. The right approach is choosing nutrient-rich, unprocessed carb sources as part of a balanced diet."
            ),
            "fat": NutritionEducationItem(
                id: "fat",
                title: "Fat",
                content: "Fat is an essential nutrient often misunderstood as the enemy of health. In reality, fat is a dense energy source (9 calories per gram), vital for maintaining cell membrane integrity, synthesizing key hormones (like sex hormones and cortisol), and helping your body absorb fat-soluble vitamins (A, D, E, K). Fats are categorized as saturated, unsaturated, and trans fats. Avoid artificial trans fats, limit saturated fats, and focus on unsaturated fats rich in Omega-3 and Omega-9, found in olive oil, avocados, fatty fish, and nuts. Healthy fat intake supports brain function, protects internal organs, and maintains healthy skin and hair. The key is choosing good fats and controlling overall intake for energy balance and cardiovascular health."
            )
        ]
        
        if let item = fallbackData[id] {
            print("📊 Setting selectedMacroItem to: \(item.title)")
            self.selectedMacroItem = item
        } else {
            print("📊 ERROR: No fallback data found for id: \(id)")
        }
    }
    
    /// Load fresh data from network
    private func loadFreshData() async {
        // Load Profile (Resilient)
        var fetchedProfile: Profile? = nil
        do {
            fetchedProfile = try await profileService.getProfile()
            self.currentProfile = fetchedProfile
        } catch {
            print("⚠️ Dashboard: Profile fetch failed (\(error)). Using default targets.")
            // Don't throw here; continue to load meals.
            // Consider defaulting currentProfile to nil or a detailed error state if needed.
        }
        
        do {
            // Load Meals in parallel (Prefer Local Repository for offline support)
            // If repository is configured, use it for immediate local data (including pending syncs)
            
            var localTodayMeals: [Meal] = []
            
            // 1. Try Local First (Offline/Pending)
            if let repository = mealRepository {
                do {
                    localTodayMeals = try repository.getTodayMeals()
                    print("📊 Dashboard: Loaded \(localTodayMeals.count) meals from Local Repository")
                } catch {
                    print("⚠️ Dashboard: Local fetch failed: \(error)")
                }
            }
            
            // 2. Load Remote (Background Sync / Historical)
            // We use repository for weekly meals too if available, to support offline charts
            
            async let mealsTask = mealService.getTodayMeals()
            async let weeklyMealsTask = mealService.getWeeklyMeals()
            
            // Optimistic Update: If we have local meals, show them immediately
            if !localTodayMeals.isEmpty {
                 self.todayMeals = localTodayMeals
                 self.todayTotals = localTodayMeals.totalNutrition
            }
            
            // Try to load local weekly meals first
            if let repository = mealRepository {
                 do {
                     let localWeekly = try repository.getWeeklyMeals()
                     if !localWeekly.isEmpty {
                         self.weeklyMeals = localWeekly
                     }
                 } catch {
                     print("⚠️ Dashboard: Local weekly fetch failed: \(error)")
                 }
            }

            let (remoteTodayMeals, weeklyMeals) = try await (mealsTask, weeklyMealsTask)
            
            // If we have Repository, we rely on it for Today's view to show pending items.
            if mealRepository != nil {
                // Refresh local again in case SyncEngine updated something in background
                if let updatedLocal = try? mealRepository?.getTodayMeals() {
                    self.todayMeals = updatedLocal
                    self.todayTotals = updatedLocal.totalNutrition
                }
                 // Refresh weekly local too
                if let updatedWeekly = try? mealRepository?.getWeeklyMeals(), !updatedWeekly.isEmpty {
                    self.weeklyMeals = updatedWeekly
                } else {
                     // If local fails or empty, fallback to remote
                     self.weeklyMeals = weeklyMeals
                }
            } else {
                // Fallback to remote if no repo configured
                self.todayMeals = remoteTodayMeals
                self.todayTotals = remoteTodayMeals.totalNutrition
                self.weeklyMeals = weeklyMeals
            }
            
            // Use profile if available, else standard defaults
            if let profile = fetchedProfile {
                self.targets = NutritionCalculator.getTargets(from: profile)
            } else {
                // Keep existing defaults (2000 kcal etc defined in init)
                print("⚠️ Dashboard: Using default nutrition targets.")
            }
            
            isLoading = false
            
            // Generate AI feedback in background
            // We pass a dummy profile or the fetched one. 
            // If fetchedProfile is nil, we can't generate personalized goal feedback easily, 
            // but we can still try with generic params or skip.
            if let profile = fetchedProfile {
                await generateFeedback(
                    todayCalories: todayTotals.calories,
                    weeklyMeals: weeklyMeals,
                    profile: profile
                )
            }
            
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
            // Priority: Delete from Local Repository (Source of Truth)
            if let repository = mealRepository {
                try repository.deleteMeal(id: meal.id)
            } else {
                // Fallback direct remote delete (legacy/non-persisted mode)
                try await mealService.deleteMeal(id: meal.id)
            }
            
            // Remove from local state immediately for UI responsiveness
            todayMeals.removeAll { $0.id == meal.id }
            weeklyMeals.removeAll { $0.id == meal.id } // Also remove from weekly if present
            todayTotals = todayMeals.totalNutrition
            
            // Notify other views
            NotificationCenter.default.post(name: .mealDidDelete, object: nil)
            
            // Close modal if this meal was selected
            if selectedMeal?.id == meal.id {
                selectedMeal = nil
            }
        } catch {
            print("❌ Delete failed: \(error)")
            self.error = "Failed to delete meal"
        }
        
        isDeletingMeal = false
        mealToDelete = nil
    }
    
    // MARK: - Refresh
    func refresh() async {
        await loadData(forceRefresh: true)
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

// MARK: - Nutrition Education Model
struct NutritionEducationItem: Codable, Identifiable {
    let id: String
    let title: String
    let content: String
}
