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
        guard let userId = try await client.auth.session.user.id else {
            throw ProfileError.notAuthenticated
        }
        
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
        guard let userId = try await client.auth.session.user.id else {
            throw ProfileError.notAuthenticated
        }
        
        try await client
            .from("profiles")
            .update(update)
            .eq("id", value: userId)
            .execute()
    }
    
    // MARK: - Update Cached Feedback
    /// Update the cached AI feedback
    func updateCachedFeedback(_ feedback: String) async throws {
        guard let userId = try await client.auth.session.user.id else {
            throw ProfileError.notAuthenticated
        }
        
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
