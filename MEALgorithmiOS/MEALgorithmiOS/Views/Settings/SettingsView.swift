import SwiftUI

// MARK: - Settings View (Premium Upgrade)
/// Main settings page with hierarchical navigation to sub-pages
/// 使用保守策略：保持原生 List/Form，添加 Nebula 背景层增强视觉效果
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingSignOutConfirm = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Nebula Background
                nebulaBackground
                
                List {
                    // Profile Header Section
                    Section {
                        NavigationLink {
                            ProfileEditView(viewModel: viewModel)
                        } label: {
                            ProfileHeaderRow(
                                email: authViewModel.currentUserEmail,
                                isLoading: viewModel.isLoading
                            )
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                    
                    // Body & Goals Section
                    Section {
                        NavigationLink {
                            PhysicalStatsSettingsView(viewModel: viewModel)
                        } label: {
                            SettingsRow(
                                icon: "📏",
                                title: "Physical Stats",
                                subtitle: physicalStatsSummary
                            )
                        }
                        
                        NavigationLink {
                            GoalsSettingsView(viewModel: viewModel)
                        } label: {
                            SettingsRow(
                                icon: "🎯",
                                title: "Goals & Targets",
                                subtitle: goalsSummary
                            )
                        }
                    } header: {
                        Text("Body & Goals")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                    
                    // General Section
                    Section {
                        NavigationLink {
                            NotificationsSettingsView()
                        } label: {
                            SettingsRow(icon: "🔔", title: "Notifications")
                        }
                        
                        NavigationLink {
                            UnitsSettingsView()
                        } label: {
                            SettingsRow(icon: "🌍", title: "Units & Formatting")
                        }
                    } header: {
                        Text("General")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                    
                    // Support Section
                    Section {
                        NavigationLink {
                            AboutSettingsView()
                        } label: {
                            SettingsRow(icon: "ℹ️", title: "About")
                        }
                    } header: {
                        Text("Support")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                    
                    // Sign Out Section (at the bottom)
                    Section {
                        Button(role: .destructive) {
                            showingSignOutConfirm = true
                            HapticManager.shared.impact(style: .medium)
                        } label: {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                    }
                    .listRowBackground(Color.red.opacity(0.1))
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .task {
                await viewModel.loadProfile()
            }
            .confirmationDialog(
                "Are you sure you want to sign out?",
                isPresented: $showingSignOutConfirm,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    // MARK: - Nebula Background
    private var nebulaBackground: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            GeometryReader { geo in
                // Primary Cyan Orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appPrimary.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.5
                        )
                    )
                    .frame(width: geo.size.width * 0.8)
                    .blur(radius: 60)
                    .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.1)
                
                // Secondary Purple Orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.4
                        )
                    )
                    .frame(width: geo.size.width * 0.6)
                    .blur(radius: 50)
                    .offset(x: geo.size.width * 0.5, y: geo.size.height * 0.5)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Computed Summaries
    private var physicalStatsSummary: String? {
        guard !viewModel.isLoading else { return nil }
        
        var parts: [String] = []
        if let height = viewModel.heightCm {
            parts.append("\(height)cm")
        }
        if let weight = viewModel.weightKg {
            parts.append("\(String(format: "%.1f", weight))kg")
        }
        if let age = viewModel.age {
            parts.append("\(age)y")
        }
        
        return parts.isEmpty ? "Not set" : parts.joined(separator: " • ")
    }
    
    private var goalsSummary: String? {
        guard !viewModel.isLoading else { return nil }
        
        if !viewModel.goalDescription.isEmpty {
            return viewModel.goalDescription
        }
        return "\(viewModel.calorieTarget) kcal target"
    }
}

// MARK: - Profile Edit View
/// Sub-page for editing profile details (placeholder for future expansion)
struct ProfileEditView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            Form {
                Section {
                    Text("Profile editing will be expanded in future updates.")
                        .foregroundColor(.white.opacity(0.6))
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Notifications Settings View
/// Sub-page for notification preferences (placeholder)
struct NotificationsSettingsView: View {
    @State private var mealReminders = true
    @State private var dailySummary = false
    @State private var weeklyReport = true
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            Form {
                Section {
                    Toggle("Meal Logging Reminders", isOn: $mealReminders)
                        .tint(.appPrimary)
                    Toggle("Daily Summary", isOn: $dailySummary)
                        .tint(.appPrimary)
                    Toggle("Weekly Report", isOn: $weeklyReport)
                        .tint(.appPrimary)
                } header: {
                    Text("Reminders")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                Section {
                    Text("Notification settings are saved automatically.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Units Settings View
/// Sub-page for unit preferences (placeholder)
struct UnitsSettingsView: View {
    @State private var useMetric = true
    @State private var dateFormat = "DD/MM/YYYY"
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            Form {
                Section {
                    Picker("Unit System", selection: $useMetric) {
                        Text("Metric (kg, cm)").tag(true)
                        Text("Imperial (lb, ft)").tag(false)
                    }
                } header: {
                    Text("Measurements")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                Section {
                    Picker("Date Format", selection: $dateFormat) {
                        Text("DD/MM/YYYY").tag("DD/MM/YYYY")
                        Text("MM/DD/YYYY").tag("MM/DD/YYYY")
                        Text("YYYY-MM-DD").tag("YYYY-MM-DD")
                    }
                } header: {
                    Text("Date & Time")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                Section {
                    Text("Unit settings are saved automatically.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Units & Formatting")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
