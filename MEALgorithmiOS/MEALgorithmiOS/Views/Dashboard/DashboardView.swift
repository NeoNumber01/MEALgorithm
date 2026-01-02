import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.appPrimary.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView(message: "Loading your nutrition data...")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            headerSection
                            
                            if viewModel.viewMode == .today {
                                todayContent
                            } else {
                                Text("Statistics View")
                                    .foregroundColor(.secondary)
                                // TODO: Add StatisticsView
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100) // Space for tab bar
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
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
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(Date().formattedDate)
                        .foregroundColor(.secondary)
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
                                .background(viewModel.viewMode == mode ? Color(.systemBackground) : Color.clear)
                                .cornerRadius(8)
                        }
                        .foregroundColor(viewModel.viewMode == mode ? .primary : .secondary)
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
            // Calorie Gauge
            CalorieGaugeView(
                current: viewModel.todayTotals.calories,
                target: viewModel.targets.calories
            )
            .frame(height: 250)
            .liquidGlass()
            .hoverEffect()
            
            // Macro Cards
            HStack(spacing: 12) {
                MacroCardView(
                    title: "Protein",
                    icon: "🥩",
                    current: viewModel.todayTotals.protein,
                    target: viewModel.targets.protein,
                    unit: "g",
                    colors: [.proteinColor, .proteinColor.opacity(0.7)]
                )
                
                MacroCardView(
                    title: "Carbs",
                    icon: "🍞",
                    current: viewModel.todayTotals.carbs,
                    target: viewModel.targets.carbs,
                    unit: "g",
                    colors: [.carbsColor, .carbsColor.opacity(0.7)]
                )
                
                MacroCardView(
                    title: "Fat",
                    icon: "🧈",
                    current: viewModel.todayTotals.fat,
                    target: viewModel.targets.fat,
                    unit: "g",
                    colors: [.fatColor, .fatColor.opacity(0.7)]
                )
            }
            
            // AI Feedback
            if !viewModel.aiFeedback.isEmpty || viewModel.isFeedbackLoading {
                AIFeedbackCard(
                    feedback: viewModel.aiFeedback,
                    isLoading: viewModel.isFeedbackLoading
                )
            }
            
            // Today's Meals
            if !viewModel.todayMeals.isEmpty {
                TodayMealsSection(
                    meals: viewModel.todayMeals,
                    onMealTap: { meal in
                        viewModel.selectedMeal = meal
                    }
                )
            } else {
                EmptyStateView(
                    icon: "🍽️",
                    title: "No meals logged yet",
                    message: "Start tracking your nutrition today!"
                )
                .liquidGlass()
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
                        LinearGradient(
                            colors: [.caloriesColor, .carbsColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                // Center text
                VStack(spacing: 4) {
                    Text("\(current)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("of \(target) kcal")
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            
            Text("Today's Calories")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .opacity(0.9)
            
            Text("\(current)\(unit)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("of \(target)\(unit)")
                .font(.caption)
                .opacity(0.8)
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                    
                    Capsule()
                        .fill(Color.white)
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 6)
            
            Text("\(Int(progress * 100))% complete")
                .font(.caption2)
                .opacity(0.7)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .foregroundColor(.white)
        .gradientCard(colors: colors)
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
                    
                    // Nutrition Summary
                    if let summary = meal.analysis?.summary {
                        HStack(spacing: 16) {
                            NutritionBadge(value: summary.calories, label: "Calories", color: .caloriesColor)
                            NutritionBadge(value: summary.protein, label: "Protein", color: .proteinColor, suffix: "g")
                            NutritionBadge(value: summary.carbs, label: "Carbs", color: .carbsColor, suffix: "g")
                            NutritionBadge(value: summary.fat, label: "Fat", color: .fatColor, suffix: "g")
                        }
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
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
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

#Preview {
    DashboardView()
}
