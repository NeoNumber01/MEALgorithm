import Foundation

// MARK: - Nutrition Calculator
/// Implements Mifflin-St Jeor equation for TDEE calculation
/// Matches web app implementation in lib/nutrition/calculator.ts
struct NutritionCalculator {
    
    // MARK: - Calculate BMR
    /// Calculate Basal Metabolic Rate using Mifflin-St Jeor equation
    /// - Parameters:
    ///   - weightKg: Weight in kilograms
    ///   - heightCm: Height in centimeters
    ///   - age: Age in years
    ///   - gender: Gender for formula selection
    /// - Returns: BMR in calories
    static func calculateBMR(
        weightKg: Double,
        heightCm: Int,
        age: Int,
        gender: Gender
    ) -> Double {
        // Mifflin-St Jeor Equation:
        // Men: BMR = 10 × weight(kg) + 6.25 × height(cm) − 5 × age(y) + 5
        // Women: BMR = 10 × weight(kg) + 6.25 × height(cm) − 5 × age(y) − 161
        let base = 10.0 * weightKg + 6.25 * Double(heightCm) - 5.0 * Double(age)
        
        switch gender {
        case .male:
            return base + 5
        case .female:
            return base - 161
        case .other:
            // Use average of male and female formulas
            return base - 78
        }
    }
    
    // MARK: - Calculate TDEE
    /// Calculate Total Daily Energy Expenditure
    /// - Parameters:
    ///   - weightKg: Weight in kilograms
    ///   - heightCm: Height in centimeters
    ///   - age: Age in years
    ///   - gender: Gender for BMR calculation
    ///   - activityLevel: Activity level multiplier
    /// - Returns: TDEE in calories (rounded to nearest integer)
    static func calculateTDEE(
        weightKg: Double,
        heightCm: Int,
        age: Int,
        gender: Gender,
        activityLevel: ActivityLevel
    ) -> Int {
        let bmr = calculateBMR(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            gender: gender
        )
        return Int(round(bmr * activityLevel.multiplier))
    }
    
    // MARK: - Calculate Macro Targets
    /// Calculate recommended macro targets based on TDEE
    /// Uses standard macro split: 30% protein, 40% carbs, 30% fat
    /// - Parameter tdee: Total Daily Energy Expenditure
    /// - Returns: Tuple with protein, carbs, and fat targets in grams
    static func calculateMacroTargets(tdee: Int) -> (protein: Int, carbs: Int, fat: Int) {
        // Standard macro split
        // Protein: 30% of calories, 4 cal/g
        // Carbs: 40% of calories, 4 cal/g
        // Fat: 30% of calories, 9 cal/g
        
        let proteinCalories = Double(tdee) * 0.30
        let carbsCalories = Double(tdee) * 0.40
        let fatCalories = Double(tdee) * 0.30
        
        return (
            protein: Int(round(proteinCalories / 4.0)),
            carbs: Int(round(carbsCalories / 4.0)),
            fat: Int(round(fatCalories / 9.0))
        )
    }
    
    // MARK: - Get Nutritional Targets from Profile
    /// Get complete nutritional targets from user profile
    /// Uses profile values if set, otherwise calculates from physical stats
    static func getTargets(from profile: Profile) -> NutritionInfo {
        // If user has custom targets, use those
        if let calories = profile.calorieTarget,
           let protein = profile.proteinTarget,
           let carbs = profile.carbsTarget,
           let fat = profile.fatTarget {
            return NutritionInfo(
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat
            )
        }
        
        // Otherwise calculate from physical stats
        guard let weightKg = profile.weightKg,
              let heightCm = profile.heightCm,
              let age = profile.age,
              let gender = profile.gender,
              let activityLevel = profile.activityLevel else {
            // Return defaults if stats not available
            return NutritionInfo(
                calories: 2000,
                protein: 150,
                carbs: 200,
                fat: 65
            )
        }
        
        let tdee = calculateTDEE(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            gender: gender,
            activityLevel: activityLevel
        )
        
        let macros = calculateMacroTargets(tdee: tdee)
        
        return NutritionInfo(
            calories: tdee,
            protein: macros.protein,
            carbs: macros.carbs,
            fat: macros.fat
        )
    }
}
