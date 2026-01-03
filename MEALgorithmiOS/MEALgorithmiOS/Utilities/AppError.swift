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
            return "Please check your internet connection."
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
        
        // Network errors
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .networkConnection
            default:
                break
            }
        }
        
        // Handle Gemini/Supabase specific error strings if needed
        let message = error.localizedDescription.lowercased()
        if message.contains("network") || message.contains("connection") || message.contains("internet") {
            return .networkConnection
        }
        
        if message.contains("unauthorized") || message.contains("401") {
            return .unauthorized
        }
        
        if message.contains("500") || message.contains("internal server") {
            return .serverError
        }
        
        return .unknown(error.localizedDescription)
    }
}
