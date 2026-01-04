import SwiftUI
import PhotosUI

// MARK: - Meal Log View (Premium Redesign)
/// Apple Design Award 级别的 Meal Log 界面
/// 遵循 Dashboard 的设计语言：Nebula 背景、玻璃磨砂材质、霓虹发光
struct MealLogView: View {
    @StateObject private var viewModel = MealLogViewModel()
    @State private var showCamera = false
    @Namespace private var inputModeAnimation
    @State private var successScale: CGFloat = 0.5
    @State private var selectedTip: TipType?
    
    enum TipType: Identifiable {
        case photoTips
        case beSpecific
        case consistency
        
        var id: Self { self }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Premium Nebula Background
                nebulaBackground
                
                switch viewModel.step {
                case .input:
                    inputView
                case .preview:
                    previewView
                case .saving:
                    savingView
                case .done:
                    doneView
                }
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCamera) {
                CameraView(image: $viewModel.selectedImage)
            }
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Nebula Background
    private var nebulaBackground: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            // Multi-layer Ambient Glow (Dashboard 风格)
            GeometryReader { geo in
                // Primary Calories Orb (Orange/Warm)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.caloriesColor.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.5
                        )
                    )
                    .frame(width: geo.size.width * 0.8)
                    .blur(radius: 60)
                    .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.1)
                
                // Secondary Green Orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appSecondary.opacity(0.25), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.4
                        )
                    )
                    .frame(width: geo.size.width * 0.6)
                    .blur(radius: 50)
                    .offset(x: geo.size.width * 0.5, y: geo.size.height * 0.5)
                
                // Accent Cyan Orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appPrimary.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.3
                        )
                    )
                    .frame(width: geo.size.width * 0.5)
                    .blur(radius: 40)
                    .offset(x: geo.size.width * 0.2, y: geo.size.height * 0.3)
            }
            .ignoresSafeArea()
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    // MARK: - Input View
    private var inputView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.large) {
                // Premium Header Badge
                headerBadge
                
                // Error message
                if let error = viewModel.error {
                    errorBanner(error)
                }
                
                // Premium Input Mode Toggle
                inputModeToggle
                
                // Input Area
                if viewModel.inputMode == .text {
                    textInputArea
                } else {
                    imageInputArea
                }
                
                // Date/Time Picker
                dateTimeSection
                
                // Meal Type
                mealTypeSection
                
                // Analyze Button
                analyzeButton
                
                // Tips
                tipsSection
            }
            .padding(.horizontal, Spacing.horizontalPadding)
            .padding(.bottom, 120)
        }
        .scrollDismissesKeyboard(.interactively)
        .addDoneButton()
    }
    
    // MARK: - Header Badge
    private var headerBadge: some View {
        VStack(spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Text("📸")
                Text("AI-Powered Analysis")
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(.ultraThinMaterial)
            .foregroundColor(.caloriesColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.caloriesColor.opacity(0.3), lineWidth: 1)
            )
            
            Text("Snap a photo or describe what you ate")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.top, Spacing.medium)
    }
    
    // MARK: - Error Banner
    private func errorBanner(_ error: String) -> some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(error)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(Color.red.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - Premium Input Mode Toggle
    private var inputModeToggle: some View {
        HStack(spacing: 0) {
            ForEach([MealLogViewModel.InputMode.text, .image], id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.inputMode = mode
                    }
                    HapticManager.shared.impact(style: .light)
                } label: {
                    HStack(spacing: 6) {
                        Text(mode == .text ? "📝" : "📷")
                        Text(mode == .text ? "Text" : "Photo")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.inputMode == mode
                        ? AnyView(
                            Capsule()
                                .fill(.white)
                                .matchedGeometryEffect(id: "inputToggle", in: inputModeAnimation)
                        )
                        : AnyView(Color.clear)
                    )
                    .foregroundColor(viewModel.inputMode == mode ? .black : .white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Text Input Area
    private var textInputArea: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $viewModel.textInput)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(height: 140)
                .padding(Spacing.medium)
            
            if viewModel.textInput.isEmpty {
                Text("Describe your meal... e.g., 'I had a grilled chicken salad with olive oil dressing'")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(Spacing.medium)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Image Input Area
    private var imageInputArea: some View {
        VStack(spacing: Spacing.medium) {
            if let image = viewModel.selectedImage {
                // Selected Image Preview
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                Button {
                    viewModel.selectedImage = nil
                    viewModel.selectedPhotoItem = nil
                    HapticManager.shared.impact(style: .light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Remove")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
            } else {
                // Empty State - Photo Selection
                VStack(spacing: Spacing.medium) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.appPrimary.opacity(0.2), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Text("📷")
                            .font(.system(size: 48))
                    }
                    
                    Text("Choose a photo of your meal")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: Spacing.medium) {
                        // Photo Library Button
                        PhotosPicker(
                            selection: $viewModel.selectedPhotoItem,
                            matching: .images
                        ) {
                            VStack(spacing: Spacing.small) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 24, weight: .medium))
                                Text("Library")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.appPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.medium)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                                    .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .onChange(of: viewModel.selectedPhotoItem) { _, newValue in
                            Task {
                                await viewModel.handlePhotoSelection(newValue)
                            }
                            HapticManager.shared.impact(style: .light)
                        }
                        
                        // Camera Button
                        Button {
                            showCamera = true
                            HapticManager.shared.impact(style: .medium)
                        } label: {
                            VStack(spacing: Spacing.small) {
                                Image(systemName: "camera")
                                    .font(.system(size: 24, weight: .medium))
                                Text("Camera")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.appSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.medium)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                                    .stroke(Color.appSecondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .cardPressEffect()
                    }
                }
                .padding(Spacing.large)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 2, dash: [10])
                        )
                )
            }
        }
    }
    
    // MARK: - Date Time Section
    private var dateTimeSection: some View {
        HStack(spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("📅")
                    Text("Date")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                DatePicker("", selection: $viewModel.mealDate, displayedComponents: .date)
                    .labelsHidden()
                    .tint(.appPrimary)
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("⏰")
                    Text("Time")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                DatePicker("", selection: $viewModel.mealDate, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(.appPrimary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Meal Type Section
    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Meal Type")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            
            Picker("Meal Type", selection: $viewModel.mealType) {
                ForEach(MealType.allCases, id: \.self) { type in
                    Text("\(type.icon) \(type.displayName)").tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.mealType) { _, _ in
                HapticManager.shared.selection()
            }
        }
    }
    
    // MARK: - Analyze Button
    private var analyzeButton: some View {
        Button {
            Task {
                await viewModel.analyzeMeal()
            }
            HapticManager.shared.impact(style: .medium)
        } label: {
            Group {
                if viewModel.isAnalyzing {
                    HStack(spacing: Spacing.small) {
                        ProgressView()
                            .tint(.white)
                        Text("Analyzing...")
                            .font(.system(size: 17, weight: .semibold))
                    }
                } else {
                    HStack(spacing: Spacing.small) {
                        Text("🔍")
                        Text("Analyze with AI")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [.appPrimary.opacity(0.7), .appSecondary.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .neonGlow(color: .appPrimary.opacity(0.7), radius: 10)
        }
        .disabled(viewModel.isAnalyzing || (viewModel.inputMode == .text ? viewModel.textInput.isEmpty : viewModel.selectedImage == nil))
        .opacity((viewModel.isAnalyzing || (viewModel.inputMode == .text ? viewModel.textInput.isEmpty : viewModel.selectedImage == nil)) ? 0.6 : 1)
        .cardPressEffect()
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Spacing.small),
            GridItem(.flexible(), spacing: Spacing.small),
            GridItem(.flexible(), spacing: Spacing.small)
        ], spacing: Spacing.small) {
            PremiumTipCard(
                icon: "📷",
                title: "Photo Tips",
                message: "Clear, well-lit"
            ) {
                selectedTip = .photoTips
            }
            
            PremiumTipCard(
                icon: "✍️",
                title: "Be Specific",
                message: "Add portions"
            ) {
                selectedTip = .beSpecific
            }
            
            PremiumTipCard(
                icon: "🎯",
                title: "Consistency",
                message: "Log all meals"
            ) {
                selectedTip = .consistency
            }
        }
        .sheet(item: $selectedTip) { tip in
            TipDetailSheet(tipType: tip)
        }
    }
    
    // MARK: - Preview View
    private var previewView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.large) {
                if viewModel.isAnalyzing {
                    // Premium Loading Animation
                    analyzingAnimation
                } else if let analysis = viewModel.analysis {
                    // Food Items Card
                    foodItemsCard(analysis: analysis)
                    
                    // Premium Nutrition Summary
                    nutritionSummaryGrid(analysis: analysis)
                    
                    // AI Feedback Card
                    aiFeedbackCard(feedback: analysis.feedback)
                    
                    // Action Buttons
                    actionButtons
                }
            }
            .padding(.horizontal, Spacing.horizontalPadding)
            .padding(.bottom, 120)
        }
    }
    
    // MARK: - Analyzing Animation
    private var analyzingAnimation: some View {
        VStack(spacing: Spacing.large) {
            ZStack {
                // Pulsing Background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appPrimary.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                
                Text("🤖")
                    .font(.system(size: 44))
            }
            .neonGlow(color: .appPrimary, radius: 20)
            
            Text("Analyzing your meal...")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Our AI is identifying ingredients and calculating nutrition")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(Spacing.large)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }
    
    // MARK: - Food Items Card
    private func foodItemsCard(analysis: MealAnalysis) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text("🍽️")
                    .font(.title2)
                Text("Food Items")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(analysis.items.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            ForEach(analysis.items) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text(item.quantity)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Text("\(item.nutrition.calories)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.caloriesColor)
                    Text("kcal")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(Spacing.medium)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Nutrition Summary Grid
    private func nutritionSummaryGrid(analysis: MealAnalysis) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Spacing.medium),
            GridItem(.flexible(), spacing: Spacing.medium)
        ], spacing: Spacing.medium) {
            PremiumNutritionCard(
                icon: "🔥",
                title: "Calories",
                value: analysis.summary.calories,
                suffix: "",
                colors: [.caloriesStart, .caloriesEnd]
            )
            PremiumNutritionCard(
                icon: "🥩",
                title: "Protein",
                value: analysis.summary.protein,
                suffix: "g",
                colors: [.proteinStart, .proteinEnd]
            )
            PremiumNutritionCard(
                icon: "🍞",
                title: "Carbs",
                value: analysis.summary.carbs,
                suffix: "g",
                colors: [.carbsStart, .carbsEnd]
            )
            PremiumNutritionCard(
                icon: "🧈",
                title: "Fat",
                value: analysis.summary.fat,
                suffix: "g",
                colors: [.fatStart, .fatEnd]
            )
        }
    }
    
    // MARK: - AI Feedback Card
    private func aiFeedbackCard(feedback: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(spacing: Spacing.small) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .neonGlow(color: .green, radius: 8)
                    
                    Text("💡")
                        .font(.title3)
                }
                
                Text("AI Insight")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(feedback)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .gradientBorder(colors: [.green.opacity(0.6), .teal.opacity(0.3)], lineWidth: 1.5)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: Spacing.medium) {
            // Edit Button
            Button {
                viewModel.goBack()
                HapticManager.shared.impact(style: .light)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                    Text("Edit")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .cardPressEffect()
            
            // Confirm & Save Button
            Button {
                Task {
                    await viewModel.saveMeal()
                }
                HapticManager.shared.impact(style: .medium)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                    Text("Confirm & Save")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
                .neonGlow(color: .green, radius: 10)
            }
            .cardPressEffect()
        }
    }
    
    // MARK: - Saving View
    private var savingView: some View {
        VStack(spacing: Spacing.large) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appPrimary.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                ProgressView()
                    .scaleEffect(2)
                    .tint(.appPrimary)
            }
            
            Text("Saving your meal...")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Done View
    private var doneView: some View {
        VStack(spacing: Spacing.xl) {
            ZStack {
                // Success Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.green.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .neonGlow(color: .green, radius: 30)
                
                Text("✅")
                    .font(.system(size: 80))
                    .scaleEffect(successScale)
            }
            
            VStack(spacing: Spacing.small) {
                Text("Meal Logged!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Your meal has been saved successfully.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Button {
                viewModel.reset()
                successScale = 0.5
                HapticManager.shared.impact(style: .medium)
            } label: {
                HStack(spacing: Spacing.small) {
                    Image(systemName: "plus")
                    Text("Log Another Meal")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [.appPrimary, .appSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .neonGlow(color: .appPrimary, radius: 12)
            }
            .cardPressEffect()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                successScale = 1.0
            }
            HapticManager.shared.notification(type: .success)
        }
    }
}

// MARK: - Premium Tip Card
struct PremiumTipCard: View {
    let icon: String
    let title: String
    let message: String
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
            HapticManager.shared.impact(style: .light)
        } label: {
            VStack(spacing: 6) {
                Text(icon)
                    .font(.title3)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                Text(message)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.medium)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .cardPressEffect()
    }
}

// MARK: - Tip Detail Sheet
struct TipDetailSheet: View {
    let tipType: MealLogView.TipType
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Text(tipIcon)
                            .font(.system(size: 48))
                        Text(tipTitle)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(tipContent, id: \.self) { paragraph in
                            Text(paragraph)
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(4)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(tipTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.appPrimary)
                }
            }
        }
    }
    
    private var tipIcon: String {
        switch tipType {
        case .photoTips: return "📷"
        case .beSpecific: return "✍️"
        case .consistency: return "🎯"
        }
    }
    
    private var tipTitle: String {
        switch tipType {
        case .photoTips: return "Photo Tips"
        case .beSpecific: return "Be Specific"
        case .consistency: return "Consistency"
        }
    }
    
    private var tipContent: [String] {
        switch tipType {
        case .photoTips:
            return [
                "🌟 Use natural lighting whenever possible. Take photos near windows or outdoors for the best results.",
                "📐 Position your camera directly above the plate for a clear bird's-eye view of all the food items.",
                "🍽️ Make sure all food items are visible and not hidden under other items or covered by sauce.",
                "📏 Include something for scale reference if possible, like a fork or napkin, to help the AI estimate portion sizes.",
                "🧹 Keep the background clean and uncluttered so the AI can focus on the food.",
                "📸 Take multiple photos from different angles if your first attempt didn't capture everything clearly."
            ]
        case .beSpecific:
            return [
                "📝 Describe the portion size using common measurements: cups, tablespoons, ounces, or palm-sized comparisons.",
                "🥗 List all ingredients you can identify, including sauces, dressings, and toppings.",
                "🍳 Mention the cooking method: grilled, fried, steamed, baked, or raw.",
                "🏷️ If you know the brand name (for packaged foods), include it for more accurate nutrition data.",
                "⚖️ Estimate quantities: \"about 1 cup of rice\" or \"2 medium eggs\" helps improve accuracy.",
                "🍝 For mixed dishes, describe the main components: \"pasta with tomato sauce, ground beef, and parmesan cheese.\""
            ]
        case .consistency:
            return [
                "⏰ Log meals at consistent times each day to build a healthy tracking habit.",
                "🍽️ Record everything you eat, including small snacks and drinks. They add up!",
                "📊 Regular logging helps you identify eating patterns and make better dietary choices.",
                "🎯 Set a daily reminder to log your meals right after eating, when details are fresh in your memory.",
                "📈 Consistent tracking provides more accurate insights from AI recommendations over time.",
                "💪 Even if you have an unhealthy meal, log it anyway. Honest tracking leads to real progress!"
            ]
        }
    }
}


// MARK: - Premium Nutrition Card
struct PremiumNutritionCard: View {
    let icon: String
    let title: String
    let value: Int
    let suffix: String
    let colors: [Color]
    
    var body: some View {
        VStack(spacing: Spacing.small) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)
                    .neonGlow(color: colors.last ?? .white, radius: 8)
                
                Text(icon)
                    .font(.title3)
            }
            
            Text("\(value)\(suffix)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(colors.last ?? .white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(colors.last?.opacity(0.3) ?? .clear, lineWidth: 1)
        )
    }
}

// MARK: - Nutrition Summary Card (Legacy - kept for compatibility)
struct NutritionSummaryCard: View {
    let value: Int
    let label: String
    let color: Color
    var suffix: String = ""
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)\(suffix)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Tip Card (Legacy - kept for compatibility)
struct TipCard: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title2)
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Text(message)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - Camera View
/// UIViewControllerRepresentable wrapper for UIImagePickerController camera
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    MealLogView()
}
