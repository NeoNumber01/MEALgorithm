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
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background {
            ZStack {
                // Frosted Glass Base
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                // Subtle Tint for Contrast (Apple-like)
                Rectangle()
                    .fill(Color.black.opacity(0.2))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.5),  // Top rim light
                            .white.opacity(0.1),  // Side fade
                            .white.opacity(0.05)  // Bottom shadow
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        )
        // Multi-layer shadow for depth
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 24)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
        .padding(.bottom, safeAreaBottomPadding)
    }
    
    /// 动态计算底部 padding，确保与屏幕边框曲线平行
    private var safeAreaBottomPadding: CGFloat {
        // 获取当前窗口的安全区域
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow })
        else {
            return 8 // 默认值
        }
        
        let bottomSafeArea = window.safeAreaInsets.bottom
        
        // 对于有 Home Indicator 的设备（如 iPhone X 及以上），使用较小的额外 padding
        // 因为 Safe Area 已经提供了足够的间距
        // 对于有 Home 按钮的设备，使用稍大的 padding 保持美观
        if bottomSafeArea > 0 {
            return max(bottomSafeArea - 20, 4) // 有 Home Indicator 的设备
        } else {
            return 8 // 有 Home 按钮的设备
        }
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
                                colors: [.appPrimary.opacity(0.2), .appSecondary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [.appPrimary.opacity(0.6), .appSecondary.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .appPrimary.opacity(0.3), radius: 8, x: 0, y: 0)
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
                .font(.system(.body, design: .rounded))
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
                .font(.system(.title2, design: .rounded))
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
                        .shadow(color: .appPrimary.opacity(0.4), radius: 10, x: 0, y: 5)
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
