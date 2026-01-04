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
        // SECURITY: Never hardcode these values in production
        var supabaseURL: String
        var supabaseKey: String
        
        if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            supabaseURL = envURL
            supabaseKey = envKey
            print("📦 SupabaseManager: Using environment variables")
        } else if let infoPlistURL = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
                  let infoPlistKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
                  !infoPlistURL.hasPrefix("$("),  // Check if value was substituted
                  !infoPlistKey.hasPrefix("$(") {
            supabaseURL = infoPlistURL
            supabaseKey = infoPlistKey
            print("📦 SupabaseManager: Using Info.plist")
        } else {
            // CRITICAL: No API Keys found.
            // In production, this should likely show a fatal error screen or crash.
            // We removed the hardcoded fallback for security.
            fatalError("🚨 FATAL: Supabase API Keys are missing! Set SUPABASE_URL and SUPABASE_ANON_KEY in Environment or Info.plist.")
        }
        
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid SUPABASE_URL: \(supabaseURL)")
        }
        
        print("📦 SupabaseManager: Connecting to \(url.host ?? "unknown")")
        
        // Create custom URLSession configuration to help with iOS Simulator network issues
        // Cloudflare (used by Supabase) enables HTTP/3 by default, which can cause
        // "network connection was lost" errors (-1005) on iOS Simulator
        let urlSessionConfiguration = URLSessionConfiguration.default
        
        // Stability settings to help with QUIC/HTTP3 issues
        urlSessionConfiguration.multipathServiceType = .none
        urlSessionConfiguration.timeoutIntervalForRequest = 30
        urlSessionConfiguration.timeoutIntervalForResource = 60
        urlSessionConfiguration.waitsForConnectivity = true
        
        // These settings help ensure connection attempts proceed
        urlSessionConfiguration.allowsConstrainedNetworkAccess = true
        urlSessionConfiguration.allowsExpensiveNetworkAccess = true
        
        // Note: If you encounter "network connection was lost" errors on Simulator:
        // 1. Reset the iOS Simulator: Device > Erase All Content and Settings
        // 2. Or test on a real device instead
        print("📦 SupabaseManager: Custom URLSession configured")
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                global: SupabaseClientOptions.GlobalOptions(
                    session: URLSession(configuration: urlSessionConfiguration)
                )
            )
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
