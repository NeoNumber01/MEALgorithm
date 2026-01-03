import SwiftUI

// MARK: - About Settings View
/// Sub-page for app information, support, and legal links
struct AboutSettingsView: View {
    @Environment(\.openURL) private var openURL
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        Form {
            // App Info Section
            Section {
                HStack {
                    // App Icon
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.appPrimary, .appSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text("🍽️")
                                .font(.largeTitle)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MEALgorithm")
                            .font(.headline)
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            // Support Section
            Section("Support") {
                Button {
                    // TODO: Open help center
                } label: {
                    SettingsRow(icon: "❓", title: "Help & FAQ")
                }
                .foregroundColor(.primary)
                
                Button {
                    if let url = URL(string: "mailto:support@mealgorithm.app") {
                        openURL(url)
                    }
                } label: {
                    SettingsRow(icon: "📧", title: "Contact Support")
                }
                .foregroundColor(.primary)
                
                Button {
                    requestAppStoreReview()
                } label: {
                    SettingsRow(icon: "⭐", title: "Rate the App")
                }
                .foregroundColor(.primary)
            }
            
            // Legal Section
            Section("Legal") {
                Button {
                    if let url = URL(string: "https://mealgorithm.app/privacy") {
                        openURL(url)
                    }
                } label: {
                    SettingsRow(icon: "🔒", title: "Privacy Policy")
                }
                .foregroundColor(.primary)
                
                Button {
                    if let url = URL(string: "https://mealgorithm.app/terms") {
                        openURL(url)
                    }
                } label: {
                    SettingsRow(icon: "📋", title: "Terms of Service")
                }
                .foregroundColor(.primary)
            }
            
            // Credits Section
            Section {
                VStack(spacing: 8) {
                    Text("Made with ❤️ for healthier eating")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("© 2026 MEALgorithm")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
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
