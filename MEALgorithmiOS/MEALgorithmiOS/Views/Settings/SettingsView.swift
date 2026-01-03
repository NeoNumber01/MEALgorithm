import SwiftUI

// MARK: - Settings View
/// Main settings page with hierarchical navigation to sub-pages
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingSignOutConfirm = false
    
    var body: some View {
        NavigationStack {
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
                
                // Body & Goals Section
                Section("Body & Goals") {
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
                }
                
                // General Section
                Section("General") {
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
                }
                
                // Support Section
                Section("Support") {
                    NavigationLink {
                        AboutSettingsView()
                    } label: {
                        SettingsRow(icon: "ℹ️", title: "About")
                    }
                }
                
                // Sign Out Section (at the bottom)
                Section {
                    Button(role: .destructive) {
                        showingSignOutConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
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
        Form {
            Section {
                Text("Profile editing will be expanded in future updates.")
                    .foregroundColor(.secondary)
            }
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
        Form {
            Section("Reminders") {
                Toggle("Meal Logging Reminders", isOn: $mealReminders)
                Toggle("Daily Summary", isOn: $dailySummary)
                Toggle("Weekly Report", isOn: $weeklyReport)
            }
            
            Section {
                Text("Notification settings are saved automatically.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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
        Form {
            Section("Measurements") {
                Picker("Unit System", selection: $useMetric) {
                    Text("Metric (kg, cm)").tag(true)
                    Text("Imperial (lb, ft)").tag(false)
                }
            }
            
            Section("Date & Time") {
                Picker("Date Format", selection: $dateFormat) {
                    Text("DD/MM/YYYY").tag("DD/MM/YYYY")
                    Text("MM/DD/YYYY").tag("MM/DD/YYYY")
                    Text("YYYY-MM-DD").tag("YYYY-MM-DD")
                }
            }
            
            Section {
                Text("Unit settings are saved automatically.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Units & Formatting")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
