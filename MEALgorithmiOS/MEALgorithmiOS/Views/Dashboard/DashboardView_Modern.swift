import SwiftUI

// MARK: - Dashboard View (Modern Redesign)
/// Apple Design Award 级别的 Dashboard 界面
/// 遵循 Bento 哲学、Fluid Interfaces 和 State-Driven Design
struct DashboardView_Modern: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Namespace private var heroAnimation
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Premium Nebula Background
                nebulaBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.large) {
                        // MARK: - Hero Header
                        heroHeader
                        
                        if viewModel.viewMode == .today {
                            todayContent
                        } else {
                            statisticsContent
                        }
                    }
                    .padding(.horizontal, Spacing.horizontalPadding)
                    .padding(.bottom, 120)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .task {
                await viewModel.loadData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .mealDidSave)) { _ in
                Task {
                    await viewModel.refresh()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .mealDidDelete)) { _ in
                Task {
                    await viewModel.refresh()
                }
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
            .sheet(item: $viewModel.selectedStatsCard) { cardType in
                StatsDetailSheet(cardType: cardType, viewModel: viewModel)
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
    
    // MARK: - Nebula Background
    private var nebulaBackground: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            // Ambient Glow Orbs
            GeometryReader { geo in
                // Primary Cyan Orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appPrimary.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.5
                        )
                    )
                    .frame(width: geo.size.width * 0.8)
                    .blur(radius: 60)
                    .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.1)
                
                // Secondary Green Orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appSecondary.opacity(0.25), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.4
                        )
                    )
                    .frame(width: geo.size.width * 0.6)
                    .blur(radius: 50)
                    .offset(x: geo.size.width * 0.5, y: geo.size.height * 0.5)
                
                // Accent Orange Orb (for calories)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.caloriesStart.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.3
                        )
                    )
                    .frame(width: geo.size.width * 0.5)
                    .blur(radius: 40)
                    .offset(x: geo.size.width * 0.2, y: geo.size.height * 0.2)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Hero Header
    private var heroHeader: some View {
        VStack(spacing: Spacing.medium) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.viewMode == .today ? "Today's Overview" : "Statistics & History")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .tracking(-1.0)
                        .foregroundColor(.white)
                    
                    Text(Date().formattedDate)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Premium Toggle Pill
                viewModeToggle
            }
        }
        .padding(.top, Spacing.medium)
        .skeleton(isLoading: viewModel.isLoading)
    }
    
    // MARK: - View Mode Toggle
    private var viewModeToggle: some View {
        HStack(spacing: 0) {
            ForEach([DashboardViewModel.ViewMode.today, .statistics], id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.viewMode = mode
                    }
                    HapticManager.shared.impact(style: .light)
                } label: {
                    Text(mode == .today ? "Today" : "Stats")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.viewMode == mode
                            ? AnyView(
                                Capsule()
                                    .fill(.white)
                                    .matchedGeometryEffect(id: "toggle", in: heroAnimation)
                            )
                            : AnyView(Color.clear)
                        )
                        .foregroundColor(viewModel.viewMode == mode ? .black : .white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Today Content
    private var todayContent: some View {
        VStack(spacing: Spacing.large) {
            // Premium Calorie Ring
            premiumCalorieRing
                .skeleton(isLoading: viewModel.isLoading)
                .smartZoomEffect()
            
            // Bento Macro Grid
            bentoMacroGrid
                .skeleton(isLoading: viewModel.isLoading)
                .smartZoomEffect()
            
            // AI Coach Card
            if !viewModel.aiFeedback.isEmpty || viewModel.isFeedbackLoading {
                aiCoachCard
            }
            
            // Timeline Meals
            timelineMealsSection
        }
    }
    
    // MARK: - Premium Calorie Ring
    private var premiumCalorieRing: some View {
        let progress = viewModel.targets.calories > 0
            ? min(Double(viewModel.todayTotals.calories) / Double(viewModel.targets.calories), 1.0)
            : 0
        
        return Button {
            viewModel.selectMacro("calories")
            HapticManager.shared.impact(style: .medium)
        } label: {
            VStack(spacing: Spacing.medium) {
                ZStack {
                    // Background Ring
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 24)
                    
                    // Progress Ring with Neon Glow
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                colors: [.caloriesStart, .caloriesEnd, .caloriesStart],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 24, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .neonGlow(color: .caloriesEnd, radius: 20)
                        .animation(.spring(response: 1.2, dampingFraction: 0.8), value: progress)
                    
                    // Center Content
                    VStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 36))
                        
                        Text("\(viewModel.todayTotals.calories)")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("of \(viewModel.targets.calories) kcal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(width: 220, height: 220)
                
                Text("Today's Calories")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(Spacing.large)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .cardPressEffect()
    }
    
    // MARK: - Bento Macro Grid
    private var bentoMacroGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Spacing.medium),
            GridItem(.flexible(), spacing: Spacing.medium),
            GridItem(.flexible(), spacing: Spacing.medium)
        ], spacing: Spacing.medium) {
            BentoMacroCard(
                title: "Protein",
                icon: "🥩",
                current: viewModel.todayTotals.protein,
                target: viewModel.targets.protein,
                colors: [.proteinStart, .proteinEnd]
            ) {
                viewModel.selectMacro("protein")
            }
            
            BentoMacroCard(
                title: "Carbs",
                icon: "🍞",
                current: viewModel.todayTotals.carbs,
                target: viewModel.targets.carbs,
                colors: [.carbsStart, .carbsEnd]
            ) {
                viewModel.selectMacro("carbs")
            }
            
            BentoMacroCard(
                title: "Fat",
                icon: "🧈",
                current: viewModel.todayTotals.fat,
                target: viewModel.targets.fat,
                colors: [.fatStart, .fatEnd]
            ) {
                viewModel.selectMacro("fat")
            }
        }
    }
    
    // MARK: - AI Coach Card
    private var aiCoachCard: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(spacing: Spacing.small) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .neonGlow(color: .green, radius: 10)
                    
                    Text("🤖")
                        .font(.title2)
                }
                
                Text("AI Coach Insight")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if viewModel.isFeedbackLoading {
                    ProgressView()
                        .tint(.green)
                }
            }
            
            if viewModel.isFeedbackLoading {
                Text("Analyzing your progress...")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
            } else {
                Text(viewModel.aiFeedback)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .gradientBorder(colors: [.green.opacity(0.6), .teal.opacity(0.3)], lineWidth: 1.5)
        .smartZoomEffect()
    }
    
    // MARK: - Timeline Meals Section
    private var timelineMealsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text("🍽️")
                    .font(.title2)
                Text("Today's Meals")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(viewModel.todayMeals.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            if viewModel.isLoading {
                // Skeleton Meals
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonMealRow()
                }
            } else if viewModel.todayMeals.isEmpty {
                // Empty State
                VStack(spacing: Spacing.medium) {
                    Text("🍽️")
                        .font(.system(size: 48))
                    
                    Text("No meals logged yet")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Start tracking your nutrition today!")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
            } else {
                // Timeline Meals
                ForEach(Array(viewModel.todayMeals.enumerated()), id: \.element.id) { index, meal in
                    TimelineMealRow(
                        meal: meal,
                        index: index,
                        isLast: index == viewModel.todayMeals.count - 1
                    ) {
                        viewModel.selectedMeal = meal
                    }
                }
            }
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .smartZoomEffect()
    }
    
    // MARK: - Statistics Content
    private var statisticsContent: some View {
        VStack(spacing: Spacing.large) {
            // Weekly Summary Card (Tappable)
            Button {
                viewModel.selectedStatsCard = .weeklySummary
                HapticManager.shared.impact(style: .medium)
            } label: {
                VStack(spacing: Spacing.medium) {
                    HStack {
                        Text("📊")
                            .font(.title2)
                        Text("Weekly Summary")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: Spacing.medium) {
                        StatBadge(
                            value: "\(viewModel.weeklyAverage)",
                            label: "Avg/Day",
                            color: .caloriesColor
                        )
                        
                        StatBadge(
                            value: "\(viewModel.weeklyTotal.calories)",
                            label: "Total kcal",
                            color: .appPrimary
                        )
                        
                        StatBadge(
                            value: "\(viewModel.weeklyMeals.count)",
                            label: "Meals",
                            color: .green
                        )
                    }
                }
                .padding(Spacing.medium)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            }
            .buttonStyle(.plain)
            .cardPressEffect()
            .smartZoomEffect()
            
            // Weekly Chart (Tappable)
            Button {
                viewModel.selectedStatsCard = .weeklyChart
                HapticManager.shared.impact(style: .medium)
            } label: {
                WeeklyChartView(
                    data: viewModel.weeklyCalorieData,
                    target: viewModel.targets.calories,
                    onDayTap: { date in
                        viewModel.selectDay(date)
                    }
                )
            }
            .buttonStyle(.plain)
            .cardPressEffect()
            .smartZoomEffect()
            
            // Weekly Macros (Tappable)
            Button {
                viewModel.selectedStatsCard = .weeklyNutrition
                HapticManager.shared.impact(style: .medium)
            } label: {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    HStack {
                        Text("📈")
                            .font(.title2)
                        Text("Weekly Nutrition")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    HStack(spacing: Spacing.medium) {
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
                .padding(Spacing.medium)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            }
            .buttonStyle(.plain)
            .cardPressEffect()
            .smartZoomEffect()
            
            // AI Insights
            aiInsightsCard
        }
    }
    
    // MARK: - AI Insights Card (Statistics)
    private var aiInsightsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text("🤖")
                    .font(.title2)
                Text("AI Insights")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if viewModel.isStatisticsInsightLoading {
                    ProgressView()
                        .tint(.appPrimary)
                }
            }
            
            if viewModel.statisticsInsight.isEmpty && !viewModel.isStatisticsInsightLoading {
                Button {
                    Task {
                        await viewModel.loadStatisticsInsight()
                    }
                    HapticManager.shared.impact(style: .medium)
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate AI Insight")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.appPrimary.opacity(0.15))
                    .clipShape(Capsule())
                }
                .disabled(!networkMonitor.isConnected)
                .opacity(networkMonitor.isConnected ? 1 : 0.5)
                
                if !networkMonitor.isConnected {
                    Text("Connect to internet to generate insights")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            } else if !viewModel.statisticsInsight.isEmpty {
                Text(viewModel.statisticsInsight)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .smartZoomEffect()
        .task {
            if viewModel.statisticsInsight.isEmpty {
                await viewModel.loadStatisticsInsight()
            }
        }
    }
}

// MARK: - Bento Macro Card
struct BentoMacroCard: View {
    let title: String
    let icon: String
    let current: Int
    let target: Int
    let colors: [Color]
    let onTap: () -> Void
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        Button(action: {
            onTap()
            HapticManager.shared.impact(style: .medium)
        }) {
            VStack(spacing: Spacing.small) {
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
                    
                    Text(icon)
                        .font(.system(size: 20))
                }
                .frame(width: 50, height: 50)
                .neonGlow(color: colors.last ?? .white, radius: 8)
                
                VStack(spacing: 2) {
                    Text("\(current)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("/\(target)g")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(colors.last ?? .white)
            }
            .padding(.vertical, Spacing.medium)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                    .stroke(colors.last?.opacity(0.3) ?? .clear, lineWidth: 1)
            )
        }
        .cardPressEffect()
    }
}

// MARK: - Timeline Meal Row
struct TimelineMealRow: View {
    let meal: Meal
    let index: Int
    let isLast: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            onTap()
            HapticManager.shared.impact(style: .light)
        }) {
            HStack(alignment: .top, spacing: Spacing.medium) {
                // Timeline Indicator
                VStack(spacing: 0) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.caloriesStart, .caloriesEnd],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 12, height: 12)
                        .neonGlow(color: .caloriesEnd, radius: 5)
                    
                    if !isLast {
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 2)
                            .frame(height: 60)
                    }
                }
                
                // Meal Info
                HStack(spacing: Spacing.medium) {
                    Text(meal.mealIcon(index: index))
                        .font(.title)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.mealType?.displayName ?? "Meal")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(meal.formattedTime)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(meal.analysis?.summary.calories ?? 0)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.caloriesColor)
                        
                        Text("kcal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(Spacing.medium)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Skeleton Meal Row
struct SkeletonMealRow: View {
    var body: some View {
        HStack(spacing: Spacing.medium) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 12, height: 12)
            
            HStack(spacing: Spacing.medium) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 80, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 50, height: 10)
                }
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 18)
            }
            .padding(Spacing.medium)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .shimmering(active: true)
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    DashboardView_Modern()
        .environmentObject(NetworkMonitor.shared)
}
