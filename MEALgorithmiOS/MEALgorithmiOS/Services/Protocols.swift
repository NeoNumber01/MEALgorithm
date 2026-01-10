import Foundation
import Supabase
import SwiftUI

// MARK: - OAuth Provider
/// Supported OAuth providers for third-party login
enum OAuthProvider: String, CaseIterable {
    case google
    case github
    
    var displayName: String {
        switch self {
        case .google: return "Google"
        case .github: return "GitHub"
        }
    }
    
    var supabaseProvider: Provider {
        switch self {
        case .google: return .google
        case .github: return .github
        }
    }
}

// MARK: - Auth Service Protocol
protocol AuthServiceProtocol: Actor {
    func signIn(email: String, password: String) async throws -> Session
    func signUp(email: String, password: String) async throws -> Session
    func signInWithApple(idToken: String, nonce: String) async throws -> Session
    func signInWithOAuth(provider: OAuthProvider) async throws -> URL
    func handleOAuthCallback(url: URL) async throws -> Session
    func signOut() async throws
    func getSession() async throws -> Session?
    func isAuthenticated() async -> Bool
    func getCurrentUser() async -> User?
    func reauthenticate(email: String, password: String) async throws
    func deleteAccount() async throws
}

// MARK: - Meal Service Protocol
protocol MealServiceProtocol: Actor {
    func saveMeal(textContent: String?, imagePath: String?, analysis: MealAnalysis, mealType: MealType?, createdAt: Date) async throws
    func getDailyMeals(start: Date, end: Date) async throws -> [Meal]
    func getTodayMeals() async throws -> [Meal]
    func getWeeklyMeals() async throws -> [Meal]
    func deleteMeal(id: UUID) async throws
    func uploadMealImage(_ imageData: Data, fileExtension: String) async throws -> String
    func getImageURL(path: String) -> URL?
}

// MARK: - Profile Service Protocol
protocol ProfileServiceProtocol: Actor {
    func getProfile() async throws -> Profile
    func updateProfile(_ update: ProfileUpdate) async throws
    func updateCachedFeedback(_ feedback: String) async throws
}

// MARK: - Gemini Service Protocol
/// Abstracting the AI service for easier mocking
protocol GeminiServiceProtocol: Sendable {
    func analyzeMeal(text: String?, image: UIImage?) async throws -> MealAnalysis
    func generateFeedback(todayCalories: Int, weeklyAvgCalories: Int, targetCalories: Int, goal: String?) async throws -> String

    func generateStatisticsInsight(periodLabel: String, totalDays: Int, daysWithMeals: Int, totalMeals: Int, avgCalories: Int, avgProtein: Int, avgCarbs: Int, avgFat: Int, targetCalories: Int, goalDescription: String?) async throws -> String
    
    func generateRecommendations(targetCalories: Int, recentAvgCalories: Int, goal: String?, preferences: [String]?) async throws -> [Recommendation]
    
    func generateDayPlan(targetCalories: Int, consumedCalories: Int, eatenMealTypes: [String], goal: String?, preferences: [String]?) async throws -> (meals: [DayPlanMeal], summary: DayPlanSummary)
}

// MARK: - Network Monitor Protocol
protocol NetworkMonitorProtocol: ObservableObject {
    var isConnected: Bool { get }
}
