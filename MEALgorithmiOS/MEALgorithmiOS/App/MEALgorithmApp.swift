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
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(networkMonitor)
                .modelContainer(container)
        }
    }
}
