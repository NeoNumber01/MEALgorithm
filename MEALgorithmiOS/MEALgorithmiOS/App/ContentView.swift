import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if authViewModel.isLoading {
                    LoadingView()
                        .onAppear { print("🔄 ContentView: Showing LoadingView") }
                } else if authViewModel.isAuthenticated {
                    MainTabView()
                        .onAppear { print("✅ ContentView: Showing MainTabView (authenticated)") }
                } else {
                    LoginView()
                        .onAppear { print("🔑 ContentView: Showing LoginView (not authenticated)") }
                }
            }
            
            // Offline Banner
            if !networkMonitor.isConnected {
                OfflineBanner()
                    .edgesIgnoringSafeArea(.top)
                    .zIndex(100) // Ensure it's on top
                    .animation(.easeInOut, value: networkMonitor.isConnected)
            }
        }
        .task {
            print("🚀 ContentView: Starting checkSession")
            await authViewModel.checkSession()
            print("✅ ContentView: checkSession completed, isLoading=\(authViewModel.isLoading), isAuthenticated=\(authViewModel.isAuthenticated)")
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: Tab = .dashboard
    
    enum Tab: Int, CaseIterable {
        case dashboard
        case logMeal
        case recommendations
        case settings
        
        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .logMeal: return "Log Meal"
            case .recommendations: return "Ideas"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .logMeal: return "camera.fill"
            case .recommendations: return "lightbulb.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content based on selected tab
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .logMeal:
                    MealLogView()
                case .recommendations:
                    RecommendationsView()
                case .settings:
                    SettingsView()
                        .environmentObject(authViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
