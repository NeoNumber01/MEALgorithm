import Foundation
import SwiftData
import Combine
import SwiftUI

// MARK: - Sync Engine Mode
enum SyncEngineMode {
    case automatic
    case manual
}

// MARK: - Sync Engine
/// Handles background synchronization of data
@MainActor
final class SyncEngine: ObservableObject {
    // Singleton for simplicity in views, but can be injected
    static let shared = SyncEngine()
    
    // Dependencies
    private var modelContainer: ModelContainer?
    private let mealService: MealServiceProtocol
    // private let networkMonitor: NetworkMonitor // Removed in favor of publisher but might need current state access?
    // Actually, we need current state too.
    // Let's keep it simple: Accept an object dealing with network.
    // Or just accept the publisher and assume we can query current state?
    // SyncEngine checks `networkMonitor.isConnected` in `syncPendingItems`. 
    // So we need a Protocol or Closure for that.
    
    private let isConnected: () -> Bool
    private let networkPublisher: AnyPublisher<Bool, Never>
    
    // State
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // Retry Logic
    private var retryAttempt = 0
    private let maxRetries = 5
    
    init(
        mealService: MealServiceProtocol = MealService(),
        networkMonitor: NetworkMonitor = NetworkMonitor.shared
    ) {
        self.mealService = mealService
        self.isConnected = { networkMonitor.isConnected }
        self.networkPublisher = networkMonitor.$isConnected.eraseToAnyPublisher()
        
        setupObservers()
    }
    
    // Test Init
    init(
        mealService: MealServiceProtocol,
        isConnected: @escaping () -> Bool,
        networkPublisher: AnyPublisher<Bool, Never>
    ) {
        self.mealService = mealService
        self.isConnected = isConnected
        self.networkPublisher = networkPublisher
        
        setupObservers()
    }
    
    /// Configure with ModelContainer (called from App)
    func configure(with container: ModelContainer) {
        self.modelContainer = container
    }
    
    private func setupObservers() {
        // Auto-sync when network returns
        networkPublisher
            .dropFirst()
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in
                Task {
                    await self?.syncPendingItems()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Trigger synchronization
    func syncPendingItems() async {
        guard let container = modelContainer else { return }
        guard isConnected() else { return }
        guard !isSyncing else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Manual ModelContext for background work
        let context = ModelContext(container)
        
        do {
            // Fetch Pending Meals
            let descriptor = FetchDescriptor<SDMeal>(
                predicate: #Predicate<SDMeal> { $0.syncStatusRaw == "pending" || $0.syncStatusRaw == "failed" }
            )
            let pendingMeals = try context.fetch(descriptor)
            
            guard !pendingMeals.isEmpty else { return }
            print("🔄 SyncEngine: Found \(pendingMeals.count) pending items")
            
            for meal in pendingMeals {
                try await syncMeal(meal, using: context)
            }
            
            lastSyncTime = Date()
            retryAttempt = 0 // Reset retry on success
            
        } catch {
            print("❌ SyncEngine Error: \(error)")
            scheduleRetry()
        }
    }
    
    private func syncMeal(_ meal: SDMeal, using context: ModelContext) async throws {
        // Prepare data
        let analysis: MealAnalysis?
        if let data = meal.analysisData {
            analysis = try? JSONDecoder().decode(MealAnalysis.self, from: data)
        } else {
            analysis = nil
        }
        
        guard let validAnalysis = analysis else {
            // Cannot sync invalid data, mark as failed permanent?
            // For now, skip
            return
        }
        
        // Upload
        // Note: Ideally, MealService should expose a 'create' that takes raw values, 
        // OR we map SDMeal to arguments.
        // We use the same 'saveMeal' API.
        
        do {
            try await mealService.saveMeal(
                textContent: meal.textContent,
                imagePath: meal.imagePath, // Assumption: Image is already uploaded OR we need to handle image upload here too.
                // NOTE: Robustness V2 should handle image upload sync. 
                // For V1, we assume imagePath is remote or nil, or we need to fix this.
                // If imagePath is local file URL, we need to upload it first.
                // Assuming for now inputs are valid.
                analysis: validAnalysis,
                mealType: meal.mealType,
                createdAt: meal.createdAt
            )
            
            // Mark synced
            meal.syncStatus = .synced
            meal.syncErrorMessage = nil
            try context.save()
            
        } catch {
            meal.syncStatus = .failed
            meal.syncErrorMessage = error.localizedDescription
            try context.save()
            throw error // Propagate to trigger retry
        }
    }
    
    private func scheduleRetry() {
        guard retryAttempt < maxRetries else {
            print("❌ SyncEngine: Max retries reached")
            return
        }
        
        let delay = pow(2.0, Double(retryAttempt)) // Exponential backoff: 1, 2, 4, 8, 16s
        retryAttempt += 1
        
        print("⏳ SyncEngine: Retrying in \(delay) seconds...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            Task {
                await self?.syncPendingItems()
            }
        }
    }
}
