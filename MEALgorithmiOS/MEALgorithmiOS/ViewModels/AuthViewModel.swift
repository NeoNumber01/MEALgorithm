import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

// MARK: - Auth View Model
/// Manages authentication state and operations
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var error: String?
    @Published var currentUserEmail: String?
    @Published var oauthURL: URL?  // Triggers ASWebAuthenticationSession for OAuth
    
    // For Sign in with Apple
    var currentNonce: String?
    
    // MARK: - Services
    // MARK: - Services
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }
    
    // MARK: - Session Check
    /// Check for existing session on app launch
    func checkSession() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Add timeout for session check
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    if let session = try await self.authService.getSession() {
                        await MainActor.run {
                            self.isAuthenticated = true
                            self.currentUserEmail = session.user.email
                        }
                    } else {
                        await MainActor.run {
                            self.isAuthenticated = false
                        }
                    }
                }
                
                group.addTask {
                    try await Task.sleep(nanoseconds: 10 * 1_000_000_000) // 10s timeout for initial check
                    throw AppError.unknown("Session check timed out")
                }
                
                try await group.next()
                group.cancelAll()
            }
        } catch {
            print("⚠️ AuthViewModel: Session check failed - \(error)")
            isAuthenticated = false
        }
    }
    
    // MARK: - Sign In
    /// Sign in with email and password
    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Please enter email and password"
            return
        }
        
        isLoading = true
        error = nil
        
        // Ensure loading is reset no matter what
        defer { isLoading = false }
        
        do {
            print("🔑 AuthViewModel: Attempting sign in for \(email)")
            
            // Add timeout for sign in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    let session = try await self.authService.signIn(email: email, password: password)
                    await MainActor.run {
                        print("✅ AuthViewModel: Sign in successful")
                        self.isAuthenticated = true
                        self.currentUserEmail = session.user.email
                    }
                }
                
                group.addTask {
                    try await Task.sleep(nanoseconds: 15 * 1_000_000_000) // 15s timeout
                    throw AppError.unknown("Sign in timed out. Please check your internet connection.")
                }
                
                try await group.next()
                group.cancelAll()
            }
        } catch {
            print("❌ AuthViewModel: Sign in failed - \(error)")
            // Extract meaningful error message
            let errorMessage = AppError.from(error).localizedDescription
            // Simplify timeout message
            if errorMessage.contains("timed out") {
                self.error = "Request timed out. Please try again."
            } else {
                self.error = errorMessage
            }
        }
    }
    
    // MARK: - Sign Up
    /// Create new account
    func signUp(email: String, password: String, confirmPassword: String) async {
        guard !email.isEmpty else {
            error = "Please enter your email"
            return
        }
        
        guard password.count >= 6 else {
            error = "Password must be at least 6 characters"
            return
        }
        
        guard password == confirmPassword else {
            error = "Passwords do not match"
            return
        }
        
        isLoading = true
        error = nil
        
        // Ensure loading is reset no matter what
        defer { isLoading = false }
        
        do {
            print("🔑 AuthViewModel: Attempting sign up for \(email)")
            
            // Add timeout for sign up
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    let session = try await self.authService.signUp(email: email, password: password)
                    await MainActor.run {
                        print("✅ AuthViewModel: Sign up successful")
                        self.isAuthenticated = true
                        self.currentUserEmail = session.user.email
                    }
                }
                
                group.addTask {
                    try await Task.sleep(nanoseconds: 15 * 1_000_000_000) // 15s timeout
                    throw AppError.unknown("Sign up timed out. Please check your internet connection.")
                }
                
                try await group.next()
                group.cancelAll()
            }
        } catch {
            print("❌ AuthViewModel: Sign up failed - \(error)")
             // Extract meaningful error message
            let errorMessage = AppError.from(error).localizedDescription
            // Simplify timeout message
            if errorMessage.contains("timed out") {
                self.error = "Request timed out. Please try again."
            } else {
                self.error = errorMessage
            }
        }
    }
    
    // MARK: - Sign in with Apple
    /// Generate nonce for Sign in with Apple
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }
    
    /// Get SHA256 hash of nonce for Apple
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Handle Sign in with Apple result
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        error = nil
        
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let idToken = String(data: identityTokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                self.error = "Failed to get Apple credentials"
                isLoading = false
                return
            }
            
            do {
                let session = try await authService.signInWithApple(idToken: idToken, nonce: nonce)
                isAuthenticated = true
                currentUserEmail = session.user.email
            } catch {
                self.error = AppError.from(error).localizedDescription
            }
            
        case .failure(let error):
            // Don't show error if user cancelled
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                self.error = AppError.from(error).localizedDescription
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Sign in with OAuth (Google/GitHub)
    /// Start OAuth sign-in flow with the specified provider
    func signInWithOAuth(provider: OAuthProvider) async {
        isLoading = true
        error = nil
        
        do {
            let url = try await authService.signInWithOAuth(provider: provider)
            // Store the URL and trigger the web authentication session
            await MainActor.run {
                self.oauthURL = url
            }
        } catch {
            self.error = AppError.from(error).localizedDescription
            isLoading = false
        }
    }
    
    /// Convenience method for Google sign-in
    func signInWithGoogle() async {
        await signInWithOAuth(provider: .google)
    }
    
    /// Convenience method for GitHub sign-in
    func signInWithGitHub() async {
        await signInWithOAuth(provider: .github)
    }
    
    /// Handle OAuth callback URL
    func handleOAuthCallback(url: URL) async {
        isLoading = true
        error = nil
        
        do {
            let session = try await authService.handleOAuthCallback(url: url)
            isAuthenticated = true
            currentUserEmail = session.user.email
        } catch {
            self.error = AppError.from(error).localizedDescription
        }
        
        isLoading = false
        oauthURL = nil
    }
    
    /// Clear OAuth URL (called when web auth session completes or is cancelled)
    func clearOAuthURL() {
        oauthURL = nil
        isLoading = false
    }
    
    // MARK: - Sign Out
    /// Sign out current user
    func signOut() async {
        isLoading = true
        
        do {
            try await authService.signOut()
            isAuthenticated = false
            currentUserEmail = nil
        } catch {
            self.error = "Failed to sign out"
        }
        
        isLoading = false
    }
    
    // MARK: - Clear Error
    func clearError() {
        error = nil
    }
    
    // MARK: - Private Helpers
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
}
