import SwiftUI

// MARK: - Glass Sheet
/// 标准化底部弹窗组件 - 毛玻璃材质背景
/// 支持拖拽关闭手势，自动计算高度
struct GlassSheet<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGFloat = 0
    
    let title: String?
    let showDragIndicator: Bool
    @ViewBuilder var content: () -> Content
    
    init(
        title: String? = nil,
        showDragIndicator: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.showDragIndicator = showDragIndicator
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator
            if showDragIndicator {
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }
            
            // Optional Title
            if let title = title {
                Text(title)
                    .typography(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Spacing.medium)
            }
            
            // Content
            content()
                .padding(.horizontal, Spacing.horizontalPadding)
        }
        .padding(.bottom, Spacing.large)
        .background(.ultraThinMaterial)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.1),
                    Color.white.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.4),
                            .white.opacity(0.1),
                            .clear,
                            .white.opacity(0.05),
                            .white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
    }
}

// MARK: - Glass Sheet Modifier
/// 用于以 sheet 形式呈现 GlassSheet 的 View 修饰符
struct GlassSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let title: String?
    @ViewBuilder var sheetContent: () -> SheetContent
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                GlassSheet(title: title) {
                    sheetContent()
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(.clear)
            }
    }
}

extension View {
    /// 以 Glass Sheet 样式呈现内容
    func glassSheet<Content: View>(
        isPresented: Binding<Bool>,
        title: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(GlassSheetModifier(
            isPresented: isPresented,
            title: title,
            sheetContent: content
        ))
    }
}

// MARK: - Preview
#Preview("Glass Sheet") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        GlassSheet(title: "Meal Details") {
            VStack(spacing: 16) {
                HStack {
                    Text("🍔")
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading) {
                        Text("Cheeseburger")
                            .typography(.headline)
                        Text("450 kcal")
                            .typography(.caption)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                HStack {
                    VStack {
                        Text("Protein")
                            .typography(.caption)
                        Text("25g")
                            .typography(.body)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("Carbs")
                            .typography(.caption)
                        Text("35g")
                            .typography(.body)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("Fat")
                            .typography(.caption)
                        Text("22g")
                            .typography(.body)
                    }
                }
                
                Button("Delete Meal") {
                    // Action
                }
                .foregroundColor(.red)
                .padding(.top)
            }
        }
        .padding()
    }
}
