import Foundation
import UIKit
import Supabase
@testable import MEALgorithmiOS

// MARK: - Mock Gemini Service
actor MockGeminiService: GeminiServiceProtocol {
    private var resultToReturn: MealAnalysis?
    private var feedbackToReturn: String = "Keep it up!"
    private var insightToReturn: String = "Great balance."
    private var errorToThrow: Error?
    
    func setResponse(_ response: MealAnalysis) { self.resultToReturn = response }
    func setFeedback(_ feedback: String) { self.feedbackToReturn = feedback }
    func setError(_ error: Error) { self.errorToThrow = error }
    
    func analyzeMeal(text: String?, image: UIImage?) async throws -> MealAnalysis {
        if let error = errorToThrow { throw error }
        if let result = resultToReturn { return result }
        throw GeminiError.emptyResponse
    }
    
    func generateFeedback(todayCalories: Int, weeklyAvgCalories: Int, targetCalories: Int, goal: String?) async throws -> String {
        if let error = errorToThrow { throw error }
        return feedbackToReturn
    }
    
    func generateStatisticsInsight(periodLabel: String, totalDays: Int, daysWithMeals: Int, totalMeals: Int, avgCalories: Int, avgProtein: Int, avgCarbs: Int, avgFat: Int, targetCalories: Int, goalDescription: String?) async throws -> String {
        if let error = errorToThrow { throw error }
        return insightToReturn
    }
    
    private(set) var generateRecommendationsCallCount = 0

    func generateRecommendations(targetCalories: Int, recentAvgCalories: Int, goal: String?, preferences: [String]?) async throws -> [Recommendation] {
        generateRecommendationsCallCount += 1
        if let error = errorToThrow { throw error }
        return [
            Recommendation(name: "Mock Meal 1", description: "Desc 1", reason: "Reason 1", nutrition: .zero),
            Recommendation(name: "Mock Meal 2", description: "Desc 2", reason: "Reason 2", nutrition: .zero),
            Recommendation(name: "Mock Meal 3", description: "Desc 3", reason: "Reason 3", nutrition: .zero)
        ]
    }
    
    private(set) var generateDayPlanCallCount = 0
    
    func generateDayPlan(targetCalories: Int, consumedCalories: Int, eatenMealTypes: [String], goal: String?, preferences: [String]?) async throws -> (meals: [DayPlanMeal], summary: DayPlanSummary) {
        generateDayPlanCallCount += 1
        if let error = errorToThrow { throw error }
        return (
            [DayPlanMeal(mealType: "dinner", name: "Mock Dinner", description: "Desc", nutrition: .zero)],
            DayPlanSummary(totalPlannedCalories: 500, advice: "Good luck")
        )
    }
}

// MARK: - Mock Meal Service
actor MockMealService: MealServiceProtocol {
    var wasSaveCalled = false
    var mealsToReturn: [Meal] = []
    
    func setMeals(_ meals: [Meal]) { self.mealsToReturn = meals }
    
    // Properties for testing access (matching test expectations)
    var mockWeeklyMeals: [Meal] {
        get { mealsToReturn }
        set { mealsToReturn = newValue }
    }
    
    
    func saveMeal(textContent: String?, imagePath: String?, analysis: MealAnalysis, mealType: MealType?, createdAt: Date) async throws {
        wasSaveCalled = true
    }
    
    func getDailyMeals(start: Date, end: Date) async throws -> [Meal] { mealsToReturn }
    func getTodayMeals() async throws -> [Meal] { mealsToReturn }
    func getWeeklyMeals() async throws -> [Meal] { mealsToReturn }
    func deleteMeal(id: UUID) async throws {}
    func uploadMealImage(_ imageData: Data, fileExtension: String) async throws -> String { "mock/path.jpg" }
    func getImageURL(path: String) -> URL? { URL(string: "https://mock.url/\(path)") }
}

// MARK: - Mock Profile Service
actor MockProfileService: ProfileServiceProtocol {
    var profileToReturn: Profile?
    
    func setProfile(_ profile: Profile) { self.profileToReturn = profile }
    
    func updateProfile(_ update: ProfileUpdate) async throws {}
    func updateCachedFeedback(_ feedback: String) async throws {}
    
    // Properties for testing access
    var shouldFail: Bool = false
    func setShouldFail(_ value: Bool) { self.shouldFail = value }
    
    var mockProfile: Profile? {
        get { profileToReturn }
        set { profileToReturn = newValue }
    }
    
    func getProfile() async throws -> Profile {
        if shouldFail { throw ProfileError.notFound }
        guard let profile = profileToReturn else {
            throw ProfileError.notFound
        }
        return profile
    }
}

// MARK: - Mock Auth Service
actor MockAuthService: AuthServiceProtocol {
    var sessionToReturn: Session?
    var userToReturn: User?
    var errorToThrow: Error?
    var reauthenticateCalled = false
    var deleteAccountCalled = false
    
    func setSession(_ session: Session) { self.sessionToReturn = session }
    func setUser(_ user: User) { self.userToReturn = user }
    func setError(_ error: Error) { self.errorToThrow = error }
    
    func signIn(email: String, password: String) async throws -> Session {
        if let error = errorToThrow { throw error }
        guard let session = sessionToReturn else { throw AuthError.sessionNotFound }
        return session
    }
    
    func signUp(email: String, password: String) async throws -> Session {
        if let error = errorToThrow { throw error }
        guard let session = sessionToReturn else { throw AuthError.sessionNotFound }
        return session
    }
    
    func signInWithApple(idToken: String, nonce: String) async throws -> Session {
        if let error = errorToThrow { throw error }
        guard let session = sessionToReturn else { throw AuthError.sessionNotFound }
        return session
    }
    
    func signInWithOAuth(provider: OAuthProvider) async throws -> URL {
        if let error = errorToThrow { throw error }
        return URL(string: "https://mock.supabase.co/auth/v1/authorize?provider=\(provider.rawValue)")!
    }
    
    func handleOAuthCallback(url: URL) async throws -> Session {
        if let error = errorToThrow { throw error }
        guard let session = sessionToReturn else { throw AuthError.sessionNotFound }
        return session
    }
    
    func signOut() async throws {}
    
    func getSession() async throws -> Session? { sessionToReturn }
    
    func isAuthenticated() async -> Bool { sessionToReturn != nil }
    
    func getCurrentUser() async -> User? { userToReturn }
    
    func reauthenticate(email: String, password: String) async throws {
        reauthenticateCalled = true
        if let error = errorToThrow { throw error }
    }
    
    func deleteAccount() async throws {
        deleteAccountCalled = true
        if let error = errorToThrow { throw error }
    }
}
