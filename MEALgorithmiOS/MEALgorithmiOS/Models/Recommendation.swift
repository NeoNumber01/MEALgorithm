import Foundation

// MARK: - Recommendation Model
struct Recommendation: Codable, Identifiable, Equatable {
    var id: UUID { UUID() }
    var name: String
    var description: String
    var reason: String
    var nutrition: NutritionInfo
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case reason
        case nutrition
    }
}

// MARK: - Day Plan Meal
struct DayPlanMeal: Codable, Identifiable, Equatable {
    var id: UUID { UUID() }
    var mealType: String
    var name: String
    var description: String
    var nutrition: NutritionInfo
    
    enum CodingKeys: String, CodingKey {
        case mealType
        case name
        case description
        case nutrition
    }
    
    var icon: String {
        switch mealType.lowercased() {
        case "breakfast": return "🌅"
        case "lunch": return "☀️"
        case "dinner": return "🌙"
        case "snack": return "🍿"
        default: return "🍽️"
        }
    }
}

// MARK: - Day Plan Summary
struct DayPlanSummary: Codable, Equatable {
    var totalPlannedCalories: Int
    var advice: String
}

// MARK: - Day Plan Context
struct DayPlanContext: Codable, Equatable {
    var targetCalories: Int
    var consumedCalories: Int
    var remainingCalories: Int
    var eatenMealTypes: [String]
    var remainingMealTypes: [String]
}

// MARK: - Recommendation Context
struct RecommendationContext: Codable, Equatable {
    var targetCalories: Int
    var recentAvgCalories: Int
    var goal: String?
}
