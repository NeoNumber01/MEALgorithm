import SwiftUI

// MARK: - Recommendations View (Premium Redesign)
/// Apple Design Award 级别的 Suggestions 界面
/// 遵循 Dashboard 的设计语言：Nebula 背景、玻璃磨砂材质、霓虹发光
struct RecommendationsView: View {
    @StateObject private var viewModel = RecommendationsViewModel()
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var showPreferences = false
    @Namespace private var viewModeAnimation
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Premium Nebula Background
                nebulaBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.large) {
                        // Header
                        headerSection
                        
                        // Preferences Panel Preview
                        preferencesButton
                        
                        // Premium View Toggle
                        viewToggle
                        
                        // Content
                        if viewModel.viewMode == .nextMeal {
                            nextMealContent
                        } else {
                            dayPlanContent
                        }
                    }
                    .padding(.horizontal, Spacing.horizontalPadding)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle("Suggestions")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPreferences) {
                PreferencesPanel(
                    onSave: {
                        viewModel.resetCache()
                        Task {
                            await viewModel.onViewModeChange()
                        }
                    }
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: .profileDidUpdate)) { _ in
                viewModel.resetCache()
                Task {
                    await viewModel.onViewModeChange()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .mealDidSave)) { _ in
                viewModel.resetCache()
                Task {
                    await viewModel.onViewModeChange()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .mealDidDelete)) { _ in
                viewModel.resetCache()
                Task {
                    await viewModel.onViewModeChange()
                }
            }
        }
    }
    
    // MARK: - Nebula Background
    private var nebulaBackground: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            GeometryReader { geo in
                // Primary Green Orb (for Suggestions theme)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.green.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.5
                        )
                    )
                    .frame(width: geo.size.width * 0.8)
                    .blur(radius: 60)
                    .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.1)
                
                // Secondary Teal Orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.teal.opacity(0.25), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.4
                        )
                    )
                    .frame(width: geo.size.width * 0.6)
                    .blur(radius: 50)
                    .offset(x: geo.size.width * 0.5, y: geo.size.height * 0.5)
                
                // Accent Cyan Orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appPrimary.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.3
                        )
                    )
                    .frame(width: geo.size.width * 0.5)
                    .blur(radius: 40)
                    .offset(x: geo.size.width * 0.2, y: geo.size.height * 0.3)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            // AI Badge
            HStack(spacing: Spacing.small) {
                Text("💡")
                Text("Powered by Gemini AI")
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(.ultraThinMaterial)
            .foregroundColor(.green)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            
            Spacer()
            
            // Refresh Button
            Button {
                Task {
                    if viewModel.viewMode == .nextMeal {
                        await viewModel.refreshNextMeal()
                    } else {
                        await viewModel.refreshDayPlan()
                    }
                }
                HapticManager.shared.impact(style: .medium)
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                    
                    if viewModel.isLoadingNextMeal || viewModel.isLoadingDayPlan {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.green)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                .neonGlow(color: .green, radius: 8)
            }
            .disabled(viewModel.isLoadingNextMeal || viewModel.isLoadingDayPlan || !networkMonitor.isConnected)
            .opacity(networkMonitor.isConnected ? 1.0 : 0.5)
            .cardPressEffect()
        }
        .padding(.top, Spacing.medium)
    }
    
    // MARK: - Preferences Button
    private var preferencesButton: some View {
        Button {
            showPreferences = true
            HapticManager.shared.impact(style: .light)
        } label: {
            HStack(spacing: Spacing.medium) {
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
                        .neonGlow(color: .green, radius: 8)
                    
                    Text("🍽️")
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Food Preferences")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Customize AI suggestions")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(Spacing.medium)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .cardPressEffect()
    }
    
    // MARK: - Premium View Toggle
    private var viewToggle: some View {
        HStack(spacing: 0) {
            ForEach([RecommendationsViewModel.ViewMode.nextMeal, .dayPlan], id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.viewMode = mode
                    }
                    HapticManager.shared.impact(style: .light)
                } label: {
                    HStack(spacing: 6) {
                        Text(mode == .nextMeal ? "🍽️" : "📅")
                        Text(mode == .nextMeal ? "Next Meal" : "Day Plan")
                            .font(.system(size: 14, weight: .semibold))
                        
                        if (mode == .nextMeal && viewModel.isLoadingNextMeal) ||
                           (mode == .dayPlan && viewModel.isLoadingDayPlan) {
                            ProgressView()
                                .scaleEffect(0.6)
                                .tint(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.viewMode == mode
                        ? AnyView(
                            Capsule()
                                .fill(.white)
                                .matchedGeometryEffect(id: "viewToggle", in: viewModeAnimation)
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
    
    // MARK: - Next Meal Content
    private var nextMealContent: some View {
        VStack(spacing: Spacing.large) {
            if viewModel.isLoadingNextMeal {
                // Skeleton State
                PremiumContextCard(targetCalories: 2000, recentAvg: 500, goal: "Loading...")
                    .skeleton(isLoading: true)
                
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonRecommendationCard()
                }
            } else if viewModel.recommendations.isEmpty {
                PremiumEmptyStateCard(
                    icon: "🍽️",
                    title: "No Suggestions Yet",
                    message: "Tap the refresh button above to get personalized meal recommendations.",
                    actionLabel: networkMonitor.isConnected ? "Generate Suggestions" : nil,
                    action: {
                        Task {
                            await viewModel.refreshNextMeal()
                        }
                    }
                )
            } else {
                // Context Card
                if let context = viewModel.recommendationContext {
                    PremiumContextCard(
                        targetCalories: context.targetCalories,
                        recentAvg: context.recentAvgCalories,
                        goal: context.goal ?? "General Health"
                    )
                }
                
                // Recommendations
                ForEach(Array(viewModel.recommendations.enumerated()), id: \.element.id) { index, rec in
                    PremiumRecommendationCard(
                        recommendation: rec,
                        rank: index + 1
                    )
                }
                
                // Refresh Button
                refreshButton(isLoading: viewModel.isLoadingNextMeal) {
                    Task {
                        await viewModel.refreshNextMeal()
                    }
                }
            }
        }
    }
    
    // MARK: - Day Plan Content
    private var dayPlanContent: some View {
        VStack(spacing: Spacing.large) {
            if viewModel.isLoadingDayPlan {
                // Skeleton State
                PremiumDayProgressCard(context: DayPlanContext(
                    targetCalories: 2000,
                    consumedCalories: 1000,
                    remainingCalories: 1000,
                    eatenMealTypes: [],
                    remainingMealTypes: ["Lunch", "Dinner"]
                ))
                .skeleton(isLoading: true)
                
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonDayPlanCard()
                }
            } else if viewModel.dayPlan.isEmpty && viewModel.dayContext == nil {
                PremiumEmptyStateCard(
                    icon: "📅",
                    title: "No Day Plan Yet",
                    message: "Tap the refresh button above to generate a personalized day plan.",
                    actionLabel: networkMonitor.isConnected ? "Generate Day Plan" : nil,
                    action: {
                        Task {
                            await viewModel.refreshDayPlan()
                        }
                    }
                )
            } else {
                // Progress Context
                if let context = viewModel.dayContext {
                    PremiumDayProgressCard(context: context)
                }
                
                // Day Plan Meals
                if viewModel.dayPlan.isEmpty {
                    CompletedMealsCard()
                } else {
                    ForEach(viewModel.dayPlan) { meal in
                        PremiumDayPlanMealCard(meal: meal)
                    }
                }
                
                // Day Summary
                if let summary = viewModel.daySummary, !viewModel.dayPlan.isEmpty {
                    PremiumDaySummaryCard(summary: summary)
                }
                
                // Refresh Button
                refreshButton(isLoading: viewModel.isLoadingDayPlan) {
                    Task {
                        await viewModel.refreshDayPlan()
                    }
                }
            }
        }
    }
    
    // MARK: - Refresh Button
    private func refreshButton(isLoading: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: Spacing.small) {
            Button {
                action()
                HapticManager.shared.impact(style: .medium)
            } label: {
                HStack(spacing: Spacing.small) {
                    if isLoading {
                        ProgressView()
                            .tint(.green)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(isLoading ? "Generating..." : "Get New Suggestions")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.green)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(isLoading || !networkMonitor.isConnected)
            .cardPressEffect()
            
            if !networkMonitor.isConnected {
                Text("Connect to internet for new suggestions")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

// MARK: - Premium Context Card
struct PremiumContextCard: View {
    let targetCalories: Int
    let recentAvg: Int
    let goal: String
    
    var body: some View {
        VStack(spacing: Spacing.medium) {
            Text("✨ Personalized For You")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: Spacing.medium) {
                ContextStatItem(value: "\(targetCalories)", label: "Daily Target", icon: "🎯")
                ContextStatItem(value: "\(recentAvg)", label: "Avg/Meal", icon: "📊")
                ContextStatItem(value: goal, label: "Goal", icon: "💪")
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.appPrimary, .appSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .neonGlow(color: .appPrimary, radius: 15)
    }
}

// MARK: - Context Stat Item
struct ContextStatItem: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Premium Recommendation Card
struct PremiumRecommendationCard: View {
    let recommendation: Recommendation
    let rank: Int
    
    private var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "🍽️"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header
            HStack {
                Text(recommendation.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(rankEmoji)
                    .font(.title2)
            }
            
            // Description
            Text(recommendation.description)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
            
            // Reason Badge
            HStack(spacing: Spacing.small) {
                Text("💡")
                Text(recommendation.reason)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(Spacing.small)
            .background(Color.green.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            
            // Nutrition Grid
            HStack(spacing: Spacing.small) {
                PremiumNutritionMiniCard(value: recommendation.nutrition.calories, label: "kcal", color: .caloriesColor)
                PremiumNutritionMiniCard(value: recommendation.nutrition.protein, label: "protein", color: .proteinColor)
                PremiumNutritionMiniCard(value: recommendation.nutrition.carbs, label: "carbs", color: .carbsColor)
                PremiumNutritionMiniCard(value: recommendation.nutrition.fat, label: "fat", color: .fatColor)
            }
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .cardPressEffect()
    }
}

// MARK: - Premium Nutrition Mini Card
struct PremiumNutritionMiniCard: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.small)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Premium Day Progress Card
struct PremiumDayProgressCard: View {
    let context: DayPlanContext
    
    var body: some View {
        VStack(spacing: Spacing.medium) {
            Text("📊 Today's Progress")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: Spacing.small) {
                DayProgressItem(value: "\(context.consumedCalories)", label: "Consumed", color: .caloriesColor)
                DayProgressItem(value: "\(context.remainingCalories)", label: "Remaining", color: .green)
                DayProgressItem(value: "\(context.targetCalories)", label: "Target", color: .appPrimary)
                DayProgressItem(value: "\(context.remainingMealTypes.count)", label: "Meals Left", color: .teal)
            }
            
            if !context.eatenMealTypes.isEmpty {
                HStack(spacing: 4) {
                    Text("✅")
                    Text("Already eaten: \(context.eatenMealTypes.map { $0.capitalized }.joined(separator: ", "))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.green, .teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .neonGlow(color: .green, radius: 15)
    }
}

// MARK: - Day Progress Item
struct DayProgressItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Premium Day Plan Meal Card
struct PremiumDayPlanMealCard: View {
    let meal: DayPlanMeal
    
    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Meal Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.3), .teal.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Text(meal.icon)
                    .font(.system(size: 28))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.mealType.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.green)
                
                Text(meal.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(meal.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
                
                HStack(spacing: Spacing.medium) {
                    MacroLabel(icon: "🥩", value: meal.nutrition.protein, color: .proteinColor)
                    MacroLabel(icon: "🍞", value: meal.nutrition.carbs, color: .carbsColor)
                    MacroLabel(icon: "🧈", value: meal.nutrition.fat, color: .fatColor)
                }
            }
            
            Spacer()
            
            VStack {
                Text("\(meal.nutrition.calories)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.caloriesColor)
                Text("kcal")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .cardPressEffect()
    }
}

// MARK: - Macro Label
struct MacroLabel: View {
    let icon: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(icon)
                .font(.system(size: 10))
            Text("\(value)g")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Premium Day Summary Card
struct PremiumDaySummaryCard: View {
    let summary: DayPlanSummary
    
    var body: some View {
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
                        .frame(width: 36, height: 36)
                        .neonGlow(color: .green, radius: 6)
                    
                    Text("💡")
                        .font(.body)
                }
                
                Text("AI Coach Advice")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(summary.advice)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
            
            Text("Planned: \(summary.totalPlannedCalories) kcal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.green)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .gradientBorder(colors: [.green.opacity(0.6), .teal.opacity(0.3)], lineWidth: 1.5)
    }
}

// MARK: - Premium Empty State Card
struct PremiumEmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.green.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Text(icon)
                    .font(.system(size: 56))
            }
            
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            if let label = actionLabel, let action = action {
                Button {
                    action()
                    HapticManager.shared.impact(style: .medium)
                } label: {
                    Text(label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.green, .teal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .neonGlow(color: .green, radius: 10)
                }
                .cardPressEffect()
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Completed Meals Card
struct CompletedMealsCard: View {
    var body: some View {
        VStack(spacing: Spacing.medium) {
            Text("🎉")
                .font(.system(size: 56))
            
            Text("You've completed all meals for today!")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Skeleton Cards
struct SkeletonRecommendationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 150, height: 20)
                Spacer()
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 32, height: 32)
            }
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(height: 40)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .frame(height: 32)
            
            HStack(spacing: Spacing.small) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 48)
                }
            }
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .shimmering(active: true)
    }
}

struct SkeletonDayPlanCard: View {
    var body: some View {
        HStack(spacing: Spacing.medium) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 56, height: 56)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 16)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 28)
            }
            
            Spacer()
            
            VStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 24)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 30, height: 12)
            }
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .shimmering(active: true)
    }
}

// MARK: - Legacy Components (kept for compatibility)
struct LoadingCard: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.green)
            Text(message)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(48)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        PremiumEmptyStateCard(icon: icon, title: title, message: message)
    }
}

struct ContextCard: View {
    let targetCalories: Int
    let recentAvg: Int
    let goal: String
    
    var body: some View {
        PremiumContextCard(targetCalories: targetCalories, recentAvg: recentAvg, goal: goal)
    }
}

struct RecommendationCard: View {
    let recommendation: Recommendation
    let rank: Int
    
    var body: some View {
        PremiumRecommendationCard(recommendation: recommendation, rank: rank)
    }
}

struct NutritionMiniCard: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        PremiumNutritionMiniCard(value: value, label: label, color: color)
    }
}

struct DayProgressCard: View {
    let context: DayPlanContext
    
    var body: some View {
        PremiumDayProgressCard(context: context)
    }
}

struct DayPlanMealCard: View {
    let meal: DayPlanMeal
    
    var body: some View {
        PremiumDayPlanMealCard(meal: meal)
    }
}

struct DaySummaryCard: View {
    let summary: DayPlanSummary
    
    var body: some View {
        PremiumDaySummaryCard(summary: summary)
    }
}

// MARK: - Preferences Panel
struct PreferencesPanel: View {
    let onSave: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var foodPreferences = ""
    @State private var foodDislikes = ""
    @State private var dietaryRestrictions = ""
    @State private var customNotes = ""
    @State private var isSaving = false
    @State private var isLoading = true
    @State private var message: (type: String, text: String)?
    
    private let profileService = ProfileService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Nebula Background
                Color.appBackground.ignoresSafeArea()
                
                GeometryReader { geo in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.green.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: geo.size.width * 0.5
                            )
                        )
                        .frame(width: geo.size.width * 0.8)
                        .blur(radius: 60)
                        .offset(x: -geo.size.width * 0.2, y: -100)
                }
                .ignoresSafeArea()
                .hideKeyboardOnTap()
                
                if isLoading {
                    VStack(spacing: Spacing.medium) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.green)
                        Text("Loading preferences...")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Spacing.large) {
                            // Info Card
                            HStack(spacing: Spacing.small) {
                                Text("💡")
                                    .font(.title2)
                                Text("Your preferences help us suggest meals you'll actually enjoy!")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(Spacing.medium)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                            
                            // Message
                            if let msg = message {
                                HStack(spacing: Spacing.small) {
                                    Image(systemName: msg.type == "success" ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    Text(msg.text)
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(msg.type == "success" ? .green : .red)
                                .padding(Spacing.medium)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                                        .stroke((msg.type == "success" ? Color.green : Color.red).opacity(0.5), lineWidth: 1)
                                )
                            }
                            
                            // Preference Fields
                            PremiumPreferenceField(
                                icon: "❤️",
                                title: "Foods I Love",
                                placeholder: "e.g., chicken wings, spicy food, Japanese cuisine...",
                                text: $foodPreferences
                            )
                            
                            PremiumPreferenceField(
                                icon: "👎",
                                title: "Foods I Dislike",
                                placeholder: "e.g., cilantro, raw onions, very sour foods...",
                                text: $foodDislikes
                            )
                            
                            PremiumPreferenceField(
                                icon: "⚠️",
                                title: "Dietary Restrictions",
                                placeholder: "e.g., Vegetarian, Gluten-free, Nut allergy...",
                                text: $dietaryRestrictions
                            )
                            
                            PremiumPreferenceField(
                                icon: "💬",
                                title: "Special Requests",
                                placeholder: "e.g., I want healthier eating, quick meals to cook...",
                                text: $customNotes
                            )
                            
                            // Save Button
                            Button {
                                Task {
                                    await savePreferences()
                                }
                                HapticManager.shared.impact(style: .medium)
                            } label: {
                                Group {
                                    if isSaving {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Save Preferences")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .teal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
                                .neonGlow(color: .green, radius: 12)
                            }
                            .disabled(isSaving)
                            .cardPressEffect()
                        }
                        .padding(.horizontal, Spacing.horizontalPadding)
                        .padding(.bottom, 40)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .addDoneButton()
                }
            }
            .navigationTitle("Food Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
            .task {
                await loadPreferences()
            }
        }
    }
    
    private func loadPreferences() async {
        isLoading = true
        do {
            let profile = try await profileService.getProfile()
            foodPreferences = profile.foodPreferences ?? ""
            foodDislikes = profile.foodDislikes ?? ""
            dietaryRestrictions = profile.dietaryRestrictions ?? ""
            customNotes = profile.customNotes ?? ""
        } catch {
            message = ("error", "Failed to load preferences")
        }
        isLoading = false
    }
    
    private func savePreferences() async {
        isSaving = true
        message = nil
        
        do {
            try await profileService.updatePreferences(
                foodPreferences: foodPreferences,
                foodDislikes: foodDislikes,
                dietaryRestrictions: dietaryRestrictions,
                customNotes: customNotes
            )
            message = ("success", "Preferences saved! Refresh suggestions to apply.")
            onSave()
        } catch {
            message = ("error", "Failed to save preferences")
        }
        
        isSaving = false
    }
}

// MARK: - Premium Preference Field
struct PremiumPreferenceField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Text(icon)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(2...4)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(Spacing.medium)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Legacy PreferenceField (kept for compatibility)
struct PreferenceField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        PremiumPreferenceField(icon: icon, title: title, placeholder: placeholder, text: $text)
    }
}

#Preview {
    RecommendationsView()
        .environmentObject(NetworkMonitor.shared)
}
