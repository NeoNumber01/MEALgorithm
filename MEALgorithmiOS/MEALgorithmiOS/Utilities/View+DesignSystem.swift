import SwiftUI

// MARK: - Design Tokens (Spacing)
/// 设计系统间距令牌 - 使用统一的间距值避免魔法数字
enum Spacing {
    static let xs: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    
    /// 标准水平内边距 (Bento 哲学)
    static let horizontalPadding: CGFloat = 20
}

// MARK: - Design Tokens (Corner Radius)
/// 设计系统圆角令牌
enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 20
    static let card: CGFloat = 24
}

// MARK: - Typography System
/// 排版样式枚举 - 遵循 Apple HIG 标准
enum TypographyStyle {
    case largeTitle   // 34pt, Black/Heavy, Tight Tracking (-1.0)
    case headline     // 20pt, Bold, Rounded
    case body         // 17pt, Regular
    case caption      // 13pt, Medium, Gray
    case callout      // 16pt, Medium
    
    var font: Font {
        switch self {
        case .largeTitle:
            return .system(size: 34, weight: .black, design: .rounded)
        case .headline:
            return .system(size: 20, weight: .bold, design: .rounded)
        case .body:
            return .system(size: 17, weight: .regular, design: .default)
        case .caption:
            return .system(size: 13, weight: .medium, design: .default)
        case .callout:
            return .system(size: 16, weight: .medium, design: .default)
        }
    }
    
    var tracking: CGFloat {
        switch self {
        case .largeTitle: return -1.0
        case .headline: return -0.5
        default: return 0
        }
    }
    
    var foregroundColor: Color? {
        switch self {
        case .caption: return .secondary
        default: return nil
        }
    }
}

// MARK: - Typography Modifier
/// 应用统一排版样式
struct TypographyModifier: ViewModifier {
    let style: TypographyStyle
    
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.tracking)
            .if(style.foregroundColor != nil) { view in
                view.foregroundColor(style.foregroundColor)
            }
    }
}

// MARK: - Bouncy Button Style (呼吸按钮效果)
/// 按下时产生弹性缩放效果的按钮样式
/// - 按下缩放至 0.96
/// - 使用 Spring 动画 (response: 0.5, dampingFraction: 0.7)
/// - 自动触发触觉反馈
struct BouncyButtonStyle: ButtonStyle {
    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0),
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.shared.impact(style: hapticStyle)
                }
            }
    }
}

// MARK: - Bento Card Modifier
/// Bento 风格卡片修饰符 - 统一的圆角卡片样式
/// - padding(16)
/// - cornerRadius: 24
/// - 阴影效果
struct BentoCardModifier: ViewModifier {
    var backgroundColor: Color = Color(uiColor: .secondarySystemGroupedBackground)
    var cornerRadius: CGFloat = CornerRadius.card
    
    func body(content: Content) -> some View {
        content
            .padding(Spacing.medium)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Shimmer Effect (增强版骨架屏)
/// 可配置的闪烁效果修饰符
struct ShimmerModifier: ViewModifier {
    let active: Bool
    let duration: Double
    
    @State private var phase: CGFloat = 0
    
    init(active: Bool, duration: Double = 1.5) {
        self.active = active
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        if active {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.6), location: 0.5),
                                .init(color: .clear, location: 1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 120)
                        .offset(x: phase * geo.size.width * 1.5 - 60)
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

// MARK: - View Extensions for Design System
extension View {
    /// 应用排版样式
    /// - Parameter style: TypographyStyle 枚举值
    func typography(_ style: TypographyStyle) -> some View {
        modifier(TypographyModifier(style: style))
    }
    
    /// 应用 Bento 卡片样式
    /// - Parameters:
    ///   - backgroundColor: 背景颜色，默认为 secondarySystemGroupedBackground
    ///   - cornerRadius: 圆角半径，默认 24
    func bentoCardStyle(
        backgroundColor: Color = Color(uiColor: .secondarySystemGroupedBackground),
        cornerRadius: CGFloat = CornerRadius.card
    ) -> some View {
        modifier(BentoCardModifier(backgroundColor: backgroundColor, cornerRadius: cornerRadius))
    }
    
    /// 应用 Bento 卡片样式 (使用Liquid Glass背景)
    func benteLiquidCardStyle() -> some View {
        self
            .padding(Spacing.medium)
            .liquidGlass(cornerRadius: CornerRadius.card)
    }
    
    /// 应用闪烁效果
    /// - Parameters:
    ///   - active: 是否激活
    ///   - duration: 动画持续时间
    func shimmering(active: Bool, duration: Double = 1.5) -> some View {
        modifier(ShimmerModifier(active: active, duration: duration))
    }
    
    /// 使按钮具有弹性效果
    func bouncable() -> some View {
        self.buttonStyle(BouncyButtonStyle())
    }
    
    /// 标准 Spring 动画
    func springAnimation<V: Equatable>(value: V) -> some View {
        self.animation(
            .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0),
            value: value
        )
    }
    
    /// 霓虹发光效果
    func neonGlow(color: Color, radius: CGFloat = 15) -> some View {
        self
            .shadow(color: color.opacity(0.8), radius: radius / 2, x: 0, y: 0)
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 1.5, x: 0, y: 0)
    }
    
    /// 卡片按压效果 (缩放 + 阴影变化)
    func cardPressEffect() -> some View {
        self.buttonStyle(CardPressButtonStyle())
    }
    
    /// 时间轴样式 (左侧带竖线)
    func timelineStyle(color: Color = .appPrimary, isLast: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                
                if !isLast {
                    Rectangle()
                        .fill(color.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            
            self
        }
    }
    
    /// 渐变边框效果
    func gradientBorder(colors: [Color], lineWidth: CGFloat = 2, cornerRadius: CGFloat = CornerRadius.card) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: lineWidth
                )
        )
    }
}

// MARK: - Card Press Button Style
/// 卡片按压时的缩放和阴影效果
struct CardPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.1 : 0.15),
                radius: configuration.isPressed ? 5 : 15,
                x: 0,
                y: configuration.isPressed ? 2 : 8
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.shared.impact(style: .medium)
                }
            }
    }
}

// MARK: - Previews
#Preview("Bouncy Button") {
    VStack(spacing: 20) {
        Button("Tap Me") {
            print("Tapped!")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [.appPrimary, .appSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .foregroundColor(.white)
        .clipShape(Capsule())
        .bouncable()
        
        Button {
            print("Card tapped!")
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bento Card")
                    .typography(.headline)
                Text("This is a sample bento card with the standard styling applied.")
                    .typography(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .bentoCardStyle()
        .bouncable()
        .padding(.horizontal, Spacing.horizontalPadding)
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Typography") {
    VStack(alignment: .leading, spacing: 16) {
        Text("Large Title")
            .typography(.largeTitle)
        
        Text("Headline Style")
            .typography(.headline)
        
        Text("Body text looks like this. It uses the default system font with regular weight.")
            .typography(.body)
        
        Text("Caption text is smaller and gray")
            .typography(.caption)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
}

#Preview("Shimmer Effect") {
    VStack(spacing: 20) {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 100)
            .shimmering(active: true)
        
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 60)
            .shimmering(active: true)
    }
    .padding()
}
