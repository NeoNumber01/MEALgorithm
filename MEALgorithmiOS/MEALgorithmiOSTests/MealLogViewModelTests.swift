import XCTest
import SwiftData
@testable import MEALgorithmiOS

@MainActor
final class MealLogViewModelTests: XCTestCase {
    var viewModel: MealLogViewModel!
    var mockGemini: MockGeminiService!
    var mockMealService: MockMealService!
    var container: ModelContainer!
    
    override func setUpWithError() throws {
        // Setup In-Memory SwiftData Container
        let schema = Schema([SDMeal.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        
        // Setup Mocks
        mockGemini = MockGeminiService()
        mockMealService = MockMealService()
        
        // Setup ViewModel
        viewModel = MealLogViewModel(geminiService: mockGemini)
        viewModel.configure(modelContext: container.mainContext, mealService: mockMealService)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockGemini = nil
        mockMealService = nil
        container = nil
    }
    
    func testAnalyzeMealSuccess() async throws {
        // Given
        viewModel.inputMode = .text
        viewModel.textInput = "Chicken Salad"
        
        let expectedAnalysis = MealAnalysis(
            items: [MealItem(name: "Chicken Salad", quantity: "1 bowl", nutrition: NutritionInfo(calories: 300, protein: 20, carbs: 10, fat: 15))],
            summary: NutritionInfo(calories: 300, protein: 20, carbs: 10, fat: 15),
            feedback: "Healthy!"
        )
        
        await mockGemini.setResponse(expectedAnalysis)
        
        // When
        await viewModel.analyzeMeal()
        
        // Then
        XCTAssertEqual(viewModel.step, .preview)
        XCTAssertEqual(viewModel.analysis, expectedAnalysis)
        XCTAssertNil(viewModel.error)
    }
    
    func testSaveMealSuccess() async throws {
        // Given
        let analysis = MealAnalysis(items: [], summary: .zero, feedback: "")
        viewModel.analysis = analysis
        viewModel.mealType = .lunch
        
        // When
        await viewModel.saveMeal()
        
        // Then
        XCTAssertEqual(viewModel.step, .done)
        
        // Verify Repository/Service Call
        let saved = await mockMealService.wasSaveCalled
        XCTAssertFalse(saved, "Service should NOT be called directly by Repository immediately inside saveMeal? Wait.")
        
        // Correction: Repository calls saveMeal -> Local DB -> syncEngine.
        // SyncEngine runs in background. 
        // SyncEngine calls mealService.
        // We need to verify LOCAL DB first.
        
        let descriptor = FetchDescriptor<SDMeal>()
        let meals = try container.mainContext.fetch(descriptor)
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.syncStatus, .pending)
    }
}
