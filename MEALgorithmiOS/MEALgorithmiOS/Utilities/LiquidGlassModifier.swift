import SwiftUI

// MARK: - Liquid Glass Modifier
/// Provides iOS 26 Liquid Glass effect with backward compatibility to iOS 17+
/// On iOS 26+: Uses native .glassEffect() modifier
/// On earlier iOS: Uses ultraThinMaterial fallback with custom styling

struct LiquidGlassModifier: ViewModifier {
    var intensity: GlassIntensity = .regular
    var cornerRadius: CGFloat = 20
    
    enum GlassIntensity {
        case thin
        case regular
        case thick
        
        var opacity: Double {
            switch self {
            case .thin: return 0.1
            case .regular: return 0.15
            case .thick: return 0.25
            }
        }
        
        var blurRadius: CGFloat {
            switch self {
            case .thin: return 10
            case .regular: return 20
            case .thick: return 30
            }
        }
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            // iOS 26+ with native Liquid Glass
            content
                .glassEffect(.regular)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            // Fallback for iOS 17-25
            content
                .background(.ultraThinMaterial)
                .background(
                    Color.white.opacity(intensity.opacity)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - View Extension
extension View {
    /// Apply Liquid Glass effect with default settings
    func liquidGlass() -> some View {
        modifier(LiquidGlassModifier())
    }
    
    /// Apply Liquid Glass effect with custom settings
    func liquidGlass(intensity: LiquidGlassModifier.GlassIntensity, cornerRadius: CGFloat = 20) -> some View {
        modifier(LiquidGlassModifier(intensity: intensity, cornerRadius: cornerRadius))
    }
}

// MARK: - Gradient Card Modifier
/// Creates gradient background cards for macro display
struct GradientCardModifier: ViewModifier {
    let colors: [Color]
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: colors.first?.opacity(0.3) ?? .clear, radius: 10, x: 0, y: 5)
    }
}

extension View {
    func gradientCard(colors: [Color], cornerRadius: CGFloat = 16) -> some View {
        modifier(GradientCardModifier(colors: colors, cornerRadius: cornerRadius))
    }
}

// MARK: - Animated Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Hover Effect Modifier (for hover/press states)
struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isHovered ? -4 : 0)
            .shadow(
                color: .black.opacity(isHovered ? 0.15 : 0.1),
                radius: isHovered ? 15 : 10,
                x: 0,
                y: isHovered ? 8 : 5
            )
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onTapGesture {} // Enable gesture detection
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isHovered = true }
                    .onEnded { _ in isHovered = false }
            )
    }
}

extension View {
    func hoverEffect() -> some View {
        modifier(HoverEffectModifier())
    }
}
