import SwiftUI
import PhotosUI
import SwiftData

// MARK: - Meal Log View Model
/// Manages meal logging flow: input → AI analysis → save
@MainActor
final class MealLogViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var step: Step = .input
    @Published var inputMode: InputMode = .text
    @Published var textInput: String = ""
    @Published var selectedImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var mealType: MealType = .lunch
    @Published var mealDate: Date = Date()
    @Published var analysis: MealAnalysis?
    @Published var isAnalyzing = false
    @Published var isSaving = false
    @Published var error: String?
    
    enum Step {
        case input
        case preview
        case saving
        case done
    }
    
    enum InputMode {
        case text
        case image
    }
    
    // MARK: - Services
    private let geminiService: GeminiServiceProtocol
    private var mealRepository: MealRepository?
    
    init(geminiService: GeminiServiceProtocol = GeminiService()) {
        self.geminiService = geminiService
    }
    
    /// Configure with ModelContext (called from View)
    func configure(modelContext: ModelContext, mealService: MealServiceProtocol = MealService()) {
        self.mealRepository = MealRepository(context: modelContext, mealService: mealService)
    }
    
    // MARK: - Analyze Meal
    /// Send input to Gemini for analysis
    func analyzeMeal() async {
        guard inputMode == .text ? !textInput.isEmpty : selectedImage != nil else {
            error = "Please provide a description or image"
            return
        }
        
        isAnalyzing = true
        error = nil
        step = .preview
        
        do {
            let result = try await geminiService.analyzeMeal(
                text: inputMode == .text ? textInput : nil,
                image: inputMode == .image ? selectedImage : nil
            )
            self.analysis = result
        } catch {
            self.error = AppError.from(error).localizedDescription
            step = .input
        }
        
        isAnalyzing = false
    }
    
    // MARK: - Save Meal
    /// Save the analyzed meal to Supabase
    func saveMeal() async {
        guard let analysis = analysis else { return }
        
        isSaving = true
        step = .saving
        error = nil
        
        do {
            // Save meal
            if let repository = mealRepository {
                try await repository.saveMeal(
                    textContent: inputMode == .text ? textInput : nil,
                    image: selectedImage,
                    analysis: analysis,
                    mealType: mealType,
                    createdAt: mealDate
                )
            } else {
               throw AppError.unknown("Repository not configured")
            }
            
            // 通知其他视图数据已更新
            NotificationCenter.default.post(name: .mealDidSave, object: nil)
            
            step = .done
        } catch {
            self.error = AppError.from(error).localizedDescription
            step = .preview
        }
        
        isSaving = false
    }
    
    // MARK: - Reset
    /// Reset for new meal entry
    func reset() {
        step = .input
        textInput = ""
        selectedImage = nil
        selectedPhotoItem = nil
        mealType = .lunch
        mealDate = Date()
        analysis = nil
        error = nil
    }
    
    // MARK: - Go Back
    func goBack() {
        step = .input
    }
    
    // MARK: - Handle Photo Selection
    func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
            }
        } catch {
            self.error = "Failed to load image"
        }
    }
}
