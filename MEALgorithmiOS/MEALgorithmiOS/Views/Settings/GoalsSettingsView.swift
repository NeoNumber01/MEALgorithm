import SwiftUI

// MARK: - Goals Settings View
/// Sub-page for editing fitness goals and nutrition targets
struct GoalsSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            // Goal Description Section
            Section {
                TextField("e.g., Lose weight, Build muscle", text: $viewModel.goalDescription)
            } header: {
                Text("Fitness Goal")
            } footer: {
                Text("Describe your health or fitness goal. This helps personalize AI recommendations.")
            }
            
            // Target Mode Section
            Section {
                Toggle("Use Custom Targets", isOn: $viewModel.useCustomTargets)
            } footer: {
                Text(viewModel.useCustomTargets
                     ? "You can manually set your nutrition targets below."
                     : "Targets are automatically calculated based on your physical stats and activity level.")
            }
            
            // Nutrition Targets Section
            Section("Daily Nutrition Targets") {
                // Calories
                HStack {
                    Circle()
                        .fill(Color.caloriesColor)
                        .frame(width: 12, height: 12)
                    Text("Calories")
                    Spacer()
                    if viewModel.useCustomTargets {
                        TextField("2000", value: $viewModel.calorieTarget, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    } else {
                        Text("\(viewModel.calorieTarget)")
                            .foregroundColor(.secondary)
                    }
                    Text("kcal")
                        .foregroundColor(.secondary)
                }
                .opacity(viewModel.useCustomTargets ? 1 : 0.7)
                
                // Protein
                HStack {
                    Circle()
                        .fill(Color.proteinColor)
                        .frame(width: 12, height: 12)
                    Text("Protein")
                    Spacer()
                    if viewModel.useCustomTargets {
                        TextField("150", value: $viewModel.proteinTarget, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    } else {
                        Text("\(viewModel.proteinTarget)")
                            .foregroundColor(.secondary)
                    }
                    Text("g")
                        .foregroundColor(.secondary)
                }
                .opacity(viewModel.useCustomTargets ? 1 : 0.7)
                
                // Carbs
                HStack {
                    Circle()
                        .fill(Color.carbsColor)
                        .frame(width: 12, height: 12)
                    Text("Carbs")
                    Spacer()
                    if viewModel.useCustomTargets {
                        TextField("200", value: $viewModel.carbsTarget, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    } else {
                        Text("\(viewModel.carbsTarget)")
                            .foregroundColor(.secondary)
                    }
                    Text("g")
                        .foregroundColor(.secondary)
                }
                .opacity(viewModel.useCustomTargets ? 1 : 0.7)
                
                // Fat
                HStack {
                    Circle()
                        .fill(Color.fatColor)
                        .frame(width: 12, height: 12)
                    Text("Fat")
                    Spacer()
                    if viewModel.useCustomTargets {
                        TextField("65", value: $viewModel.fatTarget, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    } else {
                        Text("\(viewModel.fatTarget)")
                            .foregroundColor(.secondary)
                    }
                    Text("g")
                        .foregroundColor(.secondary)
                }
                .opacity(viewModel.useCustomTargets ? 1 : 0.7)
            }
            
            // Macro Ratio Info
            if !viewModel.useCustomTargets && viewModel.hasPhysicalStats {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended Macro Split")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 16) {
                            MacroChip(label: "Protein", value: "30%", color: .proteinColor)
                            MacroChip(label: "Carbs", value: "40%", color: .carbsColor)
                            MacroChip(label: "Fat", value: "30%", color: .fatColor)
                        }
                    }
                } footer: {
                    Text("Default macro distribution for balanced nutrition. Toggle custom targets to adjust.")
                }
            }
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
}

// MARK: - Macro Chip
/// Small chip displaying macro percentage
struct MacroChip: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        GoalsSettingsView(viewModel: SettingsViewModel())
    }
}
