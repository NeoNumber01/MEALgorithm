import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Nebula Background
                Color.appBackground.ignoresSafeArea()
                
                // Ambient Glow
                GeometryReader { geo in
                    Circle()
                        .fill(Color.appPrimary.opacity(0.15))
                        .frame(width: geo.size.width * 0.8)
                        .blur(radius: 100)
                        .offset(x: -geo.size.width * 0.2, y: -100)
                    
                    Circle()
                        .fill(Color.appSecondary.opacity(0.1))
                        .frame(width: geo.size.width * 0.6)
                        .blur(radius: 80)
                        .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.4)
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection
                            .skeleton(isLoading: viewModel.isLoading)
                        
                        if viewModel.viewMode == .today {
                            todayContent
                        } else {
                            statisticsContent
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for tab bar
                }
                .disabled(viewModel.isLoading)
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(item: $viewModel.selectedMeal) { meal in
                MealDetailSheet(meal: meal) {
                    viewModel.mealToDelete = meal
                }
            }
            .sheet(item: $viewModel.selectedDate) { date in
                DayDetailSheet(
                    date: date,
                    meals: viewModel.getMealsForDate(date),
                    targets: viewModel.targets
                ) {
                    viewModel.closeDayDetail()
                }
            }
            .sheet(item: $viewModel.selectedMacroItem) { item in
                MacroDetailSheet(item: item, viewModel: viewModel)
            }
            .confirmationDialog(
                "Delete Meal?",
                isPresented: Binding(
                    get: { viewModel.mealToDelete != nil },
                    set: { if !$0 { viewModel.mealToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let meal = viewModel.mealToDelete {
                        Task {
                            await viewModel.deleteMeal(meal)
                        }
                    }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(viewModel.viewMode == .today ? "Today's Overview" : "Statistics & History")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(Date().formattedDate)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // View Mode Toggle
                HStack(spacing: 4) {
                    ForEach([DashboardViewModel.ViewMode.today, .statistics], id: \.self) { mode in
                        Button {
                            withAnimation {
                                viewModel.viewMode = mode
                            }
                        } label: {
                            Text(mode == .today ? "📅 Today" : "📊 Stats")
                                .font(.footnote)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(viewModel.viewMode == mode ? Color.white : Color.clear)
                                .cornerRadius(8)
                        }
                        .foregroundColor(viewModel.viewMode == mode ? .black : .white) // Black text on White BG
                        .hapticFeedback(style: .light)
                    }
                }
                .padding(4)
                .background(Color(.systemGray5))
                .cornerRadius(12)
            }
        }
        .padding(.top)
    }
    
    // MARK: - Today Content
    private var todayContent: some View {
        VStack(spacing: 20) {
            // Calorie Gauge - Tappable
            Button {
                print("📊 Calories gauge tapped")
                viewModel.selectMacro("calories")
            } label: {
                CalorieGaugeView(
                    current: viewModel.todayTotals.calories,
                    target: viewModel.targets.calories
                )
                .frame(height: 250)
                .liquidGlass()
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .smartZoomEffect()
            .skeleton(isLoading: viewModel.isLoading)
            
            // Macro Cards - with overlay tappable areas
            ZStack {
                // Base layer: Cards with zoom effect
                HStack(spacing: 12) {
                    MacroCardView(
                        title: "Protein",
                        icon: "🥩",
                        current: viewModel.todayTotals.protein,
                        target: viewModel.targets.protein,
                        unit: "g",
                        colors: [.proteinStart, .proteinEnd]
                    )
                    
                    MacroCardView(
                        title: "Carbs",
                        icon: "🍞",
                        current: viewModel.todayTotals.carbs,
                        target: viewModel.targets.carbs,
                        unit: "g",
                        colors: [.carbsStart, .carbsEnd]
                    )
                    
                    MacroCardView(
                        title: "Fat",
                        icon: "🧈",
                        current: viewModel.todayTotals.fat,
                        target: viewModel.targets.fat,
                        unit: "g",
                        colors: [.fatStart, .fatEnd]
                    )
                }
                .smartZoomEffect()
                
                // Overlay: Invisible tap buttons
                HStack(spacing: 12) {
                    Button {
                        print("📊 Protein card tapped")
                        viewModel.selectMacro("protein")
                    } label: {
                        Color.clear
                    }
                    
                    Button {
                        print("📊 Carbs card tapped")
                        viewModel.selectMacro("carbs")
                    } label: {
                        Color.clear
                    }
                    
                    Button {
                        print("📊 Fat card tapped")
                        viewModel.selectMacro("fat")
                    } label: {
                        Color.clear
                    }
                }
            }
            .skeleton(isLoading: viewModel.isLoading)
            
            // AI Feedback
            if !viewModel.aiFeedback.isEmpty || viewModel.isFeedbackLoading {
                AIFeedbackCard(
                    feedback: viewModel.aiFeedback,
                    isLoading: viewModel.isFeedbackLoading
                )
                .smartZoomEffect()
            }
            
            // Today's Meals
            if viewModel.isLoading {
                // Skeleton Mock Items
                VStack(spacing: 12) {
                    Text("🍽️ Today's Meals")
                        .font(.headline)
                        .skeleton(isLoading: true)
                    
                    ForEach(0..<3) { _ in
                        HStack {
                            RoundedRectangle(cornerRadius: 10).frame(width: 44, height: 44)
                            VStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).frame(width: 100, height: 16)
                                RoundedRectangle(cornerRadius: 4).frame(width: 60, height: 12)
                            }
                            Spacer()
                            RoundedRectangle(cornerRadius: 4).frame(width: 50, height: 20)
                        }
                        .padding()
                        .background(Color(.systemBackground).opacity(0.5))
                        .cornerRadius(12)
                        .skeleton(isLoading: true)
                    }
                }
                .padding()
                .liquidGlass()
            } else if !viewModel.todayMeals.isEmpty {
                TodayMealsSection(
                    meals: viewModel.todayMeals,
                    onMealTap: { meal in
                        viewModel.selectedMeal = meal
                    }
                )
                .smartZoomEffect()
            } else {
                EmptyStateView(
                    icon: "🍽️",
                    title: "No meals logged yet",
                    message: "Start tracking your nutrition today!"
                )
                .frame(maxWidth: .infinity)
                .liquidGlass()
                .smartZoomEffect()
            }
        }
    }
}

// MARK: - Calorie Gauge View
struct CalorieGaugeView: View {
    let current: Int
    let target: Int
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient.calories,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .caloriesEnd.opacity(0.5), radius: 15, x: 0, y: 0) // Neon Glow
                    .animation(.spring(response: 1.5, dampingFraction: 0.8), value: progress)
                
                // Center text
                VStack(spacing: 4) {
                    Text("\(current)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white) // Force white
                    
                    Text("of \(target) kcal")
                        .foregroundColor(.white.opacity(0.7)) // Force light
                }
            }
            .padding(20)
            
            Text("Today's Calories")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7)) // Force light
        }
        .padding()
        .frame(maxWidth: .infinity) // Ensure full width matching macro cards
    }
}

// MARK: - Macro Card View
struct MacroCardView: View {
    let title: String
    let icon: String
    let current: Int
    let target: Int
    let unit: String
    let colors: [Color]
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(colors.first?.opacity(0.2) ?? .gray)
                        .frame(width: 32, height: 32)
                    
                    Text(icon)
                        .font(.system(size: 16))
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(current)")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("/ \(target) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: colors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .shadow(color: colors.last?.opacity(0.5) ?? .clear, radius: 5, x: 0, y: 0)
                }
            }
            .frame(height: 6)
            
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(colors.last)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .liquidGlass() // New Glass Effect
        .hoverEffect()
    }
}

// MARK: - AI Feedback Card
struct AIFeedbackCard: View {
    let feedback: String
    let isLoading: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Text("🤖")
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Coach Insight")
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing your progress...")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(feedback)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Today Meals Section
struct TodayMealsSection: View {
    let meals: [Meal]
    let onMealTap: (Meal) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🍽️ Today's Meals")
                .font(.headline)
            
            ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                Button {
                    onMealTap(meal)
                } label: {
                    HStack {
                        Text(meal.mealIcon(index: index))
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                        
                        VStack(alignment: .leading) {
                            Text(meal.mealType?.displayName ?? "Meal")
                                .fontWeight(.semibold)
                            Text(meal.formattedTime)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(meal.analysis?.summary.calories ?? 0)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.caloriesColor)
                        Text("kcal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.5))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .hapticFeedback(style: .light)
            }
        }
        .padding()
        .liquidGlass()
    }
}

// MARK: - Meal Detail Sheet
struct MealDetailSheet: View {
    let meal: Meal
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text(meal.mealType?.displayName ?? "Meal")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(meal.createdAt.formattedDate)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(meal.mealType?.icon ?? "🍽️")
                            .font(.system(size: 44))
                    }
                    .padding(.horizontal) // Added padding
                    
                    // Nutrition Summary
                    if let summary = meal.analysis?.summary {
                        HStack(spacing: 16) {
                            NutritionBadge(value: summary.calories, label: "Calories", color: .caloriesColor)
                            NutritionBadge(value: summary.protein, label: "Protein", color: .proteinColor, suffix: "g")
                            NutritionBadge(value: summary.carbs, label: "Carbs", color: .carbsColor, suffix: "g")
                            NutritionBadge(value: summary.fat, label: "Fat", color: .fatColor, suffix: "g")
                        }
                        .padding(.horizontal) // Added padding
                    }
                    
                    // Food Items
                    if let items = meal.analysis?.items, !items.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Food Items")
                                .font(.headline)
                            
                            ForEach(items) { item in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .fontWeight(.medium)
                                        Text(item.quantity)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(item.nutrition.calories) kcal")
                                        .foregroundColor(.caloriesColor)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal) // Added padding
                    }
                    
                    // Feedback
                    if let feedback = meal.analysis?.feedback {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("💡 AI Feedback")
                                .font(.headline)
                            Text(feedback)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal) // Match horizontal padding with other elements
                    }
                 
                }
                .padding(.bottom)
            }
            .navigationTitle("Meal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        dismiss()
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}

// MARK: - Nutrition Badge
struct NutritionBadge: View {
    let value: Int
    let label: String
    let color: Color
    var suffix: String = ""
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)\(suffix)")
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Date Extension for Identifiable
extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

// MARK: - Statistics Content Extension
extension DashboardView {
    var statisticsContent: some View {
        VStack(spacing: 20) {
            // Weekly Summary Card
            VStack(spacing: 16) {
                HStack {
                    Text("📊")
                    Text("Weekly Summary")
                        .font(.headline)
                }
                
                HStack(spacing: 20) {
                    VStack {
                        Text("\(viewModel.weeklyAverage)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.caloriesColor)
                        Text("Avg/Day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack {
                        Text("\(viewModel.weeklyTotal.calories)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.appPrimary)
                        Text("Total kcal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack {
                        Text("\(viewModel.weeklyMeals.count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Meals")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .liquidGlass()
            .smartZoomEffect()
            
            // Weekly Chart
            WeeklyChartView(
                data: viewModel.weeklyCalorieData,
                target: viewModel.targets.calories,
                onDayTap: { date in
                    viewModel.selectDay(date)
                }
            )
            .smartZoomEffect()
            
            // Weekly Macros
            VStack(alignment: .leading, spacing: 12) {
                Text("📈 Weekly Nutrition")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    MacroSummaryCard(
                        title: "Protein",
                        value: viewModel.weeklyTotal.protein,
                        color: .proteinColor
                    )
                    MacroSummaryCard(
                        title: "Carbs",
                        value: viewModel.weeklyTotal.carbs,
                        color: .carbsColor
                    )
                    MacroSummaryCard(
                        title: "Fat",
                        value: viewModel.weeklyTotal.fat,
                        color: .fatColor
                    )
                }
            }
            .padding()
            .liquidGlass()
            .smartZoomEffect()
            
            // AI Insight Card (matching Web implementation)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("🤖")
                        .font(.title2)
                    Text("AI Insights")
                        .font(.headline)
                    if viewModel.isStatisticsInsightLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                if viewModel.statisticsInsight.isEmpty && !viewModel.isStatisticsInsightLoading {
                    Button {
                        Task {
                            await viewModel.loadStatisticsInsight()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate AI Insight")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appPrimary)
                    }
                    .disabled(!networkMonitor.isConnected)
                    .opacity(networkMonitor.isConnected ? 1 : 0.5)
                    .hapticFeedback(style: .medium)
                    
                    if !networkMonitor.isConnected {
                        Text("Connect to internet to generate insights")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if !viewModel.statisticsInsight.isEmpty {
                    Text(viewModel.statisticsInsight)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }
            }
            .padding()
            .liquidGlass()
            .smartZoomEffect()
            .task {
                // Auto-load insight when viewing statistics
                if viewModel.statisticsInsight.isEmpty {
                    await viewModel.loadStatisticsInsight()
                }
            }
        }
    }
}

// MARK: - Weekly Chart View
struct WeeklyChartView: View {
    let data: [(date: Date, calories: Int)]
    let target: Int
    let onDayTap: (Date) -> Void
    
    private var maxValue: Int {
        max(data.map { $0.calories }.max() ?? 0, target)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📅 This Week")
                .font(.headline)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data, id: \.date) { item in
                    VStack(spacing: 4) {
                        // Bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(item.calories >= target ? Color.green : Color.caloriesColor)
                            .frame(height: maxValue > 0 ? CGFloat(item.calories) / CGFloat(maxValue) * 120 : 0)
                            .frame(minHeight: 4)
                        
                        // Day label
                        Text(item.date.shortDayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        // Calories
                        Text("\(item.calories)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(item.calories > 0 ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        if item.calories > 0 {
                            onDayTap(item.date)
                        }
                    }
                }
            }
            .frame(height: 160)
            
            // Target line info
            HStack {
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 20, height: 3)
                Text("Target: \(target) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .liquidGlass()
    }
}

// MARK: - Macro Summary Card
struct MacroSummaryCard: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)g")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Day Detail Sheet
struct DayDetailSheet: View {
    let date: Date
    let meals: [Meal]
    let targets: NutritionInfo
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    private var dayTotal: NutritionInfo {
        meals.totalNutrition
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary
                    HStack(spacing: 16) {
                        NutritionBadge(value: dayTotal.calories, label: "Calories", color: .caloriesColor)
                        NutritionBadge(value: dayTotal.protein, label: "Protein", color: .proteinColor, suffix: "g")
                        NutritionBadge(value: dayTotal.carbs, label: "Carbs", color: .carbsColor, suffix: "g")
                        NutritionBadge(value: dayTotal.fat, label: "Fat", color: .fatColor, suffix: "g")
                    }
                    .padding()
                    .liquidGlass()
                    
                    // Progress vs Target
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress vs Target")
                            .font(.headline)
                        
                        let progress = min(Double(dayTotal.calories) / Double(targets.calories), 1.0)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.2))
                                Capsule()
                                    .fill(dayTotal.calories > targets.calories ? Color.orange : Color.green)
                                    .frame(width: geo.size.width * progress)
                            }
                        }
                        .frame(height: 12)
                        
                        Text("\(dayTotal.calories) of \(targets.calories) kcal (\(Int(progress * 100))%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .liquidGlass()
                    
                    // Meals List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🍽️ Meals (\(meals.count))")
                            .font(.headline)
                        
                        if meals.isEmpty {
                            Text("No meals logged this day")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                                HStack {
                                    Text(meal.mealIcon(index: index))
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading) {
                                        Text(meal.mealType?.displayName ?? "Meal")
                                            .fontWeight(.medium)
                                        Text(meal.formattedTime)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(meal.analysis?.summary.calories ?? 0) kcal")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.caloriesColor)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .liquidGlass()
                }
                .padding()
            }
            .navigationTitle(date.formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Date Extension for Short Day Name
extension Date {
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
}

#Preview {
    DashboardView()
}

// MARK: - Macro Detail Sheet
struct MacroDetailSheet: View {
    let item: NutritionEducationItem
    let viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Chart
                    NutrientChartView(
                        data: viewModel.getWeeklyData(for: item.id),
                        target: getTarget(for: item.id),
                        color: getColor(for: item.id),
                        unit: item.id == "calories" ? "kcal" : "g"
                    )
                    .frame(height: 200)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    
                    // Education Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text("📖 Knowledge")
                            .font(.headline)
                        
                        Text(item.content)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(6)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func getTarget(for id: String) -> Int {
        switch id {
        case "calories": return viewModel.targets.calories
        case "protein": return viewModel.targets.protein
        case "carbs": return viewModel.targets.carbs
        case "fat": return viewModel.targets.fat
        default: return 0
        }
    }
    
    private func getColor(for id: String) -> Color {
        switch id {
        case "calories": return .caloriesColor
        case "protein": return .proteinColor
        case "carbs": return .carbsColor
        case "fat": return .fatColor
        default: return .gray
        }
    }
}

// MARK: - Nutrient Chart View
struct NutrientChartView: View {
    let data: [(date: Date, value: Int)]
    let target: Int
    let color: Color
    let unit: String
    
    private var maxValue: Int {
        max(data.map { $0.value }.max() ?? 0, target)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Trend")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data, id: \.date) { item in
                    VStack(spacing: 4) {
                        // Bar
                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(item.value >= target ? Color.green : color)
                                    .frame(height: maxValue > 0 ? CGFloat(item.value) / CGFloat(maxValue) * geo.size.height : 0)
                            }
                        }
                        .frame(minHeight: 4)
                        
                        // Day label
                        Text(item.date.shortDayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            // Target line info
            HStack {
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 20, height: 3)
                Text("Target: \(target) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
