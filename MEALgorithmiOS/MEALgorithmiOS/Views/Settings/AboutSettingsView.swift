import SwiftUI

// MARK: - About Settings View (Premium Upgrade)
/// Sub-page for app information, support, and legal links
struct AboutSettingsView: View {
    @Environment(\.openURL) private var openURL
    
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
                        // TODO: Open help center
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        SettingsRow(icon: "❓", title: "Help & FAQ")
                    }
                    
                    Button {
                        if let url = URL(string: "mailto:support@mealgorithm.app") {
                            openURL(url)
                        }
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        SettingsRow(icon: "📧", title: "Contact Support")
                    }
                    
                    Button {
                        requestAppStoreReview()
                        HapticManager.shared.notification(type: .success)
                    } label: {
                        SettingsRow(icon: "⭐", title: "Rate the App")
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
                        if let url = URL(string: "https://mealgorithm.app/privacy") {
                            openURL(url)
                        }
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        SettingsRow(icon: "🔒", title: "Privacy Policy")
                    }
                    
                    Button {
                        if let url = URL(string: "https://mealgorithm.app/terms") {
                            openURL(url)
                        }
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        SettingsRow(icon: "📋", title: "Terms of Service")
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

#Preview {
    NavigationStack {
        AboutSettingsView()
    }
}
