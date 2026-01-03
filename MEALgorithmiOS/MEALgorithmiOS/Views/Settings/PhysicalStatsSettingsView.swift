import SwiftUI

// MARK: - Physical Stats Settings View
/// Sub-page for editing body measurements and activity level
struct PhysicalStatsSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        Form {
            // Body Measurements Section
            Section {
                // Height
                HStack {
                    Text("Height")
                    Spacer()
                    TextField("170", value: $viewModel.heightCm, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("cm")
                        .foregroundColor(.secondary)
                }
                
                // Weight
                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("70.0", value: $viewModel.weightKg, format: .number.precision(.fractionLength(1)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("kg")
                        .foregroundColor(.secondary)
                }
                
                // Age
                HStack {
                    Text("Age")
                    Spacer()
                    TextField("25", value: $viewModel.age, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("years")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Body Measurements")
            } footer: {
                Text("Used to calculate your daily calorie needs (TDEE) using the Mifflin-St Jeor equation.")
            }
            
            // Demographics Section
            Section("Demographics") {
                Picker("Gender", selection: $viewModel.gender) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
                
                Picker("Activity Level", selection: $viewModel.activityLevel) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
            }
            
            // TDEE Preview Section
            if viewModel.hasPhysicalStats {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Estimated TDEE")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(viewModel.calorieTarget) kcal/day")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appPrimary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "flame.fill")
                            .font(.title)
                            .foregroundColor(.caloriesColor)
                    }
                } footer: {
                    Text("Total Daily Energy Expenditure - the estimated calories you burn per day based on your stats and activity level.")
                }
            }
        }
        .navigationTitle("Physical Stats")
        .navigationBarTitleDisplayMode(.inline)
        .addDoneButton()
        .onDisappear {
            // Auto-save when leaving the page
            Task {
                await viewModel.saveProfileIfNeeded()
            }
        }
        .onChange(of: viewModel.heightCm) { _, _ in viewModel.recalculateTargets() }
        .onChange(of: viewModel.weightKg) { _, _ in viewModel.recalculateTargets() }
        .onChange(of: viewModel.age) { _, _ in viewModel.recalculateTargets() }
        .onChange(of: viewModel.gender) { _, _ in viewModel.recalculateTargets() }
        .onChange(of: viewModel.activityLevel) { _, _ in viewModel.recalculateTargets() }
    }
}

#Preview {
    NavigationStack {
        PhysicalStatsSettingsView(viewModel: SettingsViewModel())
    }
}
