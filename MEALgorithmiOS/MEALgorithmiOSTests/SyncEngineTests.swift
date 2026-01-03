import XCTest
import Combine
import SwiftData
@testable import MEALgorithmiOS

@MainActor
final class SyncEngineTests: XCTestCase {
    var syncEngine: SyncEngine!
    var mockMealService: MockMealService!
    var networkSubject: PassthroughSubject<Bool, Never>!
    var container: ModelContainer!
    
    override func setUpWithError() throws {
        // Setup In-Memory SwiftData
        let schema = Schema([SDMeal.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        
        // Setup Mocks
        mockMealService = MockMealService()
        networkSubject = PassthroughSubject<Bool, Never>()
        
        // Setup SyncEngine with dependency injection
        syncEngine = SyncEngine(
            mealService: mockMealService,
            isConnected: { true }, // Default connected
            networkPublisher: networkSubject.eraseToAnyPublisher()
        )
        syncEngine.configure(with: container)
    }
    
    override func tearDown() {
        syncEngine = nil
        mockMealService = nil
        networkSubject = nil
        container = nil
    }
    
    func testSyncTriggersOnPendingItems() async throws {
        // Given
        // Given
        let meal = SDMeal(userId: UUID(), createdAt: Date())
        meal.syncStatus = .pending
        container.mainContext.insert(meal)
        
        // When
        await syncEngine.syncPendingItems()
        
        // Then
        let saved = await mockMealService.wasSaveCalled
        XCTAssertTrue(saved)
        XCTAssertEqual(meal.syncStatus, .synced)
    }
    
    // Note: Testing Combine sinks in XCTest usually requires expectations
    // or MainActor isolation handling.
}
