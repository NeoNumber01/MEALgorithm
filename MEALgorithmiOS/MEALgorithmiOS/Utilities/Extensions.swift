import SwiftUI
import Foundation

// MARK: - Color Extensions
extension Color {
    // MARK: - Nebula Theme Palette
    static let appBackground = Color(hex: "0F1115") // Deep Space
    static let appSurface = Color(hex: "1C1E26") // Nebula Surface
    
    // Primary Vibrant
    static let appPrimary = Color(hex: "00F0FF") // Cyan Neon
    static let appSecondary = Color(hex: "00FF94") // Neon Green
    
    // Macro Gradients (Start/End)
    static let proteinStart = Color(hex: "FF512F")
    static let proteinEnd = Color(hex: "DD2476")
    
    static let carbsStart = Color(hex: "F09819")
    static let carbsEnd = Color(hex: "FF512F")
    
    static let fatStart = Color(hex: "4776E6")
    static let fatEnd = Color(hex: "8E54E9")
    
    static let caloriesStart = Color(hex: "FF8008")
    static let caloriesEnd = Color(hex: "FFC837")
    
    // Legacy mapping for compatibility
    static let proteinColor = proteinStart
    static let carbsColor = carbsStart
    static let fatColor = fatStart
    static let caloriesColor = caloriesStart
    
    // Helper init
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension LinearGradient {
    static let protein = LinearGradient(colors: [.proteinStart, .proteinEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let carbs = LinearGradient(colors: [.carbsStart, .carbsEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let fat = LinearGradient(colors: [.fatStart, .fatEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let calories = LinearGradient(colors: [.caloriesStart, .caloriesEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let nebulaEffect = LinearGradient(colors: [.appPrimary.opacity(0.2), .appSecondary.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
        return "\(Swift.min(100, (self * 100) / total))%"
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

// MARK: - Notification Extensions
extension Notification.Name {
    static let profileDidUpdate = Notification.Name("ProfileDidUpdate")
    static let mealDidSave = Notification.Name("MealDidSave")
    static let mealDidDelete = Notification.Name("MealDidDelete")
}
