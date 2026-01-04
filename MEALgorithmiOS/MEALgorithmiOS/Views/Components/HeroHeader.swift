import SwiftUI

// MARK: - Hero Header
/// 可伸缩的粘性头部组件
/// - 下拉放大效果 (Stretchy Header)
/// - Parallax 视差滚动
/// - 自动折叠/展开动画
struct HeroHeader<Content: View>: View {
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let backgroundColor: Color
    @ViewBuilder var content: (CGFloat) -> Content
    
    init(
        minHeight: CGFloat = 100,
        maxHeight: CGFloat = 300,
        backgroundColor: Color = .appBackground,
        @ViewBuilder content: @escaping (CGFloat) -> Content
    ) {
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.backgroundColor = backgroundColor
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geo in
            let scrollOffset = geo.frame(in: .global).minY
            let height = max(minHeight, maxHeight + scrollOffset)
            let scale = max(1.0, 1.0 + scrollOffset / maxHeight)
            let opacity = min(1.0, max(0, 1 - scrollOffset / -100))
            
            ZStack {
                // Background with Stretchy Effect
                backgroundColor
                    .frame(height: height)
                    .scaleEffect(scale, anchor: .top)
                    .offset(y: scrollOffset > 0 ? -scrollOffset : 0)
                
                // Content with Progress
                content(clamp(scrollOffset / maxHeight, min: -1, max: 1))
                    .opacity(opacity)
                    .scaleEffect(scale, anchor: .center)
                    .offset(y: scrollOffset > 0 ? -scrollOffset / 2 : 0) // Parallax
            }
            .frame(height: height)
            .clipped()
        }
        .frame(height: maxHeight)
    }
    
    private func clamp(_ value: CGFloat, min minVal: CGFloat, max maxVal: CGFloat) -> CGFloat {
        return max(minVal, min(maxVal, value))
    }
}

// MARK: - Collapsible Hero Header (with ScrollView integration)
/// 与 ScrollView 集成的可折叠 Hero Header
struct CollapsibleHeroHeader<HeaderContent: View, BodyContent: View>: View {
    let minHeight: CGFloat
    let maxHeight: CGFloat
    @ViewBuilder var headerContent: (CGFloat) -> HeaderContent
    @ViewBuilder var bodyContent: () -> BodyContent
    
    @State private var scrollOffset: CGFloat = 0
    
    init(
        minHeight: CGFloat = 60,
        maxHeight: CGFloat = 200,
        @ViewBuilder headerContent: @escaping (CGFloat) -> HeaderContent,
        @ViewBuilder bodyContent: @escaping () -> BodyContent
    ) {
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.headerContent = headerContent
        self.bodyContent = bodyContent
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Stretchy Header
                GeometryReader { geo in
                    let offset = geo.frame(in: .named("scroll")).minY
                    let height = max(minHeight, maxHeight + offset)
                    let progress = clamp(-offset / (maxHeight - minHeight), min: 0, max: 1)
                    
                    ZStack {
                        // Gradient Background
                        LinearGradient(
                            colors: [.appPrimary.opacity(0.3), .appSecondary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        headerContent(progress)
                    }
                    .frame(height: offset > 0 ? maxHeight + offset : height)
                    .offset(y: offset > 0 ? -offset : 0)
                    .onChange(of: offset) { _, newValue in
                        scrollOffset = newValue
                    }
                }
                .frame(height: maxHeight)
                
                // Body Content
                bodyContent()
            }
        }
        .coordinateSpace(name: "scroll")
    }
    
    private func clamp(_ value: CGFloat, min minVal: CGFloat, max maxVal: CGFloat) -> CGFloat {
        return max(minVal, min(maxVal, value))
    }
}

// MARK: - Hero Image Header
/// 带图片的 Hero Header
struct HeroImageHeader: View {
    let imageName: String?
    let systemImage: String?
    let title: String
    let subtitle: String?
    
    init(
        imageName: String? = nil,
        systemImage: String? = nil,
        title: String,
        subtitle: String? = nil
    ) {
        self.imageName = imageName
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        HeroHeader { progress in
            VStack(spacing: 8) {
                // Icon or Image
                if let imageName = imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                // Title
                Text(title)
                    .typography(.largeTitle)
                    .foregroundColor(.white)
                    .scaleEffect(1 - progress * 0.3)
                
                // Subtitle
                if let subtitle = subtitle {
                    Text(subtitle)
                        .typography(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(1 - Double(progress))
                }
            }
            .padding(.bottom, Spacing.large)
        }
    }
}

// MARK: - Preview
#Preview("Hero Header") {
    ScrollView {
        VStack(spacing: 0) {
            HeroHeader { progress in
                VStack {
                    Text("🍽️")
                        .font(.system(size: 60))
                        .scaleEffect(1 - progress * 0.3)
                    
                    Text("MEALgorithm")
                        .typography(.largeTitle)
                        .foregroundColor(.white)
                    
                    Text("Your AI-Powered Nutrition Assistant")
                        .typography(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(1 - Double(progress))
                }
            }
            
            VStack(spacing: Spacing.medium) {
                ForEach(0..<10, id: \.self) { i in
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 100)
                }
            }
            .padding(.horizontal, Spacing.horizontalPadding)
            .padding(.top, Spacing.large)
        }
    }
    .background(Color.appBackground)
    .ignoresSafeArea()
}

#Preview("Collapsible Hero") {
    CollapsibleHeroHeader(minHeight: 80, maxHeight: 220) { progress in
        VStack {
            Text("Dashboard")
                .font(.system(size: 34 - progress * 14, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            if progress < 0.5 {
                Text("Today's Overview")
                    .typography(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(1 - Double(progress * 2))
            }
        }
    } bodyContent: {
        VStack(spacing: Spacing.medium) {
            ForEach(0..<8, id: \.self) { i in
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 80)
            }
        }
        .padding(.horizontal, Spacing.horizontalPadding)
        .padding(.top, Spacing.large)
    }
    .background(Color.appBackground)
    .ignoresSafeArea()
}
