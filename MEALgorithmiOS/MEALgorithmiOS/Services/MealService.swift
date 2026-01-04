import Foundation
import Supabase

// MARK: - Meal Service
/// Handles meal CRUD operations with Supabase
actor MealService: MealServiceProtocol {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    // MARK: - Save Meal
    /// Save a new meal with analysis
    func saveMeal(
        textContent: String?,
        imagePath: String?,
        analysis: MealAnalysis,
        mealType: MealType?,
        createdAt: Date = Date()
    ) async throws {
        let session = try await client.auth.session
        let userId = session.user.id
        
        let meal = MealCreate(
            userId: userId,
            textContent: textContent,
            imagePath: imagePath,
            analysis: analysis,
            mealType: mealType?.rawValue,
            createdAt: createdAt
        )
        
        try await client
            .from("meals")
            .insert(meal)
            .execute()
        
        // Update last_meal_at to invalidate cached feedback
        struct LastMealUpdate: Codable {
            var lastMealAt: Date
            enum CodingKeys: String, CodingKey {
                case lastMealAt = "last_meal_at"
            }
        }
        
        try await client
            .from("profiles")
            .update(LastMealUpdate(lastMealAt: Date()))
            .eq("id", value: userId)
            .execute()
        
        // Invalidate local cache
        CacheService.shared.notifyDataUpdated()
    }
    
    // MARK: - Get Daily Meals
    /// Fetch meals for a specific date range
    func getDailyMeals(start: Date, end: Date) async throws -> [Meal] {
        let session = try await client.auth.session
        let userId = session.user.id
        
        let meals: [Meal] = try await client
            .from("meals")
            .select()
            .eq("user_id", value: userId)
            .gte("created_at", value: start.ISO8601Format())
            .lte("created_at", value: end.ISO8601Format())
            .order("created_at", ascending: true)
            .execute()
            .value
        
        return meals
    }
    
    // MARK: - Get Today's Meals
    /// Convenience method to get today's meals
    func getTodayMeals() async throws -> [Meal] {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await getDailyMeals(start: startOfDay, end: endOfDay)
    }
    
    // MARK: - Get Weekly Stats
    /// Get meals for the past 7 days
    func getWeeklyMeals() async throws -> [Meal] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.date(byAdding: .day, value: -6, to: startOfToday)!
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        return try await getDailyMeals(start: startOfWeek, end: endOfDay)
    }
    
    // MARK: - Delete Meal
    /// Delete a meal by ID
    func deleteMeal(id: UUID) async throws {
        let session = try await client.auth.session
        let userId = session.user.id
        
        try await client
            .from("meals")
            .delete()
            .eq("id", value: id)
            .eq("user_id", value: userId)
            .execute()
        
        // Invalidate local cache
        CacheService.shared.notifyDataUpdated()
    }
    
    // MARK: - Upload Image
    /// Upload meal image to Supabase storage
    func uploadMealImage(_ imageData: Data, fileExtension: String) async throws -> String {
        let session = try await client.auth.session
        let userId = session.user.id
        
        let fileName = "\(userId.uuidString)/\(Int(Date().timeIntervalSince1970)).\(fileExtension)"
        
        try await client.storage
            .from("meal_images")
            .upload(fileName, data: imageData, options: FileOptions(contentType: "image/jpeg"))
        
        return fileName
    }
    
    // MARK: - Get Image URL
    /// Get public URL for meal image
    func getImageURL(path: String) -> URL? {
        try? client.storage
            .from("meal_images")
            .getPublicURL(path: path)
    }
}

// MARK: - Meal Service Errors
enum MealServiceError: LocalizedError {
    case notAuthenticated
    case uploadFailed(String)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in"
        case .uploadFailed(let message):
            return "Failed to upload image: \(message)"
        case .saveFailed(let message):
            return "Failed to save meal: \(message)"
        }
    }
}
