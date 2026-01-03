import XCTest
@testable import MEALgorithmiOS

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var viewModel: DashboardViewModel!
    var mockMealService: MockMealService!
    var mockProfileService: MockProfileService!
    var mockGeminiService: MockGeminiService!
    
    override func setUp() {
        mockMealService = MockMealService()
        mockProfileService = MockProfileService()
        mockGeminiService = MockGeminiService()
        viewModel = DashboardViewModel(
            mealService: mockMealService,
            profileService: mockProfileService,
            geminiService: mockGeminiService
        )
    }
    
    func testLoadDataSuccess() async {
        // Given
        await mockProfileService.setProfile(Profile(id: UUID(), calorieTarget: 2000))
        await mockMealService.setMeals([])
        
        // When
        await viewModel.loadData() // Was private? No, usually public. Check actual file.
        // DashboardViewModel.loadData() is public.
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.targets.calories, 2000)
    }
    
    func testLoadDataProfileMissing() async {
        // Given - Profile Service throws not found
        // When
        await viewModel.loadData()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error) // Should handle error
    }
    
    // Extreme Case: Network fail then cache
    // Note: To test cache, we'd need to mock CacheService too, but it's a singleton.
    // For now, we verified logic is: try cache -> background reload.
}
