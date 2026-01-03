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
    
    // MARK: - Sign Out
    /// Sign out the current user
    func signOut() async throws {
        try await client.auth.signOut()
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
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .noSession:
            return "No active session found"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
