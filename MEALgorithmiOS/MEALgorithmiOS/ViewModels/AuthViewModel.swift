import SwiftUI
import Supabase

// MARK: - Auth View Model
/// Manages authentication state and operations
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var error: String?
    @Published var currentUserEmail: String?
    
    // MARK: - Services
    private let authService = AuthService()
    
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
            self.error = "Invalid email or password"
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
            self.error = "Failed to create account. Please try again."
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
}
