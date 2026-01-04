import SwiftUI

// MARK: - Symbol Icon
/// 统一的 SF Symbols 图标组件
/// 支持渐变色、霓虹发光和圆形背景
struct SymbolIcon: View {
    let icon: IconType
    var size: CGFloat = 24
    var colors: [Color]? = nil
    var showBackground: Bool = false
    var backgroundSize: CGFloat? = nil
    var glowColor: Color? = nil
    var glowRadius: CGFloat = 8
    
    var body: some View {
        ZStack {
            if showBackground {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: backgroundSize ?? size * 1.8, height: backgroundSize ?? size * 1.8)
            }
            
            if let colors = colors, colors.count > 1 {
                Image(systemName: icon.rawValue)
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else if let colors = colors, let firstColor = colors.first {
                Image(systemName: icon.rawValue)
                    .font(.system(size: size, weight: .semibold))
                    .foregroundColor(firstColor)
            } else {
                Image(systemName: icon.rawValue)
                    .font(.system(size: size, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .modifier(NeonGlowModifier(color: glowColor, radius: glowRadius))
    }
    
    // MARK: - Icon Types
    enum IconType: String {
        // 餐食相关
        case meal = "fork.knife"
        case mealCircle = "fork.knife.circle.fill"
        case calories = "flame.fill"
        case protein = "fish.fill"
        case carbs = "leaf.fill"
        case fat = "drop.fill"
        
        // AI 相关
        case ai = "brain.head.profile"
        case aiFilled = "brain"
        case insight = "lightbulb.fill"
        case sparkles = "sparkles"
        
        // 功能相关
        case camera = "camera.fill"
        case cameraViewfinder = "camera.viewfinder"
        case photo = "photo.fill"
        case photoLibrary = "photo.on.rectangle"
        case calendar = "calendar"
        case clock = "clock.fill"
        case chart = "chart.bar.fill"
        case trend = "chart.line.uptrend.xyaxis"
        case search = "magnifyingglass"
        case target = "target"
        case text = "text.alignleft"
        case textCursor = "character.cursor.ibeam"
        
        // 设置相关
        case help = "questionmark.circle.fill"
        case email = "envelope.fill"
        case star = "star.fill"
        case privacy = "lock.shield.fill"
        case terms = "doc.text.fill"
        case knowledge = "book.fill"
        case clipboard = "list.bullet.clipboard.fill"
        
        // 状态相关
        case celebrate = "party.popper.fill"
        case checkmark = "checkmark.circle.fill"
        case refresh = "arrow.clockwise"
        
        // 宏量元素徽章
        case medal = "medal.fill"
        case trophy = "trophy.fill"
        
        // 健身/目标
        case fitness = "figure.run"
    }
}

// MARK: - Neon Glow Modifier (Private)
private struct NeonGlowModifier: ViewModifier {
    let color: Color?
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        if let color = color {
            content
                .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
                .shadow(color: color.opacity(0.3), radius: radius / 2, x: 0, y: 0)
        } else {
            content
        }
    }
}

// MARK: - Convenience Initializers
extension SymbolIcon {
    /// 创建带渐变背景圆的图标
    static func inCircle(
        _ icon: IconType,
        size: CGFloat = 20,
        colors: [Color],
        circleSize: CGFloat = 44,
        glowColor: Color? = nil
    ) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: circleSize, height: circleSize)
            
            Image(systemName: icon.rawValue)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(.white)
        }
        .modifier(NeonGlowModifier(color: glowColor, radius: 10))
    }
    
    /// 创建营养图标 (calories, protein, carbs, fat)
    static func nutrition(
        _ type: NutritionType,
        size: CGFloat = 20
    ) -> some View {
        SymbolIcon(
            icon: type.icon,
            size: size,
            colors: type.colors
        )
    }
    
    enum NutritionType {
        case calories, protein, carbs, fat
        
        var icon: IconType {
            switch self {
            case .calories: return .calories
            case .protein: return .protein
            case .carbs: return .carbs
            case .fat: return .fat
            }
        }
        
        var colors: [Color] {
            switch self {
            case .calories: return [.caloriesStart, .caloriesEnd]
            case .protein: return [.proteinStart, .proteinEnd]
            case .carbs: return [.carbsStart, .carbsEnd]
            case .fat: return [.fatStart, .fatEnd]
            }
        }
    }
}

// MARK: - Rank Badge
/// 排名徽章组件 (替代 🥇🥈🥉)
struct RankBadge: View {
    let rank: Int
    var size: CGFloat = 24
    
    private var color: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .green
        }
    }
    
    private var iconName: String {
        switch rank {
        case 1, 2, 3: return "medal.fill"
        default: return "fork.knife"
        }
    }
    
    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(color)
            .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
    }
}

// MARK: - Preview
#Preview("Symbol Icons") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        VStack(spacing: 24) {
            // Basic icons
            HStack(spacing: 20) {
                SymbolIcon(icon: .meal, size: 28)
                SymbolIcon(icon: .calories, size: 28, colors: [.caloriesStart, .caloriesEnd])
                SymbolIcon(icon: .ai, size: 28, colors: [.green, .teal], glowColor: .green)
                SymbolIcon(icon: .insight, size: 28, colors: [.yellow])
            }
            
            // Nutrition icons
            HStack(spacing: 20) {
                SymbolIcon.nutrition(.calories)
                SymbolIcon.nutrition(.protein)
                SymbolIcon.nutrition(.carbs)
                SymbolIcon.nutrition(.fat)
            }
            
            // Icons in circles
            HStack(spacing: 20) {
                SymbolIcon.inCircle(.ai, colors: [.green, .teal], glowColor: .green)
                SymbolIcon.inCircle(.insight, colors: [.yellow, .orange])
                SymbolIcon.inCircle(.meal, colors: [.appPrimary, .appSecondary])
            }
            
            // Rank badges
            HStack(spacing: 20) {
                RankBadge(rank: 1)
                RankBadge(rank: 2)
                RankBadge(rank: 3)
                RankBadge(rank: 4)
            }
            
            // Settings icons
            HStack(spacing: 20) {
                SymbolIcon(icon: .help, size: 24, colors: [.blue])
                SymbolIcon(icon: .email, size: 24, colors: [.green])
                SymbolIcon(icon: .star, size: 24, colors: [.yellow])
                SymbolIcon(icon: .privacy, size: 24, colors: [.purple])
            }
        }
        .padding()
    }
}
