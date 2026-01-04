import Foundation
import Supabase
import Auth

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
            fatalError("🚨 FATAL: Supabase API Keys are missing! Set SUPABASE_URL and SUPABASE_ANON_KEY in Environment or Info.plist.")
        }
        
        // Sanitize inputs
        let rawURL = supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "")
        let sanitizedKey = supabaseKey.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "")
        
        print("📦 RAW URL: '\(supabaseURL)'")
        print("📦 CLEAN URL: '\(rawURL)'")
        
        // Ensure scheme is present
        let sanitizedURL = rawURL.hasPrefix("https://") ? rawURL : "https://\(rawURL)"
        print("📦 FINAL URL: '\(sanitizedURL)'")
        
        guard let url = URL(string: sanitizedURL), let host = url.host else {
            fatalError("🚨 Invalid SUPABASE_URL: '\(sanitizedURL)'. Host is nil.")
        }
        
        print("📦 SupabaseManager: Connecting to \(host)")
        
        // Create custom URLSession configuration
        let urlSessionConfiguration = URLSessionConfiguration.default
        
        // STANDARD SETTINGS (Strategy 1: Simplify for Debugging)
        // We removed 'waitsForConnectivity = true' and 'multipathServiceType'
        // to prevent the "Silent Hang" issue where the OS holds the request indefinitely.
        urlSessionConfiguration.timeoutIntervalForRequest = 30
        urlSessionConfiguration.timeoutIntervalForResource = 60
        
        print("📦 SupabaseManager: Custom URLSession configured (Simplified Strategy 1)")
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: sanitizedKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                ),
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
