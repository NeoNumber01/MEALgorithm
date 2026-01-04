import SwiftUI

// MARK: - Settings Row (Premium Upgrade)
/// Reusable row component for settings list items
struct SettingsRow: View {
    let icon: String?
    let systemIcon: String?
    let title: String
    var subtitle: String? = nil
    var showChevron: Bool = true
    
    init(icon: String? = nil, systemIcon: String? = nil, title: String, subtitle: String? = nil, showChevron: Bool = true) {
        self.icon = icon
        self.systemIcon = systemIcon
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let systemIcon = systemIcon {
                Image(systemName: systemIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appPrimary, .appSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32)
            } else if let icon = icon {
                Text(icon)
                    .font(.title2)
                    .frame(width: 32)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Profile Header Row (Premium Upgrade)
/// User avatar and email display for settings
struct ProfileHeaderRow: View {
    let email: String?
    var isLoading: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar with Glow
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.appPrimary.opacity(0.7), .appSecondary.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .neonGlow(color: .appPrimary, radius: 12)
                
                Text(avatarInitial)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("My Profile")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(email ?? "Not signed in")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .skeleton(isLoading: isLoading)
    }
    
    private var avatarInitial: String {
        guard let email = email, let first = email.first else { return "?" }
        return String(first).uppercased()
    }
}

// MARK: - Macro Target Row
/// Row for displaying and editing macro targets with color indicator
struct MacroTargetRow: View {
    let title: String
    @Binding var value: Int
    let unit: String
    let color: Color
    let disabled: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .shadow(color: color.opacity(0.5), radius: 4)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            if disabled {
                Text("\(value) \(unit)")
                    .foregroundColor(.white.opacity(0.5))
            } else {
                TextField("", value: $value, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .foregroundColor(.white)
                
                Text(unit)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .opacity(disabled ? 0.6 : 1)
    }
}

#Preview("Settings Row") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        List {
            SettingsRow(icon: "📏", title: "Physical Stats", subtitle: "Height: 175cm, Weight: 70kg")
            SettingsRow(icon: "🎯", title: "Goals & Targets")
            SettingsRow(icon: "🔔", title: "Notifications")
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }
}

#Preview("Profile Header") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        List {
            ProfileHeaderRow(email: "user@example.com")
                .listRowBackground(Color.white.opacity(0.05))
        }
        .scrollContentBackground(.hidden)
    }
}
