import SwiftUI

// MARK: - Custom Tab Bar
/// Custom floating tab bar with smooth tab switching animation
struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: animation
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .liquidGlass(intensity: .thick, cornerRadius: 30)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let tab: MainTabView.Tab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.appPrimary, .appSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .matchedGeometryEffect(id: "TAB_INDICATOR", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var message: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.appPrimary)
            
            Text(message)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 60))
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.appPrimary, .appSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(32)
    }
}

// MARK: - Confirm Modal
struct ConfirmModal: View {
    let title: String
    let message: String
    let confirmText: String
    let cancelText: String
    let isDestructive: Bool
    let isLoading: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    init(
        title: String,
        message: String,
        confirmText: String = "Confirm",
        cancelText: String = "Cancel",
        isDestructive: Bool = true,
        isLoading: Bool = false,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmText = confirmText
        self.cancelText = cancelText
        self.isDestructive = isDestructive
        self.isLoading = isLoading
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.headline)
            
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text(cancelText)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }
                .disabled(isLoading)
                
                Button(action: onConfirm) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(confirmText)
                    }
                }
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isDestructive ? Color.red : Color.appPrimary)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isLoading)
            }
        }
        .padding(24)
        .liquidGlass(cornerRadius: 20)
        .padding(32)
    }
}

// MARK: - Offline Banner
struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("No Internet Connection")
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.red)
        .foregroundColor(.white)
        .transition(.move(edge: .top))
    }
}

// MARK: - Haptic Manager
/// Manages haptic feedback for a premium feel
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Skeleton Loading Modifier
/// Adds a shimmering skeleton effect for loading states
struct SkeletonModifier: ViewModifier {
    let isLoading: Bool
    let opacity: Double
    let duration: Double
    
    @State private var phase: CGFloat = 0
    
    init(isLoading: Bool, opacity: Double = 0.5, duration: Double = 1.5) {
        self.isLoading = isLoading
        self.opacity = opacity
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        if isLoading {
            content
                .opacity(0)
                .overlay(
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background
                            Color(.systemGray5)
                            
                            // Highlight
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .white.opacity(0.5), location: 0.5),
                                    .init(color: .clear, location: 1)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 150)
                            .offset(x: phase * geo.size.width * 2 - 50)
                        }
                    }
                )
                .mask(content)
                .onAppear {
                    withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func skeleton(isLoading: Bool) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading))
    }
    
    func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.simultaneousGesture(TapGesture().onEnded { _ in
            HapticManager.shared.impact(style: style)
        })
    }
}

// MARK: - Previews
#Preview("Tab Bar") {
    VStack {
        Spacer()
        CustomTabBar(selectedTab: .constant(.dashboard))
    }
}

#Preview("Loading") {
    LoadingView()
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "🍽️",
        title: "No meals logged yet",
        message: "Start tracking your nutrition today!",
        actionTitle: "Log your meal"
    ) {}
}
