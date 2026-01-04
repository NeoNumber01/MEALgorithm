import Foundation

// MARK: - App Error
enum AppError: LocalizedError {
    case networkConnection
    case serverError
    case unauthorized
    case validationFailed(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkConnection:
            // TEMP DEBUG: Show actual details
            return "Network Error (check Xcode console for details)"
        case .serverError:
            return "Our servers are experiencing issues. Please try again later."
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .validationFailed(let message):
            return message
        case .unknown(let message):
            return message
        }
    }
    
    // Helper to map errors
    static func from(_ error: Error) -> AppError {
        let nsError = error as NSError
        
        // Debug: Print actual error for diagnosics
        print("🔴 AppError: Original error - \(error)")
        print("🔴 AppError: Domain=\(nsError.domain), Code=\(nsError.code)")
        print("🔴 AppError: Description=\(error.localizedDescription)")
        
        // Network errors (URL loading system)
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .networkConnection
            case NSURLErrorTimedOut:
                return .serverError  // Timeout is more likely server issue
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return .serverError  // DNS/Host issues
            default:
                break
            }
        }
        
        // Supabase Auth specific errors - check for auth error types
        let message = error.localizedDescription.lowercased()
        
        // More specific checks before falling back to generic "connection" check
        if message.contains("invalid login credentials") || message.contains("email not confirmed") {
            return .validationFailed(error.localizedDescription)
        }
        
        if message.contains("user already registered") {
            return .validationFailed("This email is already registered. Try signing in instead.")
        }
        
        if message.contains("unauthorized") || message.contains("401") {
            return .unauthorized
        }
        
        if message.contains("500") || message.contains("internal server") {
            return .serverError
        }
        
        // Network-like errors - be more specific
        if nsError.domain == NSURLErrorDomain {
            // Any remaining URL errors likely indicate connectivity issues
            return .networkConnection
        }
        
        // For non-URL errors that mention "connection", show the actual message
        // This avoids hiding Supabase-specific errors
        return .unknown(error.localizedDescription)
    }
}
