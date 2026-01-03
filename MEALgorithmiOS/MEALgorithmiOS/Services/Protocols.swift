import Foundation
import Supabase
import SwiftUI

// MARK: - Auth Service Protocol
protocol AuthServiceProtocol: Actor {
    func signIn(email: String, password: String) async throws -> Session
    func signUp(email: String, password: String) async throws -> Session
    func signInWithApple(idToken: String, nonce: String) async throws -> Session
    func signOut() async throws
    func getSession() async throws -> Session?
    func isAuthenticated() async -> Bool
    func getCurrentUser() async -> User?
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

// MARK: - Gemini Service Protocol
/// Abstracting the AI service for easier mocking
protocol GeminiServiceProtocol: Sendable {
    func analyzeMeal(text: String?, image: UIImage?) async throws -> MealAnalysis
}
