import SwiftUI

// MARK: - Stats Detail Sheet
/// 统计卡片详情弹窗 - 显示详细数据和教育内容
struct StatsDetailSheet: View {
    let cardType: DashboardViewModel.StatsCardType
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Chart Section
                    chartSection
                    
                    // Stats Details
                    detailsSection
                    
                    // Educational Content
                    educationSection
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle(cardType.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Chart Section
    @ViewBuilder
    private var chartSection: some View {
        switch cardType {
        case .weeklySummary:
            weeklySummaryChart
        case .weeklyChart:
            weeklyCalorieChart
        case .weeklyNutrition:
            weeklyNutritionChart
        }
    }
    
    private var weeklySummaryChart: some View {
        VStack(spacing: 16) {
            // Summary Stats
            HStack(spacing: 20) {
                SummaryStatCard(
                    value: "\(viewModel.weeklyAverage)",
                    label: "Daily Avg",
                    unit: "kcal",
                    color: .caloriesColor
                )
                SummaryStatCard(
                    value: "\(viewModel.weeklyTotal.calories)",
                    label: "Total",
                    unit: "kcal",
                    color: .appPrimary
                )
                SummaryStatCard(
                    value: "\(viewModel.weeklyMeals.count)",
                    label: "Meals",
                    unit: "",
                    color: .green
                )
            }
            
            // Progress towards weekly goal
            if viewModel.weeklyMeals.isEmpty {
                emptyStateView(message: "No meals logged this week yet.")
            } else {
                weeklyProgressView
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private var weeklyCalorieChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Calories")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.weeklyMeals.isEmpty {
                emptyStateView(message: "Start logging meals to see your calorie trends.")
            } else {
                // Bar chart
                let calendarData = viewModel.weeklyCalorieData
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<calendarData.count, id: \.self) { index in
                        VStack(spacing: 4) {
                            Text("\(calendarData[index].calories)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    calendarData[index].calories >= viewModel.targets.calories
                                    ? AnyShapeStyle(Color.green)
                                    : AnyShapeStyle(LinearGradient(colors: [.caloriesStart, .caloriesEnd], startPoint: .bottom, endPoint: .top))
                                )
                                .frame(height: chartBarHeight(for: calendarData[index].calories))
                            
                            Text(calendarData[index].date.shortDayName)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 180)
                
                // Target indicator
                HStack {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 20, height: 3)
                    Text("Target: \(viewModel.targets.calories) kcal")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private var weeklyNutritionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macro Breakdown")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.weeklyMeals.isEmpty {
                emptyStateView(message: "Log meals to see your macro distribution.")
            } else {
                // Macro summary cards
                HStack(spacing: 12) {
                    MacroDetailCard(
                        title: "Protein",
                        value: viewModel.weeklyTotal.protein,
                        target: viewModel.targets.protein * 7,
                        color: .proteinColor
                    )
                    MacroDetailCard(
                        title: "Carbs",
                        value: viewModel.weeklyTotal.carbs,
                        target: viewModel.targets.carbs * 7,
                        color: .carbsColor
                    )
                    MacroDetailCard(
                        title: "Fat",
                        value: viewModel.weeklyTotal.fat,
                        target: viewModel.targets.fat * 7,
                        color: .fatColor
                    )
                }
                
                // Daily average breakdown
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Averages")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    let uniqueDays = max(Set(viewModel.weeklyMeals.map { Calendar.current.startOfDay(for: $0.createdAt) }).count, 1)
                    
                    HStack(spacing: 16) {
                        AverageLabel(value: viewModel.weeklyTotal.protein / uniqueDays, label: "Protein", unit: "g")
                        AverageLabel(value: viewModel.weeklyTotal.carbs / uniqueDays, label: "Carbs", unit: "g")
                        AverageLabel(value: viewModel.weeklyTotal.fat / uniqueDays, label: "Fat", unit: "g")
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // MARK: - Details Section
    @ViewBuilder
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📋 Details")
                .font(.headline)
                .foregroundColor(.white)
            
            switch cardType {
            case .weeklySummary:
                summaryDetails
            case .weeklyChart:
                chartDetails
            case .weeklyNutrition:
                nutritionDetails
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private var summaryDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.weeklyMeals.isEmpty {
                Text("• Track your meals consistently to build insights")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text("• Set realistic daily calorie targets")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text("• Aim for balanced nutrient distribution")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            } else {
                let uniqueDays = Set(viewModel.weeklyMeals.map { Calendar.current.startOfDay(for: $0.createdAt) }).count
                Text("• \(uniqueDays) day(s) with tracked meals")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text("• \(viewModel.weeklyMeals.count) total meals logged")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text("• Average \(viewModel.weeklyMeals.count / max(uniqueDays, 1)) meals per day")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var chartDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.weeklyMeals.isEmpty {
                Text("• Each bar represents daily calorie intake")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text("• Green bars indicate target achieved")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text("• Tap any day to see meal details")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            } else {
                let daysOnTarget = viewModel.weeklyCalorieData.filter { $0.calories >= viewModel.targets.calories }.count
                Text("• \(daysOnTarget) day(s) met your calorie target")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text("• Your target: \(viewModel.targets.calories) kcal/day")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                let maxDay = viewModel.weeklyCalorieData.max(by: { $0.calories < $1.calories })
                if let max = maxDay {
                    Text("• Highest day: \(max.calories) kcal")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    private var nutritionDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.weeklyMeals.isEmpty {
                Text("• Protein: Essential for muscle repair")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text("• Carbs: Primary energy source")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text("• Fat: Supports hormone production")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            } else {
                let total = viewModel.weeklyTotal
                let macroTotal = total.protein + total.carbs + total.fat
                if macroTotal > 0 {
                    let proteinPct = Int(Double(total.protein) / Double(macroTotal) * 100)
                    let carbsPct = Int(Double(total.carbs) / Double(macroTotal) * 100)
                    let fatPct = Int(Double(total.fat) / Double(macroTotal) * 100)
                    Text("• Protein: \(proteinPct)% of macros")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    Text("• Carbs: \(carbsPct)% of macros")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    Text("• Fat: \(fatPct)% of macros")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    // MARK: - Education Section
    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 Tips")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(educationalContent)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private var educationalContent: String {
        switch cardType {
        case .weeklySummary:
            return "Consistency is key! Tracking your meals daily helps build awareness of your eating patterns. Research shows that people who consistently log their food are more successful at achieving their health goals."
        case .weeklyChart:
            return "Your daily calorie needs depend on factors like age, weight, activity level, and goals. Aim for a sustainable approach - dramatic restrictions often lead to rebounds. Small, consistent adjustments are more effective long-term."
        case .weeklyNutrition:
            return "A balanced macro distribution supports overall health. Generally, aim for 10-35% protein, 45-65% carbs, and 20-35% fat. However, individual needs vary based on your specific goals and activity level."
        }
    }
    
    // MARK: - Helper Views
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Text("📊")
                .font(.system(size: 48))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private var weeklyProgressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Week Progress")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            let weeklyTarget = viewModel.targets.calories * 7
            let progress = min(Double(viewModel.weeklyTotal.calories) / Double(weeklyTarget), 1.0)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(
                            LinearGradient(colors: [.caloriesStart, .caloriesEnd], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 12)
            
            Text("\(viewModel.weeklyTotal.calories) / \(weeklyTarget) kcal (\(Int(progress * 100))%)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private func chartBarHeight(for calories: Int) -> CGFloat {
        let maxCalories = max(viewModel.weeklyCalorieData.map { $0.calories }.max() ?? 0, viewModel.targets.calories)
        guard maxCalories > 0 else { return 4 }
        return max(CGFloat(calories) / CGFloat(maxCalories) * 140, 4)
    }
}

// MARK: - Supporting Views
private struct SummaryStatCard: View {
    let value: String
    let label: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(unit.isEmpty ? label : "\(unit)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            if !unit.isEmpty {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MacroDetailCard: View {
    let title: String
    let value: Int
    let target: Int
    let color: Color
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(value) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 50, height: 50)
            
            Text("\(value)g")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct AverageLabel: View {
    let value: Int
    let label: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)\(unit)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    StatsDetailSheet(
        cardType: .weeklySummary,
        viewModel: DashboardViewModel()
    )
}
