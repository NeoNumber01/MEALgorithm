import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView(message: "Loading profile...")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            headerSection
                            
                            // Messages
                            if let error = viewModel.error {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            if viewModel.saveSuccess {
                                Text("✓ Profile saved successfully!")
                                    .foregroundColor(.green)
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            // Physical Stats
                            physicalStatsSection
                            
                            // Goals
                            goalsSection
                            
                            // Nutritional Targets
                            nutritionalTargetsSection
                            
                            // Save Button
                            Button {
                                Task {
                                    await viewModel.saveProfile()
                                }
                            } label: {
                                if viewModel.isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Save Profile")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(viewModel.isSaving)
                            
                            // Account Section
                            accountSection
                        }
                        .padding()
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadProfile()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("⚙️")
            Text("Profile Configuration")
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.1))
        .foregroundColor(.purple)
        .cornerRadius(20)
    }
    
    // MARK: - Physical Stats Section
    private var physicalStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("📏")
                Text("Physical Stats")
                    .font(.headline)
            }
            
            Text("We use the Mifflin-St Jeor equation to calculate your daily calorie needs.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                NumberField(title: "Height (cm)", value: $viewModel.heightCm, placeholder: "170")
                    .onChange(of: viewModel.heightCm) { _, _ in viewModel.recalculateTargets() }
                
                NumberFieldDouble(title: "Weight (kg)", value: $viewModel.weightKg, placeholder: "70")
                    .onChange(of: viewModel.weightKg) { _, _ in viewModel.recalculateTargets() }
                
                NumberField(title: "Age", value: $viewModel.age, placeholder: "25")
                    .onChange(of: viewModel.age) { _, _ in viewModel.recalculateTargets() }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gender")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Gender", selection: $viewModel.gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onChange(of: viewModel.gender) { _, _ in viewModel.recalculateTargets() }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity Level")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Activity Level", selection: $viewModel.activityLevel) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.menu)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .onChange(of: viewModel.activityLevel) { _, _ in viewModel.recalculateTargets() }
            }
        }
        .padding()
        .liquidGlass()
        .hoverEffect()
    }
    
    // MARK: - Goals Section
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🎯")
                Text("Goals")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Goal Description")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g., Lose weight, Build muscle", text: $viewModel.goalDescription)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            Toggle("Use custom targets instead of calculated values", isOn: $viewModel.useCustomTargets)
                .font(.subheadline)
                .onChange(of: viewModel.useCustomTargets) { _, _ in
                    if !viewModel.useCustomTargets {
                        viewModel.recalculateTargets()
                    }
                }
        }
        .padding()
        .liquidGlass()
        .hoverEffect()
    }
    
    // MARK: - Nutritional Targets Section
    private var nutritionalTargetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🔥")
                Text("Daily Targets")
                    .font(.headline)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                TargetField(
                    title: "Calories",
                    value: $viewModel.calorieTarget,
                    unit: "kcal",
                    disabled: !viewModel.useCustomTargets
                )
                
                TargetField(
                    title: "Protein",
                    value: $viewModel.proteinTarget,
                    unit: "grams",
                    disabled: !viewModel.useCustomTargets
                )
                
                TargetField(
                    title: "Carbs",
                    value: $viewModel.carbsTarget,
                    unit: "grams",
                    disabled: !viewModel.useCustomTargets
                )
                
                TargetField(
                    title: "Fat",
                    value: $viewModel.fatTarget,
                    unit: "grams",
                    disabled: !viewModel.useCustomTargets
                )
            }
            
            if !viewModel.useCustomTargets && viewModel.hasPhysicalStats {
                Text("💡 Based on your stats, your estimated TDEE is \(viewModel.calorieTarget) kcal/day")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .foregroundColor(.white)
        .gradientCard(colors: [.caloriesColor, .proteinColor])
        .hoverEffect()
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("👤")
                Text("Account")
                    .font(.headline)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Signed in as")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(authViewModel.currentUserEmail ?? "Unknown")
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Button(role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                } label: {
                    Text("Sign Out")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .liquidGlass()
        .hoverEffect()
    }
}

// MARK: - Number Field
struct NumberField: View {
    let title: String
    @Binding var value: Int?
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(placeholder, value: $value, format: .number)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

// MARK: - Number Field Double
struct NumberFieldDouble: View {
    let title: String
    @Binding var value: Double?
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(placeholder, value: $value, format: .number)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

// MARK: - Target Field
struct TargetField: View {
    let title: String
    @Binding var value: Int
    let unit: String
    let disabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .opacity(0.8)
            TextField("", value: $value, format: .number)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.white.opacity(0.3))
                .cornerRadius(8)
                .disabled(disabled)
                .opacity(disabled ? 0.7 : 1)
            Text(unit)
                .font(.caption2)
                .opacity(0.7)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
