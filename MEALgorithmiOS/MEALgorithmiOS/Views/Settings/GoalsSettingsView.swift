import SwiftUI

// MARK: - Goals Settings View (Premium Upgrade)
/// Sub-page for editing fitness goals and nutrition targets
struct GoalsSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Nebula Background
            nebulaBackground
            
            Form {
                // Goal Description Section
                Section {
                    TextField("e.g., Lose weight, Build muscle", text: $viewModel.goalDescription)
                        .foregroundColor(.white)
                } header: {
                    Text("Fitness Goal")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                } footer: {
                    Text("Describe your health or fitness goal. This helps personalize AI recommendations.")
                        .foregroundColor(.white.opacity(0.5))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Target Mode Section
                Section {
                    Toggle("Use Custom Targets", isOn: $viewModel.useCustomTargets)
                        .tint(.appPrimary)
                        .foregroundColor(.white)
                } footer: {
                    Text(viewModel.useCustomTargets
                         ? "You can manually set your nutrition targets below."
                         : "Targets are automatically calculated based on your physical stats and activity level.")
                    .foregroundColor(.white.opacity(0.5))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Nutrition Targets Section
                Section {
                    // Calories
                    HStack {
                        Circle()
                            .fill(Color.caloriesColor)
                            .frame(width: 12, height: 12)
                            .shadow(color: .caloriesColor.opacity(0.5), radius: 4)
                        Text("Calories")
                            .foregroundColor(.white)
                        Spacer()
                        if viewModel.useCustomTargets {
                            TextField("2000", value: $viewModel.calorieTarget, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .foregroundColor(.white)
                        } else {
                            Text("\(viewModel.calorieTarget)")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Text("kcal")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .opacity(viewModel.useCustomTargets ? 1 : 0.7)
                    
                    // Protein
                    HStack {
                        Circle()
                            .fill(Color.proteinColor)
                            .frame(width: 12, height: 12)
                            .shadow(color: .proteinColor.opacity(0.5), radius: 4)
                        Text("Protein")
                            .foregroundColor(.white)
                        Spacer()
                        if viewModel.useCustomTargets {
                            TextField("150", value: $viewModel.proteinTarget, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .foregroundColor(.white)
                        } else {
                            Text("\(viewModel.proteinTarget)")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Text("g")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .opacity(viewModel.useCustomTargets ? 1 : 0.7)
                    
                    // Carbs
                    HStack {
                        Circle()
                            .fill(Color.carbsColor)
                            .frame(width: 12, height: 12)
                            .shadow(color: .carbsColor.opacity(0.5), radius: 4)
                        Text("Carbs")
                            .foregroundColor(.white)
                        Spacer()
                        if viewModel.useCustomTargets {
                            TextField("200", value: $viewModel.carbsTarget, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .foregroundColor(.white)
                        } else {
                            Text("\(viewModel.carbsTarget)")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Text("g")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .opacity(viewModel.useCustomTargets ? 1 : 0.7)
                    
                    // Fat
                    HStack {
                        Circle()
                            .fill(Color.fatColor)
                            .frame(width: 12, height: 12)
                            .shadow(color: .fatColor.opacity(0.5), radius: 4)
                        Text("Fat")
                            .foregroundColor(.white)
                        Spacer()
                        if viewModel.useCustomTargets {
                            TextField("65", value: $viewModel.fatTarget, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .foregroundColor(.white)
                        } else {
                            Text("\(viewModel.fatTarget)")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Text("g")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .opacity(viewModel.useCustomTargets ? 1 : 0.7)
                } header: {
                    Text("Daily Nutrition Targets")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Macro Ratio Info
                if !viewModel.useCustomTargets && viewModel.hasPhysicalStats {
                    Section {
                        VStack(alignment: .leading, spacing: Spacing.small) {
                            Text("Recommended Macro Split")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: Spacing.medium) {
                                PremiumMacroChip(label: "Protein", value: "30%", color: .proteinColor)
                                PremiumMacroChip(label: "Carbs", value: "40%", color: .carbsColor)
                                PremiumMacroChip(label: "Fat", value: "30%", color: .fatColor)
                            }
                        }
                    } footer: {
                        Text("Default macro distribution for balanced nutrition. Toggle custom targets to adjust.")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Goals & Targets")
        .navigationBarTitleDisplayMode(.inline)
        .addDoneButton()
        .onDisappear {
            Task {
                await viewModel.saveProfileIfNeeded()
            }
        }
        .onChange(of: viewModel.useCustomTargets) { _, newValue in
            if !newValue {
                viewModel.recalculateTargets()
            }
        }
    }
    
    // MARK: - Nebula Background
    private var nebulaBackground: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appPrimary.opacity(0.25), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.5
                        )
                    )
                    .frame(width: geo.size.width * 0.8)
                    .blur(radius: 60)
                    .offset(x: -geo.size.width * 0.2, y: -100)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.proteinColor.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.4
                        )
                    )
                    .frame(width: geo.size.width * 0.6)
                    .blur(radius: 50)
                    .offset(x: geo.size.width * 0.5, y: geo.size.height * 0.4)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Premium Macro Chip
/// Small chip displaying macro percentage with glow effect
struct PremiumMacroChip: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Legacy Macro Chip (kept for compatibility)
struct MacroChip: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        PremiumMacroChip(label: label, value: value, color: color)
    }
}

#Preview {
    NavigationStack {
        GoalsSettingsView(viewModel: SettingsViewModel())
    }
}
