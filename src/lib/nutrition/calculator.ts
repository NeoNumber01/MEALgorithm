// Utility functions for calculating nutritional targets

export type Gender = 'male' | 'female' | 'other'
export type ActivityLevel = 'sedentary' | 'light' | 'moderate' | 'active' | 'very_active'

// Activity level multipliers for TDEE
const ACTIVITY_MULTIPLIERS: Record<ActivityLevel, number> = {
    sedentary: 1.2,      // Little or no exercise
    light: 1.375,        // Light exercise 1-3 days/week
    moderate: 1.55,      // Moderate exercise 3-5 days/week
    active: 1.725,       // Hard exercise 6-7 days/week
    very_active: 1.9,    // Very hard exercise & physical job
}

/**
 * Calculate Basal Metabolic Rate using Mifflin-St Jeor Equation
 */
export function calculateBMR(
    weightKg: number,
    heightCm: number,
    age: number,
    gender: Gender
): number {
    // Mifflin-St Jeor Equation
    const base = 10 * weightKg + 6.25 * heightCm - 5 * age

    if (gender === 'male') {
        return Math.round(base + 5)
    } else {
        return Math.round(base - 161)
    }
}

/**
 * Calculate Total Daily Energy Expenditure
 */
export function calculateTDEE(
    weightKg: number,
    heightCm: number,
    age: number,
    gender: Gender,
    activityLevel: ActivityLevel
): number {
    const bmr = calculateBMR(weightKg, heightCm, age, gender)
    return Math.round(bmr * ACTIVITY_MULTIPLIERS[activityLevel])
}

/**
 * Calculate recommended macros based on calorie target
 * Default ratio: 30% protein, 40% carbs, 30% fat
 */
export function calculateMacroTargets(
    calorieTarget: number,
    proteinRatio = 0.30,
    carbsRatio = 0.40,
    fatRatio = 0.30
): { protein: number; carbs: number; fat: number } {
    // Calories per gram: Protein=4, Carbs=4, Fat=9
    return {
        protein: Math.round((calorieTarget * proteinRatio) / 4),
        carbs: Math.round((calorieTarget * carbsRatio) / 4),
        fat: Math.round((calorieTarget * fatRatio) / 9),
    }
}

/**
 * Get all nutritional targets from profile data
 */
export function getNutritionalTargets(profile: {
    height_cm?: number | null
    weight_kg?: number | null
    age?: number | null
    gender?: Gender | null
    activity_level?: ActivityLevel | null
    calorie_target?: number | null
    protein_target?: number | null
    carbs_target?: number | null
    fat_target?: number | null
}): {
    calories: number
    protein: number
    carbs: number
    fat: number
    isCalculated: boolean
} {
    let calories = profile.calorie_target || 2000
    let isCalculated = false

    // Calculate from physical stats if available
    if (profile.height_cm && profile.weight_kg && profile.age && profile.gender) {
        calories = calculateTDEE(
            profile.weight_kg,
            profile.height_cm,
            profile.age,
            profile.gender,
            profile.activity_level || 'moderate'
        )
        isCalculated = true
    }

    // Use custom macro targets if set, otherwise calculate
    const macros = calculateMacroTargets(calories)

    return {
        calories,
        protein: profile.protein_target || macros.protein,
        carbs: profile.carbs_target || macros.carbs,
        fat: profile.fat_target || macros.fat,
        isCalculated,
    }
}
