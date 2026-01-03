import SwiftUI

// MARK: - Settings Row
/// Reusable row component for settings list items
struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var showChevron: Bool = true
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Profile Header Row
/// User avatar and email display for settings
struct ProfileHeaderRow: View {
    let email: String?
    var isLoading: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.appPrimary.opacity(0.6), .appSecondary.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Text(avatarInitial)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("My Profile")
                    .font(.headline)
                
                Text(email ?? "Not signed in")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
            
            Text(title)
            
            Spacer()
            
            if disabled {
                Text("\(value) \(unit)")
                    .foregroundColor(.secondary)
            } else {
                TextField("", value: $value, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                
                Text(unit)
                    .foregroundColor(.secondary)
            }
        }
        .opacity(disabled ? 0.6 : 1)
    }
}

#Preview("Settings Row") {
    List {
        SettingsRow(icon: "📏", title: "Physical Stats", subtitle: "Height: 175cm, Weight: 70kg")
        SettingsRow(icon: "🎯", title: "Goals & Targets")
        SettingsRow(icon: "🔔", title: "Notifications")
    }
}

#Preview("Profile Header") {
    List {
        ProfileHeaderRow(email: "user@example.com")
    }
}
