#if false
import XCTest
@testable import MEALgorithmiOS
import Supabase

@MainActor
final class AuthViewModelTests: XCTestCase {
    
    var viewModel: AuthViewModel!
    var mockAuthService: AuthViewModelTestsMockAuthService!
    
    override func setUp() async throws {
        mockAuthService = AuthViewModelTestsMockAuthService()
        viewModel = AuthViewModel(authService: mockAuthService)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockAuthService = nil
    }
    
    func testSignIn_Success() async {
        // Given
        await mockAuthService.setShouldSucceed(true)
        
        // When
        await viewModel.signIn(email: "test@example.com", password: "password")
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.currentUserEmail, "test@example.com")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testSignIn_Failure() async {
        // Given
        await mockAuthService.setShouldSucceed(false)
        
        // When
        await viewModel.signIn(email: "test@example.com", password: "password")
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // We cannot easily test the exact timeout logic without slow mocks or waiting 15s,
    // but we can ensure the structure handles errors correctly.
}

// Mock AuthService
actor AuthViewModelTestsMockAuthService: AuthServiceProtocol {
    var shouldSucceed = true
    
    func getSession() async throws -> Session? {
        if shouldSucceed {
            return Session(accessToken: "mock_token", tokenType: "bearer", expiresIn: 3600, refreshToken: "mock_refresh", user: User(id: UUID(), appMetadata: [:], userMetadata: [:], aud: "authenticated", createdAt: Date(), email: "test@example.com"))
        }
        return nil
    }
    
    func signIn(email: String, password: String) async throws -> Session {
        if shouldSucceed {
             return Session(accessToken: "mock_token", tokenType: "bearer", expiresIn: 3600, refreshToken: "mock_refresh", user: User(id: UUID(), appMetadata: [:], userMetadata: [:], aud: "authenticated", createdAt: Date(), email: "test@example.com"))
        }
        throw AppError.unknown("Mock sign in failed")
    }
    
    func signUp(email: String, password: String) async throws -> Session {
        if shouldSucceed {
             return Session(accessToken: "mock_token", tokenType: "bearer", expiresIn: 3600, refreshToken: "mock_refresh", user: User(id: UUID(), appMetadata: [:], userMetadata: [:], aud: "authenticated", createdAt: Date(), email: "test@example.com"))
        }
        throw AppError.unknown("Mock sign up failed")
    }
    
    func signInWithApple(idToken: String, nonce: String) async throws -> Session {
        if shouldSucceed {
             return Session(accessToken: "mock_token", tokenType: "bearer", expiresIn: 3600, refreshToken: "mock_refresh", user: User(id: UUID(), appMetadata: [:], userMetadata: [:], aud: "authenticated", createdAt: Date(), email: "test@example.com"))
        }
        throw AppError.unknown("Mock Apple sign in failed")
    }
    
    func signInWithOAuth(provider: OAuthProvider) async throws -> URL {
        return URL(string: "https://example.com")!
    }
    
    func handleOAuthCallback(url: URL) async throws -> Session {
        if shouldSucceed {
             return Session(accessToken: "mock_token", tokenType: "bearer", expiresIn: 3600, refreshToken: "mock_refresh", user: User(id: UUID(), appMetadata: [:], userMetadata: [:], aud: "authenticated", createdAt: Date(), email: "test@example.com"))
        }
        throw AppError.unknown("Mock OAuth failed")
    }
    
    func signOut() async throws {
        // no-op
    }
    
    func isAuthenticated() async -> Bool {
        return shouldSucceed && (try? await getSession()) != nil
    }
    
    func getCurrentUser() async -> User? {
        return try? await getSession()?.user
    }
    
    func setShouldSucceed(_ value: Bool) {
        self.shouldSucceed = value
    }
}
#endif
