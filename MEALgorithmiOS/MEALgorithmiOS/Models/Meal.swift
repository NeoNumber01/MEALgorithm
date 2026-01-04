import Foundation

// MARK: - Meal Model
/// Matches Supabase `meals` table schema
struct Meal: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    var imagePath: String?
    var textContent: String?
    var analysis: MealAnalysis?
    var mealType: MealType?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case imagePath = "image_path"
        case textContent = "text_content"
        case analysis
        case mealType = "meal_type"
        case createdAt = "created_at"
    }
    
    /// Formatted time string for display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    /// Icon based on meal index in day
    func mealIcon(index: Int) -> String {
        switch index {
        case 0: return "🌅"
        case 1: return "☀️"
        case 2: return "🌙"
        default: return "🍿"
        }
    }
}

// MARK: - Meal Type Enum
enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .breakfast: return "🌅"
        case .lunch: return "☀️"
        case .dinner: return "🌙"
        case .snack: return "🍿"
        }
    }
}

// MARK: - Meal Analysis (AI Response)
struct MealAnalysis: Codable, Equatable {
    var items: [MealItem]
    var summary: NutritionInfo
    var feedback: String
}

// MARK: - Meal Item
struct MealItem: Codable, Equatable, Identifiable {
    var id: UUID { UUID() }
    var name: String
    var quantity: String
    var nutrition: NutritionInfo
    var confidence: Double?
    
    enum CodingKeys: String, CodingKey {
        case name
        case quantity
        case nutrition
        case confidence
    }
}

// MARK: - Nutrition Info
struct NutritionInfo: Codable, Equatable {
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    
    static var zero: NutritionInfo {
        NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0)
    }
    
    static func + (lhs: NutritionInfo, rhs: NutritionInfo) -> NutritionInfo {
        NutritionInfo(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat
        )
    }
    
    // Custom decoding to handle AI returning Floats/Doubles
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Helper to decode Int or Double and round to Int
        func decodeIntOrDouble(forKey key: CodingKeys) throws -> Int {
            if let intValue = try? container.decode(Int.self, forKey: key) {
                return intValue
            } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
                return Int(round(doubleValue))
            } else {
                // If missing or null, default to 0 to be resilient
                return 0
            }
        }
        
        calories = try decodeIntOrDouble(forKey: .calories)
        protein = try decodeIntOrDouble(forKey: .protein)
        carbs = try decodeIntOrDouble(forKey: .carbs)
        fat = try decodeIntOrDouble(forKey: .fat)
    }
    
    // Default init need to be explicit if we have custom decoding
    init(calories: Int, protein: Int, carbs: Int, fat: Int) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
    
    enum CodingKeys: String, CodingKey {
        case calories, protein, carbs, fat
    }
}

// MARK: - Meal Create DTO
struct MealCreate: Codable {
    let userId: UUID
    var textContent: String?
    var imagePath: String?
    var analysis: MealAnalysis
    var mealType: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case textContent = "text_content"
        case imagePath = "image_path"
        case analysis
        case mealType = "meal_type"
        case createdAt = "created_at"
    }
}
