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
                                systemIcon: "ruler.fill",
                                title: "Physical Stats",
                                subtitle: physicalStatsSummary
                            )
                        }
                        
                        NavigationLink {
                            GoalsSettingsView(viewModel: viewModel)
                        } label: {
                            SettingsRow(
                                systemIcon: "target",
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
                            SettingsRow(systemIcon: "bell.fill", title: "Notifications")
                        }
                        
                        NavigationLink {
                            UnitsSettingsView()
                        } label: {
                            SettingsRow(systemIcon: "globe", title: "Units & Formatting")
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
                            SettingsRow(systemIcon: "info.circle.fill", title: "About")
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
                .contentMargins(.bottom, 100, for: .scrollContent)
            }
            .navigationTitle("Settings")
            .toolbarBackground(.hidden, for: .navigationBar)
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
/// Sub-page for editing profile details with full form
struct ProfileEditView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @FocusState private var focusedField: ProfileField?
    
    enum ProfileField {
        case fullName, foodPreferences, foodDislikes, dietaryRestrictions, customNotes
    }
    
    var body: some View {
        ZStack {
            // MARK: - Nebula Background
            nebulaBackground
            
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Profile Header Card
                    profileHeaderCard
                    
                    // MARK: - Personal Info Section
                    profileFormSection(title: "Personal Info") {
                        FormTextField(
                            title: "Full Name",
                            placeholder: "Your display name",
                            text: $viewModel.fullName,
                            icon: "person.fill"
                        )
                        .focused($focusedField, equals: .fullName)
                    }
                    
                    // MARK: - AI Preferences Section
                    profileFormSection(title: "AI Personalization", subtitle: "These help our AI make better meal recommendations") {
                        FormTextEditor(
                            title: "Food Preferences",
                            placeholder: "e.g., High protein, Mediterranean cuisine, Asian food...",
                            text: $viewModel.foodPreferences,
                            icon: "heart.fill"
                        )
                        .focused($focusedField, equals: .foodPreferences)
                        
                        FormTextEditor(
                            title: "Food Dislikes",
                            placeholder: "e.g., Mushrooms, seafood, spicy food...",
                            text: $viewModel.foodDislikes,
                            icon: "hand.thumbsdown.fill"
                        )
                        .focused($focusedField, equals: .foodDislikes)
                        
                        FormTextEditor(
                            title: "Dietary Restrictions",
                            placeholder: "e.g., Vegetarian, gluten-free, lactose intolerant...",
                            text: $viewModel.dietaryRestrictions,
                            icon: "exclamationmark.triangle.fill"
                        )
                        .focused($focusedField, equals: .dietaryRestrictions)
                        
                        FormTextEditor(
                            title: "Additional Notes",
                            placeholder: "Any other information for AI recommendations...",
                            text: $viewModel.customNotes,
                            icon: "note.text"
                        )
                        .focused($focusedField, equals: .customNotes)
                    }
                    
                    // Save status
                    if viewModel.saveSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Changes saved")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .transition(.opacity)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .onDisappear {
            Task {
                await viewModel.saveProfileIfNeeded()
            }
        }
    }
    
    // MARK: - Profile Header Card
    private var profileHeaderCard: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.appPrimary.opacity(0.7), .appSecondary.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .neonGlow(color: .appPrimary, radius: 15)
                
                Text(avatarInitial)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Email (read-only)
            VStack(spacing: 4) {
                Text(authViewModel.currentUserEmail ?? "Not signed in")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Email cannot be changed")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Form Section Builder
    private func profileFormSection<Content: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
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
                            colors: [Color.appSecondary.opacity(0.2), Color.clear],
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
    
    private var avatarInitial: String {
        if !viewModel.fullName.isEmpty, let first = viewModel.fullName.first {
            return String(first).uppercased()
        }
        guard let email = authViewModel.currentUserEmail, let first = email.first else { return "?" }
        return String(first).uppercased()
    }
}

// MARK: - Form Text Field Component
private struct FormTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appPrimary, .appSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
                .foregroundColor(.white)
        }
    }
}

// MARK: - Form Text Editor Component
private struct FormTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appPrimary, .appSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .frame(minHeight: 60, maxHeight: 100)
                    .padding(8)
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
        }
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
