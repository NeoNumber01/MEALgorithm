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
            if let session = try await authService.getSession() {
                isAuthenticated = true
                currentUserEmail = session.user.email
            } else {
                isAuthenticated = false
            }
        } catch {
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
        
        do {
            let session = try await authService.signIn(email: email, password: password)
            isAuthenticated = true
            currentUserEmail = session.user.email
        } catch {
            self.error = AppError.from(error).localizedDescription
        }
        
        isLoading = false
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
        
        do {
            let session = try await authService.signUp(email: email, password: password)
            isAuthenticated = true
            currentUserEmail = session.user.email
        } catch {
            self.error = AppError.from(error).localizedDescription
        }
        
        isLoading = false
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
