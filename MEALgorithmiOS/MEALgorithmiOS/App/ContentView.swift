import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()
            } else if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .task {
            await authViewModel.checkSession()
        }
    }
}

struct MainTabView: View {
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
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(Tab.dashboard)
                
                MealLogView()
                    .tag(Tab.logMeal)
                
                RecommendationsView()
                    .tag(Tab.recommendations)
                
                SettingsView()
                    .tag(Tab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
