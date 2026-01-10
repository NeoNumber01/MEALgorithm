import Foundation
import Supabase
import AuthenticationServices

// MARK: - Authentication Service
/// Handles all authentication operations with Supabase
actor AuthService: AuthServiceProtocol {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    // MARK: - Sign In
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> Session {
        try await client.auth.signIn(email: email, password: password)
    }
    
    // MARK: - Sign Up
    /// Create a new account with email and password
    func signUp(email: String, password: String) async throws -> Session {
        let response = try await client.auth.signUp(email: email, password: password)
        guard let session = response.session else {
            throw AuthError.noSession
        }
        return session
    }
    
    // MARK: - Sign in with Apple
    /// Sign in using Apple ID
    func signInWithApple(idToken: String, nonce: String) async throws -> Session {
        try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }
    
    // MARK: - Sign in with OAuth (Google/GitHub)
    /// Get OAuth sign-in URL for the specified provider
    /// The URL should be opened in ASWebAuthenticationSession
    func signInWithOAuth(provider: OAuthProvider) async throws -> URL {
        // Create the OAuth URL with the app's custom URL scheme for callback
        let redirectURL = URL(string: "mealgorithm://auth/callback")!
        
        let url = try client.auth.getOAuthSignInURL(
            provider: provider.supabaseProvider,
            redirectTo: redirectURL
        )
        return url
    }
    
    /// Handle OAuth callback URL and exchange code for session
    func handleOAuthCallback(url: URL) async throws -> Session {
        try await client.auth.session(from: url)
    }
    
    // MARK: - Sign Out
    /// Sign out the current user
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // MARK: - Reauthenticate
    /// Reauthenticate user with password before sensitive operations
    func reauthenticate(email: String, password: String) async throws {
        // Attempt to sign in with credentials - if successful, user is reauthenticated
        _ = try await client.auth.signIn(email: email, password: password)
    }
    
    // MARK: - Delete Account
    /// Permanently delete user account via Edge Function
    func deleteAccount() async throws {
        // Get current session for authorization
        let session = try await client.auth.session
        
        // Response structure from Edge Function
        struct DeleteResponse: Decodable {
            var success: Bool?
            var error: String?
        }
        
        // Call the delete-account Edge Function with typed response
        let response: DeleteResponse = try await client.functions.invoke(
            "delete-account",
            options: FunctionInvokeOptions(
                headers: ["Authorization": "Bearer \(session.accessToken)"]
            )
        )
        
        // Check for errors in response
        if let errorMessage = response.error {
            throw AuthError.deleteFailed(errorMessage)
        }
        
        // Sign out locally after successful deletion
        try? await client.auth.signOut()
    }
    
    // MARK: - Session
    /// Get the current session
    func getSession() async throws -> Session? {
        try await client.auth.session
    }
    
    /// Check if user is authenticated
    func isAuthenticated() async -> Bool {
        do {
            _ = try await client.auth.session
            return true
        } catch {
            return false
        }
    }
    
    /// Get current user
    func getCurrentUser() async -> User? {
        try? await client.auth.session.user
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case noSession
    case invalidCredentials
    case userNotFound
    case deleteFailed(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .noSession:
            return "No active session found"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .deleteFailed(let message):
            return "Failed to delete account: \(message)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
