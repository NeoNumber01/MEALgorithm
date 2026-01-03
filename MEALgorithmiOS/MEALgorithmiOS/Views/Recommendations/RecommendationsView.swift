import SwiftUI

// MARK: - Recommendations View
struct RecommendationsView: View {
    @StateObject private var viewModel = RecommendationsViewModel()
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var showPreferences = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.green.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection
                        
                        // Preferences Panel Preview
                        preferencesButton
                        
                        // View Toggle
                        viewToggle
                        
                        // Content
                        if viewModel.viewMode == .nextMeal {
                            nextMealContent
                        } else {
                            dayPlanContent
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Suggestions")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.onViewModeChange()
            }
            .onChange(of: viewModel.viewMode) { _, _ in
                Task {
                    await viewModel.onViewModeChange()
                }
            }
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
        }
    }
    
    // MARK: - Preferences Button
    private var preferencesButton: some View {
        Button {
            showPreferences = true
        } label: {
            HStack {
                Text("🍽️")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Food Preferences")
                        .fontWeight(.semibold)
                    Text("Customize AI suggestions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .liquidGlass()
        }
        .foregroundColor(.primary)
        .hapticFeedback(style: .light)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("💡")
            Text("Powered by Gemini AI")
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.green.opacity(0.1))
        .foregroundColor(.green)
        .cornerRadius(20)
    }
    
    // MARK: - View Toggle
    private var viewToggle: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.viewMode = .nextMeal
            } label: {
                HStack {
                    Text("🍽️ Next Meal")
                    if viewModel.isLoadingNextMeal {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(viewModel.viewMode == .nextMeal ? Color(.systemBackground) : Color.clear)
                .cornerRadius(8)
                .shadow(color: viewModel.viewMode == .nextMeal ? .black.opacity(0.05) : .clear, radius: 4)
            }
            .foregroundColor(viewModel.viewMode == .nextMeal ? .primary : .secondary)
            
            Button {
                viewModel.viewMode = .dayPlan
            } label: {
                HStack {
                    Text("📅 Day Plan")
                    if viewModel.isLoadingDayPlan {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(viewModel.viewMode == .dayPlan ? Color(.systemBackground) : Color.clear)
                .cornerRadius(8)
                .shadow(color: viewModel.viewMode == .dayPlan ? .black.opacity(0.05) : .clear, radius: 4)
            }
            .foregroundColor(viewModel.viewMode == .dayPlan ? .primary : .secondary)
            .hapticFeedback(style: .light)
        }
        .padding(4)
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
    
    // MARK: - Next Meal Content
    private var nextMealContent: some View {
        VStack(spacing: 16) {
            if viewModel.isLoadingNextMeal {
                // Skeleton State
                ContextCard(targetCalories: 2000, recentAvg: 500, goal: "Loading...")
                    .skeleton(isLoading: true)
                
                ForEach(0..<3) { _ in
                    RecommendationCard(
                        recommendation: Recommendation(
                            name: "Loading Meal Name",
                            description: "Loading description of the meal...",
                            reason: "Loading reason...",
                            nutrition: .zero
                        ),
                        rank: 1
                    )
                    .skeleton(isLoading: true)
                }
            } else if viewModel.recommendations.isEmpty {
                LoadingCard(message: "Finding meal ideas...")
            } else {
                // Context Card
                if let context = viewModel.recommendationContext {
                    ContextCard(
                        targetCalories: context.targetCalories,
                        recentAvg: context.recentAvgCalories,
                        goal: context.goal ?? "General Health"
                    )
                }
                
                // Recommendations Grid
                ForEach(Array(viewModel.recommendations.enumerated()), id: \.element.id) { index, rec in
                    RecommendationCard(
                        recommendation: rec,
                        rank: index + 1
                    )
                }
                
                // Refresh Button
                Button {
                    Task {
                        await viewModel.refreshNextMeal()
                    }
                } label: {
                    HStack {
                        if viewModel.isLoadingNextMeal {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(viewModel.isLoadingNextMeal ? "Generating..." : "🔄 Get New Suggestions")
                    }
                    .foregroundColor(.appPrimary)
                    .fontWeight(.medium)
                }
                .disabled(viewModel.isLoadingNextMeal || !networkMonitor.isConnected)
                .opacity(networkMonitor.isConnected ? 1.0 : 0.5)
                .hapticFeedback(style: .medium)
                
                if !networkMonitor.isConnected {
                    Text("Connect to internet for new suggestions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Day Plan Content
    private var dayPlanContent: some View {
        VStack(spacing: 16) {
            if viewModel.isLoadingDayPlan {
                // Skeleton State
                DayProgressCard(context: DayPlanContext(
                    targetCalories: 2000,
                    consumedCalories: 1000,
                    remainingCalories: 1000,
                    eatenMealTypes: [],
                    remainingMealTypes: ["Lunch", "Dinner"]
                ))
                .skeleton(isLoading: true)
                
                ForEach(0..<3) { _ in
                    DayPlanMealCard(meal: DayPlanMeal(
                        mealType: "lunch",
                        name: "Loading Meal...",
                        description: "Loading meal description...",
                        nutrition: .zero
                    ))
                    .skeleton(isLoading: true)
                }
            } else if viewModel.dayPlan.isEmpty && viewModel.dayContext == nil {
                LoadingCard(message: "Planning your day...")
            } else {
                // Progress Context
                if let context = viewModel.dayContext {
                    DayProgressCard(context: context)
                }
                
                // Day Plan Meals
                if viewModel.dayPlan.isEmpty {
                    VStack(spacing: 8) {
                        Text("🎉")
                            .font(.system(size: 48))
                        Text("You've completed all meals for today!")
                            .foregroundColor(.secondary)
                    }
                    .padding(32)
                } else {
                    ForEach(viewModel.dayPlan) { meal in
                        DayPlanMealCard(meal: meal)
                    }
                }
                
                // Day Summary
                if let summary = viewModel.daySummary, !viewModel.dayPlan.isEmpty {
                    DaySummaryCard(summary: summary)
                }
                
                // Refresh Button
                Button {
                    Task {
                        await viewModel.refreshDayPlan()
                    }
                } label: {
                    HStack {
                        if viewModel.isLoadingDayPlan {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(viewModel.isLoadingDayPlan ? "Generating..." : "🔄 Regenerate Day Plan")
                    }
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                }
                .disabled(viewModel.isLoadingDayPlan || !networkMonitor.isConnected)
                .opacity(networkMonitor.isConnected ? 1.0 : 0.5)
                .hapticFeedback(style: .medium)
                
                if !networkMonitor.isConnected {
                    Text("Connect to internet to regenerate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Loading Card
struct LoadingCard: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
        .liquidGlass()
    }
}

// MARK: - Context Card
struct ContextCard: View {
    let targetCalories: Int
    let recentAvg: Int
    let goal: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Personalized For You")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                VStack {
                    Text("\(targetCalories)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Daily Target")
                        .font(.caption)
                        .opacity(0.8)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(recentAvg)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Recent Avg/Meal")
                        .font(.caption)
                        .opacity(0.8)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text(goal)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    Text("Goal")
                        .font(.caption)
                        .opacity(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .foregroundColor(.white)
        .gradientCard(colors: [.appPrimary, .appSecondary])
        .hoverEffect()
    }
}

// MARK: - Recommendation Card
struct RecommendationCard: View {
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(recommendation.name)
                    .font(.headline)
                Spacer()
                Text(rankEmoji)
                    .font(.title2)
            }
            
            Text(recommendation.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("💡")
                Text(recommendation.reason)
                    .font(.caption)
            }
            .padding(8)
            .background(Color.appPrimary.opacity(0.1))
            .cornerRadius(8)
            
            HStack(spacing: 8) {
                NutritionMiniCard(value: recommendation.nutrition.calories, label: "kcal", color: .caloriesColor)
                NutritionMiniCard(value: recommendation.nutrition.protein, label: "protein", color: .proteinColor)
                NutritionMiniCard(value: recommendation.nutrition.carbs, label: "carbs", color: .carbsColor)
                NutritionMiniCard(value: recommendation.nutrition.fat, label: "fat", color: .fatColor)
            }
        }
        .padding()
        .liquidGlass()
        .hoverEffect()
    }
}

// MARK: - Nutrition Mini Card
struct NutritionMiniCard: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Day Progress Card
struct DayProgressCard: View {
    let context: DayPlanContext
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Today's Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                VStack {
                    Text("\(context.consumedCalories)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Consumed")
                        .font(.caption)
                        .opacity(0.8)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(context.remainingCalories)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Remaining")
                        .font(.caption)
                        .opacity(0.8)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(context.targetCalories)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Target")
                        .font(.caption)
                        .opacity(0.8)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(context.remainingMealTypes.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Meals Left")
                        .font(.caption)
                        .opacity(0.8)
                }
                .frame(maxWidth: .infinity)
            }
            
            if !context.eatenMealTypes.isEmpty {
                Text("✅ Already eaten: \(context.eatenMealTypes.map { $0.capitalized }.joined(separator: ", "))")
                    .font(.caption)
                    .opacity(0.8)
            }
        }
        .padding()
        .foregroundColor(.white)
        .gradientCard(colors: [.green, .teal])
        .hoverEffect()
    }
}

// MARK: - Day Plan Meal Card
struct DayPlanMealCard: View {
    let meal: DayPlanMeal
    
    var body: some View {
        HStack(spacing: 16) {
            Text(meal.icon)
                .font(.system(size: 36))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.mealType.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(meal.name)
                    .font(.headline)
                Text(meal.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Text("🥩 \(meal.nutrition.protein)g")
                        .foregroundColor(.proteinColor)
                    Text("🍞 \(meal.nutrition.carbs)g")
                        .foregroundColor(.carbsColor)
                    Text("🧈 \(meal.nutrition.fat)g")
                        .foregroundColor(.fatColor)
                }
                .font(.caption)
            }
            
            Spacer()
            
            VStack {
                Text("\(meal.nutrition.calories)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.caloriesColor)
                Text("kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .liquidGlass()
        .hoverEffect()
    }
}

// MARK: - Day Summary Card
struct DaySummaryCard: View {
    let summary: DayPlanSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💡")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("AI Coach Advice")
                        .font(.headline)
                        .foregroundColor(.appPrimary)
                    Text(summary.advice)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Planned calories: \(summary.totalPlannedCalories) kcal")
                .font(.caption)
                .foregroundColor(.appPrimary)
        }
        .padding()
        .background(Color.appPrimary.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appPrimary.opacity(0.2), lineWidth: 1)
        )
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
                LinearGradient(
                    colors: [Color(.systemBackground), Color.green.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading preferences...")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Info Card
                            HStack {
                                Text("💡")
                                    .font(.title2)
                                Text("Your preferences help us suggest meals you'll actually enjoy!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .liquidGlass()
                            
                            // Message
                            if let msg = message {
                                HStack {
                                    Image(systemName: msg.type == "success" ? "checkmark.circle" : "exclamationmark.circle")
                                    Text(msg.text)
                                }
                                .font(.subheadline)
                                .foregroundColor(msg.type == "success" ? .green : .red)
                                .padding()
                                .background((msg.type == "success" ? Color.green : Color.red).opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Foods I Love
                            PreferenceField(
                                icon: "❤️",
                                title: "Foods I Love",
                                placeholder: "e.g., chicken wings, spicy food, Japanese cuisine...",
                                text: $foodPreferences
                            )
                            
                            // Foods I Dislike
                            PreferenceField(
                                icon: "👎",
                                title: "Foods I Dislike",
                                placeholder: "e.g., cilantro, raw onions, very sour foods...",
                                text: $foodDislikes
                            )
                            
                            // Dietary Restrictions
                            PreferenceField(
                                icon: "⚠️",
                                title: "Dietary Restrictions",
                                placeholder: "e.g., Vegetarian, Gluten-free, Nut allergy...",
                                text: $dietaryRestrictions
                            )
                            
                            // Special Requests
                            PreferenceField(
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
                            } label: {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Save Preferences")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(isSaving)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Food Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
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

// MARK: - Preference Field
struct PreferenceField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                Text(title)
                    .font(.headline)
            }
            
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(2...4)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
        .padding()
        .liquidGlass()
    }
}

#Preview {
    RecommendationsView()
}
