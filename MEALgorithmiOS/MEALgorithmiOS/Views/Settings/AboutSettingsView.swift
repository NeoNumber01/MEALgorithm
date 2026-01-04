import SwiftUI

// MARK: - About Settings View (Premium Upgrade)
/// Sub-page for app information, support, and legal links
struct AboutSettingsView: View {
    @Environment(\.openURL) private var openURL
    
    // Sheet states
    @State private var showingHelpFAQ = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        ZStack {
            // Nebula Background
            nebulaBackground
            
            Form {
                // App Info Section
                Section {
                    HStack {
                        // App Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.appPrimary, .appSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .neonGlow(color: .appPrimary, radius: 12)
                            
                            Text("🍽️")
                                .font(.system(size: 32))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MEALgorithm")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Text("Version \(appVersion) (\(buildNumber))")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.leading, 8)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Support Section
                Section {
                    Button {
                        showingHelpFAQ = true
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        SettingsRow(systemIcon: "questionmark.circle.fill", title: "Help & FAQ")
                    }
                    
                    Button {
                        if let url = URL(string: "mailto:support@mealgorithm.app") {
                            openURL(url)
                        }
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        SettingsRow(systemIcon: "envelope.fill", title: "Contact Support")
                    }
                    
                    Button {
                        requestAppStoreReview()
                        HapticManager.shared.notification(type: .success)
                    } label: {
                        SettingsRow(systemIcon: "star.fill", title: "Rate the App")
                    }
                } header: {
                    Text("Support")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Legal Section
                Section {
                    Button {
                        showingPrivacyPolicy = true
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        SettingsRow(systemIcon: "lock.shield.fill", title: "Privacy Policy")
                    }
                    
                    Button {
                        showingTermsOfService = true
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        SettingsRow(systemIcon: "doc.text.fill", title: "Terms of Service")
                    }
                } header: {
                    Text("Legal")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Credits Section
                Section {
                    VStack(spacing: 8) {
                        Text("Made with ❤️ for healthier eating")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("© 2026 MEALgorithm")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        // MARK: - Sheets
        .sheet(isPresented: $showingHelpFAQ) {
            HelpFAQSheet()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicySheet()
        }
        .sheet(isPresented: $showingTermsOfService) {
            TermsOfServiceSheet()
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
    
    private func requestAppStoreReview() {
        // Request App Store review
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            #if !DEBUG
            SKStoreReviewController.requestReview(in: scene)
            #endif
        }
    }
}

// MARK: - Help & FAQ Sheet
struct HelpFAQSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        FAQItem(
                            question: "How does AI meal analysis work?",
                            answer: "Our AI analyzes your meal photos and descriptions to estimate nutritional content. It uses advanced image recognition and natural language processing to identify foods and calculate calories, protein, carbs, and fat."
                        )
                        
                        FAQItem(
                            question: "How accurate are the calorie estimates?",
                            answer: "AI estimates are approximate and should be used as a guide. For best results, provide clear photos and detailed descriptions. Accuracy improves when you include portion sizes."
                        )
                        
                        FAQItem(
                            question: "How are my nutrition goals calculated?",
                            answer: "Your goals are calculated using the Mifflin-St Jeor equation based on your height, weight, age, gender, and activity level. You can also set custom targets in Settings → Goals & Targets."
                        )
                        
                        FAQItem(
                            question: "Can I edit or delete logged meals?",
                            answer: "Yes! Tap on any meal in your history to view details. From there, you can delete the meal. Editing features are coming soon."
                        )
                        
                        FAQItem(
                            question: "How do meal recommendations work?",
                            answer: "Our AI considers your remaining daily calories and macros, your food preferences, dietary restrictions, and previous meals to suggest personalized meal ideas."
                        )
                        
                        FAQItem(
                            question: "Is my data private?",
                            answer: "Absolutely. Your data is securely stored and never shared with third parties. We only use your information to provide personalized nutrition insights."
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Help & FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.title2)
                    }
                }
            }
        }
    }
}

// MARK: - FAQ Item Component
private struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(question)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.appPrimary)
                        .font(.caption)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Privacy Policy Sheet
struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Last Updated: January 2026")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        
                        PolicySection(
                            title: "Information We Collect",
                            content: """
                            • Account information (email address)
                            • Profile data (height, weight, age, dietary preferences)
                            • Meal logs and photos you submit
                            • App usage analytics (anonymized)
                            """
                        )
                        
                        PolicySection(
                            title: "How We Use Your Data",
                            content: """
                            • Provide personalized nutrition tracking
                            • Generate AI-powered meal recommendations
                            • Improve our services and algorithms
                            • Send important account notifications
                            """
                        )
                        
                        PolicySection(
                            title: "Data Storage & Security",
                            content: """
                            Your data is encrypted and stored securely using industry-standard practices. We use Supabase for database services with row-level security policies to ensure only you can access your data.
                            """
                        )
                        
                        PolicySection(
                            title: "Third-Party Services",
                            content: """
                            • Google Gemini AI for meal analysis
                            • Supabase for authentication and storage
                            • Apple for Sign in with Apple
                            
                            These services have their own privacy policies.
                            """
                        )
                        
                        PolicySection(
                            title: "Your Rights",
                            content: """
                            You can request to:
                            • Access your personal data
                            • Delete your account and all data
                            • Export your data
                            
                            Contact support@mealgorithm.app for requests.
                            """
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.title2)
                    }
                }
            }
        }
    }
}

// MARK: - Terms of Service Sheet
struct TermsOfServiceSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Last Updated: January 2026")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        
                        PolicySection(
                            title: "Acceptance of Terms",
                            content: """
                            By using MEALgorithm, you agree to these terms. If you do not agree, please do not use the app.
                            """
                        )
                        
                        PolicySection(
                            title: "Service Description",
                            content: """
                            MEALgorithm provides AI-powered nutritional tracking and meal recommendations. Our estimates are for informational purposes only and should not replace professional medical or dietary advice.
                            """
                        )
                        
                        PolicySection(
                            title: "User Responsibilities",
                            content: """
                            • Provide accurate profile information
                            • Use the app for personal, non-commercial purposes
                            • Do not attempt to manipulate or abuse the service
                            • Report any bugs or security issues
                            """
                        )
                        
                        PolicySection(
                            title: "Disclaimer",
                            content: """
                            MEALgorithm is not a medical device. Nutritional estimates are approximate. Always consult healthcare professionals for dietary decisions, especially if you have health conditions.
                            """
                        )
                        
                        PolicySection(
                            title: "Limitation of Liability",
                            content: """
                            MEALgorithm is provided "as is" without warranties. We are not liable for any damages arising from the use of this app or reliance on its nutritional data.
                            """
                        )
                        
                        PolicySection(
                            title: "Changes to Terms",
                            content: """
                            We may update these terms. Continued use after changes constitutes acceptance. Check this page periodically for updates.
                            """
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.title2)
                    }
                }
            }
        }
    }
}

// MARK: - Policy Section Component
private struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        AboutSettingsView()
    }
}

