import SwiftUI
import PhotosUI

// MARK: - Meal Log View
struct MealLogView: View {
    @StateObject private var viewModel = MealLogViewModel()
    @State private var showCamera = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.caloriesColor.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
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
    
    // MARK: - Input View
    private var inputView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Text("📸")
                        Text("AI-Powered Analysis")
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.caloriesColor.opacity(0.1))
                    .foregroundColor(.caloriesColor)
                    .cornerRadius(20)
                    
                    Text("Snap a photo or describe what you ate")
                        .foregroundColor(.secondary)
                }
                
                // Error message
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Input Mode Toggle
                HStack(spacing: 0) {
                    Button {
                        viewModel.inputMode = .text
                    } label: {
                        Text("📝 Text")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(viewModel.inputMode == .text ? Color.appPrimary : Color.clear)
                            .foregroundColor(viewModel.inputMode == .text ? .white : .primary)
                    }
                    
                    Button {
                        viewModel.inputMode = .image
                    } label: {
                        Text("📷 Photo")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(viewModel.inputMode == .image ? Color.appPrimary : Color.clear)
                            .foregroundColor(viewModel.inputMode == .image ? .white : .primary)
                    }
                }
                .background(Color(.systemGray5))
                .cornerRadius(12)
                
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
                Button {
                    Task {
                        await viewModel.analyzeMeal()
                    }
                } label: {
                    if viewModel.isAnalyzing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        HStack {
                            Text("🔍")
                            Text("Analyze with AI")
                                .fontWeight(.semibold)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.appPrimary, .appSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(viewModel.isAnalyzing || (viewModel.inputMode == .text ? viewModel.textInput.isEmpty : viewModel.selectedImage == nil))
                
                // Tips
                tipsSection
            }
            .padding()
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Text Input Area
    private var textInputArea: some View {
        TextEditor(text: $viewModel.textInput)
            .frame(height: 120)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                Group {
                    if viewModel.textInput.isEmpty {
                        Text("Describe your meal... e.g., 'I had a grilled chicken salad with olive oil dressing'")
                            .foregroundColor(.secondary)
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                },
                alignment: .topLeading
            )
    }
    
    // MARK: - Image Input Area
    private var imageInputArea: some View {
        VStack(spacing: 16) {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                
                Button("Remove", role: .destructive) {
                    viewModel.selectedImage = nil
                    viewModel.selectedPhotoItem = nil
                }
            } else {
                VStack(spacing: 16) {
                    Text("📷")
                        .font(.system(size: 48))
                    
                    Text("Choose a photo of your meal")
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        PhotosPicker(
                            selection: $viewModel.selectedPhotoItem,
                            matching: .images
                        ) {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.appPrimary.opacity(0.1))
                                .foregroundColor(.appPrimary)
                                .cornerRadius(8)
                        }
                        .onChange(of: viewModel.selectedPhotoItem) { _, newValue in
                            Task {
                                await viewModel.handlePhotoSelection(newValue)
                            }
                        }
                        
                        // Camera button
                        Button {
                            showCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera")
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.appSecondary.opacity(0.1))
                                .foregroundColor(.appSecondary)
                                .cornerRadius(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .foregroundColor(.secondary.opacity(0.3))
                )
            }
        }
    }
    
    // MARK: - Date Time Section
    private var dateTimeSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("📅 Date")
                    .font(.caption)
                    .foregroundColor(.secondary)
                DatePicker("", selection: $viewModel.mealDate, displayedComponents: .date)
                    .labelsHidden()
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("⏰ Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                DatePicker("", selection: $viewModel.mealDate, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Meal Type Section
    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meal Type")
                .font(.headline)
            
            Picker("Meal Type", selection: $viewModel.mealType) {
                ForEach(MealType.allCases, id: \.self) { type in
                    Text("\(type.icon) \(type.displayName)").tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        HStack(spacing: 12) {
            TipCard(icon: "📷", title: "Photo Tips", message: "Take a clear, well-lit photo")
            TipCard(icon: "✍️", title: "Be Specific", message: "Include portion sizes")
            TipCard(icon: "🎯", title: "Consistency", message: "Log all meals for accuracy")
        }
        .liquidGlass(intensity: .thin, cornerRadius: 16)
    }
    
    // MARK: - Preview View
    private var previewView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isAnalyzing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Analyzing your meal...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if let analysis = viewModel.analysis {
                    // Food Items
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Food Items")
                            .font(.headline)
                        
                        ForEach(analysis.items) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .fontWeight(.medium)
                                    Text(item.quantity)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(item.nutrition.calories) kcal")
                                    .foregroundColor(.appPrimary)
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Nutrition Summary
                    HStack(spacing: 12) {
                        NutritionSummaryCard(value: analysis.summary.calories, label: "Calories", color: .caloriesColor)
                        NutritionSummaryCard(value: analysis.summary.protein, label: "Protein", color: .proteinColor, suffix: "g")
                        NutritionSummaryCard(value: analysis.summary.carbs, label: "Carbs", color: .carbsColor, suffix: "g")
                        NutritionSummaryCard(value: analysis.summary.fat, label: "Fat", color: .fatColor, suffix: "g")
                    }
                    
                    // Feedback
                    HStack {
                        Text("💡")
                        Text(analysis.feedback)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Buttons
                    HStack(spacing: 16) {
                        Button {
                            viewModel.goBack()
                        } label: {
                            Text("← Edit")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(.systemGray5))
                                .cornerRadius(12)
                        }
                        
                        Button {
                            Task {
                                await viewModel.saveMeal()
                            }
                        } label: {
                            Text("✓ Confirm & Save")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Saving View
    private var savingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Saving your meal...")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Done View
    private var doneView: some View {
        VStack(spacing: 20) {
            Text("✅")
                .font(.system(size: 60))
            
            Text("Meal Logged!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Text("Your meal has been saved successfully.")
                .foregroundColor(.secondary)
            
            Button {
                viewModel.reset()
            } label: {
                Text("Log Another Meal")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.appPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Tip Card
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
            Text(message)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - Nutrition Summary Card
struct NutritionSummaryCard: View {
    let value: Int
    let label: String
    let color: Color
    var suffix: String = ""
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)\(suffix)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
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
