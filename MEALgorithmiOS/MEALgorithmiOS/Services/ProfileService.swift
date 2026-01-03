import Foundation
import Supabase

// MARK: - Profile Service
/// Handles profile CRUD operations with Supabase
actor ProfileService {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    // MARK: - Get Profile
    /// Fetch current user's profile
    func getProfile() async throws -> Profile {
        let session = try await client.auth.session
        let userId = session.user.id
        
        let response: Profile = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Update Profile
    /// Update user profile with new values
    func updateProfile(_ update: ProfileUpdate) async throws {
        let session = try await client.auth.session
        let userId = session.user.id
        
        try await client
            .from("profiles")
            .update(update)
            .eq("id", value: userId)
            .execute()
    }
    
    // MARK: - Update Cached Feedback
    /// Update the cached AI feedback
    func updateCachedFeedback(_ feedback: String) async throws {
        let session = try await client.auth.session
        let userId = session.user.id
        
        struct FeedbackUpdate: Codable {
            var cachedFeedback: String
            var feedbackUpdatedAt: Date
            
            enum CodingKeys: String, CodingKey {
                case cachedFeedback = "cached_feedback"
                case feedbackUpdatedAt = "feedback_updated_at"
            }
        }
        
        try await client
            .from("profiles")
            .update(FeedbackUpdate(
                cachedFeedback: feedback,
                feedbackUpdatedAt: Date()
            ))
            .eq("id", value: userId)
            .execute()
    }
    
    // MARK: - Update Preferences
    /// Update food preferences for AI suggestions
    func updatePreferences(
        foodPreferences: String,
        foodDislikes: String,
        dietaryRestrictions: String,
        customNotes: String
    ) async throws {
        guard let userId = await SupabaseManager.shared.currentUserId else {
            throw ProfileError.notAuthenticated
        }
        
        struct PreferencesUpdate: Codable {
            var foodPreferences: String?
            var foodDislikes: String?
            var dietaryRestrictions: String?
            var customNotes: String?
            
            enum CodingKeys: String, CodingKey {
                case foodPreferences = "food_preferences"
                case foodDislikes = "food_dislikes"
                case dietaryRestrictions = "dietary_restrictions"
                case customNotes = "custom_notes"
            }
        }
        
        try await client
            .from("profiles")
            .update(PreferencesUpdate(
                foodPreferences: foodPreferences.isEmpty ? nil : foodPreferences,
                foodDislikes: foodDislikes.isEmpty ? nil : foodDislikes,
                dietaryRestrictions: dietaryRestrictions.isEmpty ? nil : dietaryRestrictions,
                customNotes: customNotes.isEmpty ? nil : customNotes
            ))
            .eq("id", value: userId)
            .execute()
    }
}

// MARK: - Profile Errors
enum ProfileError: LocalizedError {
    case notAuthenticated
    case notFound
    case updateFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in"
        case .notFound:
            return "Profile not found"
        case .updateFailed(let message):
            return "Failed to update profile: \(message)"
        }
    }
}
