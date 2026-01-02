import SwiftUI
import Foundation

// MARK: - Color Extensions
extension Color {
    // App color palette
    static let appPrimary = Color(red: 0.0, green: 0.75, blue: 0.85) // Cyan
    static let appSecondary = Color(red: 0.55, green: 0.85, blue: 0.35) // Lime
    static let appGradientStart = Color(red: 0.0, green: 0.75, blue: 0.85)
    static let appGradientEnd = Color(red: 0.55, green: 0.85, blue: 0.35)
    
    // Macro colors
    static let proteinColor = Color(red: 0.9, green: 0.3, blue: 0.35)
    static let carbsColor = Color(red: 0.95, green: 0.65, blue: 0.2)
    static let fatColor = Color(red: 0.3, green: 0.5, blue: 0.9)
    static let caloriesColor = Color(red: 0.95, green: 0.5, blue: 0.2)
}

// MARK: - Date Extensions
extension Date {
    /// Start of current day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// End of current day
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
    }
    
    /// Format as time string (e.g., "2:30 PM")
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Format as date string (e.g., "Monday, January 2")
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: self)
    }
    
    /// Format for API calls (YYYY-MM-DD)
    var apiFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}

// MARK: - View Extensions
extension View {
    /// Hide keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Conditional modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Optional Extensions
extension Optional where Wrapped == String {
    /// Returns empty string if nil
    var orEmpty: String {
        self ?? ""
    }
}

// MARK: - Array Extensions
extension Array where Element == Meal {
    /// Calculate total nutrition from meals
    var totalNutrition: NutritionInfo {
        reduce(NutritionInfo.zero) { total, meal in
            if let summary = meal.analysis?.summary {
                return total + summary
            }
            return total
        }
    }
}

// MARK: - Int Extensions
extension Int {
    /// Format as percentage string
    func asPercentage(of total: Int) -> String {
        guard total > 0 else { return "0%" }
        return "\(min(100, (self * 100) / total))%"
    }
}

// MARK: - Double Extensions
extension Double {
    /// Round to specified decimal places
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
