import SwiftUI

// MARK: - Settings View Model
/// Manages user profile settings and TDEE calculations
@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var error: String?
    
    // Physical Stats
    @Published var heightCm: Int?
    @Published var weightKg: Double?
    @Published var age: Int?
    @Published var gender: Gender = .male
    @Published var activityLevel: ActivityLevel = .moderate
    @Published var goalDescription: String = ""
    
    // Nutritional Targets
    @Published var calorieTarget: Int = 2000
    @Published var proteinTarget: Int = 150
    @Published var carbsTarget: Int = 200
    @Published var fatTarget: Int = 65
    @Published var useCustomTargets: Bool = false
    
    // User Info
    @Published var userEmail: String = ""
    
    // MARK: - Services
    private let profileService = ProfileService()
    
    // MARK: - Computed Properties
    var hasPhysicalStats: Bool {
        heightCm != nil && weightKg != nil && age != nil
    }
    
    // MARK: - Load Profile
    func loadProfile() async {
        isLoading = true
        error = nil
        
        do {
            let profile = try await profileService.getProfile()
            
            // Populate fields
            heightCm = profile.heightCm
            weightKg = profile.weightKg
            age = profile.age
            gender = profile.gender ?? .male
            activityLevel = profile.activityLevel ?? .moderate
            goalDescription = profile.goalDescription ?? ""
            
            // Targets
            if let calories = profile.calorieTarget {
                calorieTarget = calories
            }
            if let protein = profile.proteinTarget {
                proteinTarget = protein
            }
            if let carbs = profile.carbsTarget {
                carbsTarget = carbs
            }
            if let fat = profile.fatTarget {
                fatTarget = fat
            }
            
            // Calculate if we have stats
            if !useCustomTargets {
                recalculateTargets()
            }
            
        } catch {
            self.error = "Failed to load profile"
        }
        
        isLoading = false
    }
    
    // MARK: - Recalculate Targets
    /// Recalculate TDEE and macros based on physical stats
    func recalculateTargets() {
        guard !useCustomTargets,
              let height = heightCm,
              let weight = weightKg,
              let userAge = age else {
            return
        }
        
        let tdee = NutritionCalculator.calculateTDEE(
            weightKg: weight,
            heightCm: height,
            age: userAge,
            gender: gender,
            activityLevel: activityLevel
        )
        
        let macros = NutritionCalculator.calculateMacroTargets(tdee: tdee)
        
        calorieTarget = tdee
        proteinTarget = macros.protein
        carbsTarget = macros.carbs
        fatTarget = macros.fat
    }
    
    // MARK: - Save Profile
    func saveProfile() async {
        isSaving = true
        error = nil
        saveSuccess = false
        
        // Validate inputs (matching Web implementation)
        if let validationError = validateProfile() {
            error = validationError
            isSaving = false
            return
        }
        
        let update = ProfileUpdate(
            calorieTarget: calorieTarget,
            goalDescription: goalDescription.isEmpty ? nil : goalDescription,
            heightCm: heightCm,
            weightKg: weightKg,
            age: age,
            gender: gender.rawValue,
            activityLevel: activityLevel.rawValue,
            proteinTarget: proteinTarget,
            carbsTarget: carbsTarget,
            fatTarget: fatTarget
        )
        
        do {
            try await profileService.updateProfile(update)
            saveSuccess = true
            
            // Clear success after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            saveSuccess = false
        } catch {
            self.error = AppError.from(error).localizedDescription
        }
        
        isSaving = false
    }
    
    // MARK: - Validate Profile (matching Web implementation)
    /// Validates profile data before saving
    private func validateProfile() -> String? {
        var errors: [String] = []
        
        if let height = heightCm {
            if height < 50 || height > 250 {
                errors.append("Height must be between 50 and 250 cm")
            }
        }
        
        if let weight = weightKg {
            if weight < 10 || weight > 500 {
                errors.append("Weight must be between 10 and 500 kg")
            }
        }
        
        if let userAge = age {
            if userAge < 1 || userAge > 120 {
                errors.append("Age must be between 1 and 120 years")
            }
        }
        
        if calorieTarget < 500 || calorieTarget > 10000 {
            errors.append("Calorie target must be between 500 and 10,000 kcal")
        }
        
        if proteinTarget < 0 || proteinTarget > 500 {
            errors.append("Protein target must be between 0 and 500g")
        }
        
        if carbsTarget < 0 || carbsTarget > 1000 {
            errors.append("Carbs target must be between 0 and 1,000g")
        }
        
        if fatTarget < 0 || fatTarget > 500 {
            errors.append("Fat target must be between 0 and 500g")
        }
        
        return errors.isEmpty ? nil : errors.joined(separator: ". ")
    }
    
    // MARK: - Toggle Custom Targets
    func toggleCustomTargets() {
        useCustomTargets.toggle()
        if !useCustomTargets {
            recalculateTargets()
        }
    }
}
