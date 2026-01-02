import Foundation

// MARK: - Profile Model
/// Matches Supabase `profiles` table schema
struct Profile: Codable, Identifiable, Equatable {
    let id: UUID
    var calorieTarget: Int?
    var goalDescription: String?
    var fullName: String?
    var avatarUrl: String?
    var heightCm: Int?
    var weightKg: Double?
    var age: Int?
    var gender: Gender?
    var activityLevel: ActivityLevel?
    var proteinTarget: Int?
    var carbsTarget: Int?
    var fatTarget: Int?
    var cachedFeedback: String?
    var feedbackUpdatedAt: Date?
    var lastMealAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case calorieTarget = "calorie_target"
        case goalDescription = "goal_description"
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case age
        case gender
        case activityLevel = "activity_level"
        case proteinTarget = "protein_target"
        case carbsTarget = "carbs_target"
        case fatTarget = "fat_target"
        case cachedFeedback = "cached_feedback"
        case feedbackUpdatedAt = "feedback_updated_at"
        case lastMealAt = "last_meal_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Gender Enum
enum Gender: String, Codable, CaseIterable {
    case male
    case female
    case other
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        }
    }
}

// MARK: - Activity Level Enum
enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary
    case light
    case moderate
    case active
    case veryActive = "very_active"
    
    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary (little or no exercise)"
        case .light: return "Light (exercise 1-3 days/week)"
        case .moderate: return "Moderate (exercise 3-5 days/week)"
        case .active: return "Active (exercise 6-7 days/week)"
        case .veryActive: return "Very Active (intense exercise + physical job)"
        }
    }
    
    /// Activity multiplier for TDEE calculation
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }
}

// MARK: - Profile Update DTO
struct ProfileUpdate: Codable {
    var calorieTarget: Int?
    var goalDescription: String?
    var heightCm: Int?
    var weightKg: Double?
    var age: Int?
    var gender: String?
    var activityLevel: String?
    var proteinTarget: Int?
    var carbsTarget: Int?
    var fatTarget: Int?
    
    enum CodingKeys: String, CodingKey {
        case calorieTarget = "calorie_target"
        case goalDescription = "goal_description"
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case age
        case gender
        case activityLevel = "activity_level"
        case proteinTarget = "protein_target"
        case carbsTarget = "carbs_target"
        case fatTarget = "fat_target"
    }
}
