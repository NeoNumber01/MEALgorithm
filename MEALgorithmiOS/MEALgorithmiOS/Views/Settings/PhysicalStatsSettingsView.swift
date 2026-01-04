import SwiftUI

// MARK: - Physical Stats Settings View (Premium Upgrade)
/// Sub-page for editing body measurements and activity level
struct PhysicalStatsSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        ZStack {
            // Nebula Background
            nebulaBackground
            
            Form {
                // Body Measurements Section
                Section {
                    // Height
                    HStack {
                        Text("Height")
                            .foregroundColor(.white)
                        Spacer()
                        TextField("170", value: $viewModel.heightCm, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .foregroundColor(.white)
                        Text("cm")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    // Weight
                    HStack {
                        Text("Weight")
                            .foregroundColor(.white)
                        Spacer()
                        TextField("70.0", value: $viewModel.weightKg, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .foregroundColor(.white)
                        Text("kg")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    // Age
                    HStack {
                        Text("Age")
                            .foregroundColor(.white)
                        Spacer()
                        TextField("25", value: $viewModel.age, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .foregroundColor(.white)
                        Text("years")
                            .foregroundColor(.white.opacity(0.5))
                    }
                } header: {
                    Text("Body Measurements")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                } footer: {
                    Text("Used to calculate your daily calorie needs (TDEE) using the Mifflin-St Jeor equation.")
                        .foregroundColor(.white.opacity(0.5))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Demographics Section
                Section {
                    Picker("Gender", selection: $viewModel.gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender)
                        }
                    }
                    .foregroundColor(.white)
                    
                    Picker("Activity Level", selection: $viewModel.activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .foregroundColor(.white)
                } header: {
                    Text("Demographics")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // TDEE Preview Section
                if viewModel.hasPhysicalStats {
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Estimated TDEE")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(viewModel.calorieTarget) kcal/day")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.caloriesColor)
                            }
                            
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color.caloriesColor.opacity(0.3), Color.clear],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 30
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: "flame.fill")
                                    .font(.title)
                                    .foregroundColor(.caloriesColor)
                            }
                            .neonGlow(color: .caloriesColor, radius: 10)
                        }
                    } footer: {
                        Text("Total Daily Energy Expenditure - the estimated calories you burn per day based on your stats and activity level.")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
            }
            .scrollContentBackground(.hidden)
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
    
    // MARK: - Nebula Background
    private var nebulaBackground: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.caloriesColor.opacity(0.25), Color.clear],
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
                            colors: [Color.appPrimary.opacity(0.2), Color.clear],
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

#Preview {
    NavigationStack {
        PhysicalStatsSettingsView(viewModel: SettingsViewModel())
    }
}
