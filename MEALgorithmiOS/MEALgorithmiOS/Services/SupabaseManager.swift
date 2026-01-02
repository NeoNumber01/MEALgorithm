import Foundation
import Supabase

// MARK: - Supabase Manager
/// Singleton for managing Supabase client connection
/// API keys are loaded from environment variables for security
final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // Load from environment variables or Info.plist
        // SECURITY: Never hardcode these values
        let supabaseURL: String
        let supabaseKey: String
        
        if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            supabaseURL = envURL
            supabaseKey = envKey
        } else if let infoPlistURL = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
                  let infoPlistKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String {
            supabaseURL = infoPlistURL
            supabaseKey = infoPlistKey
        } else {
            // Fallback for development - should be replaced with actual values
            fatalError("""
                Missing Supabase configuration.
                Set SUPABASE_URL and SUPABASE_ANON_KEY in:
                - Environment variables (for Xcode scheme), or
                - Info.plist
                """)
        }
        
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid SUPABASE_URL: \(supabaseURL)")
        }
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey
        )
    }
}

// MARK: - Supabase Extensions
extension SupabaseManager {
    /// Current authenticated user
    var currentUser: User? {
        get async {
            try? await client.auth.session.user
        }
    }
    
    /// Current user ID
    var currentUserId: UUID? {
        get async {
            await currentUser?.id
        }
    }
}
