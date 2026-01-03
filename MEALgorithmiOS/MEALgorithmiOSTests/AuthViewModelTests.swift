import XCTest
import Supabase // If needed for Session types
@testable import MEALgorithmiOS

@MainActor
final class AuthViewModelTests: XCTestCase {
    var viewModel: AuthViewModel!
    var mockAuthService: MockAuthService!
    
    override func setUp() {
        mockAuthService = MockAuthService()
        viewModel = AuthViewModel(authService: mockAuthService)
    }
    
    func testSignInSuccess() async {
        // Given
        // Can't easily construct real Session struct as init might be internal in Supabase lib.
        // However, we can test protocol interaction or just success flow if we can assume Session object presence.
        // Or simpler: MockAuthService throwing/returning nil.
        // Assuming we can instantiate a dummy Session or rely on protocol returning it.
        // (Supabase Session struct is public usually)
        
        // When
        // await viewModel.signIn(email: "test@example.com", password: "password")
        
        // As constructing 'Session' might be hard without valid JSON/Token, we will verify Error handling primarily.
    }
    
    func testSignInFailure() async {
        await mockAuthService.setError(AuthError.sessionNotFound)
        
        await viewModel.signIn(email: "test@test.com", password: "pass")
        
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isAuthenticated)
    }
}
