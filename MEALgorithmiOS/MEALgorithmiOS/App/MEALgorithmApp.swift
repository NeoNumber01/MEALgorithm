import SwiftUI
import SwiftData

@main
struct MEALgorithmApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    // SwiftData container
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: SDMeal.self)
            // Configure sync engine
            SyncEngine.shared.configure(with: container)
            
            // Setup user sign out observer to clear local data
            setupSignOutObserver()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(networkMonitor)
                .preferredColorScheme(.dark) // Force Nebula Theme (Dark Mode)
                .modelContainer(container)
                .onOpenURL { url in
                    // Handle OAuth callback URL
                    Task {
                        await authViewModel.handleOAuthCallback(url: url)
                    }
                }
        }
    }
    
    // MARK: - Sign Out Data Cleanup
    
    /// Setup observer to clear local SwiftData when user signs out
    /// This ensures data isolation between different users
    private func setupSignOutObserver() {
        NotificationCenter.default.addObserver(
            forName: .userWillSignOut,
            object: nil,
            queue: .main
        ) { [self] _ in
            Task { @MainActor in
                do {
                    let context = container.mainContext
                    let repository = MealRepository(context: context)
                    try repository.deleteAllLocalMeals()
                    print("✅ MEALgorithmApp: Local data cleared on sign out")
                } catch {
                    print("❌ MEALgorithmApp: Failed to clear local data: \(error)")
                }
            }
        }
    }
}

