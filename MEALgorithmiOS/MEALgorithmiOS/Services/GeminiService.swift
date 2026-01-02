import Foundation
import GoogleGenerativeAI
import UIKit

// MARK: - Gemini Service
/// Handles AI-powered meal analysis using Google Gemini
actor GeminiService {
    private let model: GenerativeModel
    
    // MARK: - System Prompt (matching web app)
    private let systemPrompt = """
    You are an expert Nutritionist AI.
    Your task is to analyze the user's meal input (text or image) and output a structured nutritional analysis.
    
    Rules:
    1. Identify all food items and estimate their portions.
    2. Estimate calories, protein(g), carbs(g), and fat(g) for each item.
    3. Provide a summary of the total values.
    4. Give a short, encouraging feedback message (max 2 sentences).
    5. Output strict JSON format matching the schema:
       {
         "items": [{ "name": "...", "quantity": "...", "nutrition": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 } }],
         "summary": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 },
         "feedback": "..."
       }
    """
    
    init() {
        // Load API key from environment or Info.plist
        let apiKey: String
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            apiKey = envKey
        } else if let plistKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String {
            apiKey = plistKey
        } else {
            fatalError("Missing GEMINI_API_KEY in environment or Info.plist")
        }
        
        model = GenerativeModel(name: "gemini-2.0-flash", apiKey: apiKey)
    }
    
    // MARK: - Analyze Meal
    /// Analyze meal from text description and/or image
    func analyzeMeal(text: String?, image: UIImage?) async throws -> MealAnalysis {
        guard text != nil || image != nil else {
            throw GeminiError.noInput
        }
        
        var parts: [any ThrowingPartsRepresentable] = [systemPrompt]
        
        if let text = text, !text.isEmpty {
            parts.append("\nUser Text Input: \"\(text)\"")
        }
        
        if let image = image {
            parts.append(image)
        }
        
        // First attempt
        let response = try await model.generateContent(parts)
        guard let responseText = response.text else {
            throw GeminiError.emptyResponse
        }
        
        // Try to parse
        do {
            return try parseAnalysis(from: responseText)
        } catch {
            // Retry with error feedback
            print("First parse failed, retrying...")
            let retryParts: [any ThrowingPartsRepresentable] = parts + [
                "\nPrevious Output: \(responseText)",
                "\nError: The JSON was invalid. Please fix it to match the schema strictly. JSON only."
            ]
            
            let retryResponse = try await model.generateContent(retryParts)
            guard let retryText = retryResponse.text else {
                throw GeminiError.emptyResponse
            }
            
            return try parseAnalysis(from: retryText)
        }
    }
    
    // MARK: - Generate Recommendations
    /// Generate meal recommendations based on user context
    func generateRecommendations(
        targetCalories: Int,
        recentAvgCalories: Int,
        goal: String?,
        preferences: [String]?
    ) async throws -> [Recommendation] {
        let prompt = """
        You are a personalized meal recommendation AI.
        
        User Context:
        - Daily calorie target: \(targetCalories) kcal
        - Recent average calories per meal: \(recentAvgCalories) kcal
        - Goal: \(goal ?? "General Health")
        - Food preferences: \(preferences?.joined(separator: ", ") ?? "None specified")
        
        Generate 3 meal recommendations. Output strict JSON array:
        [
          {
            "name": "Meal Name",
            "description": "Brief description",
            "reason": "Why this meal is recommended",
            "nutrition": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 }
          }
        ]
        """
        
        let response = try await model.generateContent(prompt)
        guard let responseText = response.text else {
            throw GeminiError.emptyResponse
        }
        
        return try parseRecommendations(from: responseText)
    }
    
    // MARK: - Generate Day Plan
    /// Generate a full day meal plan
    func generateDayPlan(
        targetCalories: Int,
        consumedCalories: Int,
        eatenMealTypes: [String],
        goal: String?,
        preferences: [String]?
    ) async throws -> (meals: [DayPlanMeal], summary: DayPlanSummary) {
        let remainingMealTypes = ["breakfast", "lunch", "dinner", "snack"]
            .filter { !eatenMealTypes.contains($0) }
        
        let prompt = """
        You are a meal planning AI.
        
        User Context:
        - Daily target: \(targetCalories) kcal
        - Already consumed: \(consumedCalories) kcal
        - Remaining calories: \(targetCalories - consumedCalories) kcal
        - Already eaten: \(eatenMealTypes.isEmpty ? "Nothing yet" : eatenMealTypes.joined(separator: ", "))
        - Meals to plan: \(remainingMealTypes.joined(separator: ", "))
        - Goal: \(goal ?? "General Health")
        - Preferences: \(preferences?.joined(separator: ", ") ?? "None")
        
        Create a meal plan for the remaining meals. Output strict JSON:
        {
          "dayPlan": [
            {
              "mealType": "breakfast|lunch|dinner|snack",
              "name": "Meal Name",
              "description": "Brief description",
              "nutrition": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 }
            }
          ],
          "summary": {
            "totalPlannedCalories": 0,
            "advice": "Brief nutritional advice"
          }
        }
        """
        
        let response = try await model.generateContent(prompt)
        guard let responseText = response.text else {
            throw GeminiError.emptyResponse
        }
        
        return try parseDayPlan(from: responseText)
    }
    
    // MARK: - Generate AI Feedback
    /// Generate personalized feedback based on daily progress
    func generateFeedback(
        todayCalories: Int,
        weeklyAvgCalories: Int,
        targetCalories: Int,
        goal: String?
    ) async throws -> String {
        let prompt = """
        You are a supportive nutrition coach AI.
        
        User's Progress:
        - Today's calories: \(todayCalories) kcal
        - Weekly average: \(weeklyAvgCalories) kcal
        - Daily target: \(targetCalories) kcal
        - Goal: \(goal ?? "General Health")
        
        Provide a brief, encouraging feedback message (2-3 sentences max).
        Be specific about their progress. Output just the text, no JSON.
        """
        
        let response = try await model.generateContent(prompt)
        return response.text ?? "Keep up the great work! You're making progress."
    }
    
    // MARK: - Parsing Helpers
    private func parseAnalysis(from text: String) throws -> MealAnalysis {
        let cleanedText = cleanJSON(text)
        guard let data = cleanedText.data(using: .utf8) else {
            throw GeminiError.invalidJSON
        }
        return try JSONDecoder().decode(MealAnalysis.self, from: data)
    }
    
    private func parseRecommendations(from text: String) throws -> [Recommendation] {
        let cleanedText = cleanJSON(text)
        guard let data = cleanedText.data(using: .utf8) else {
            throw GeminiError.invalidJSON
        }
        return try JSONDecoder().decode([Recommendation].self, from: data)
    }
    
    private func parseDayPlan(from text: String) throws -> (meals: [DayPlanMeal], summary: DayPlanSummary) {
        let cleanedText = cleanJSON(text)
        guard let data = cleanedText.data(using: .utf8) else {
            throw GeminiError.invalidJSON
        }
        
        struct DayPlanResponse: Codable {
            var dayPlan: [DayPlanMeal]
            var summary: DayPlanSummary
        }
        
        let response = try JSONDecoder().decode(DayPlanResponse.self, from: data)
        return (response.dayPlan, response.summary)
    }
    
    /// Remove markdown code blocks if present
    private func cleanJSON(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Gemini Errors
enum GeminiError: LocalizedError {
    case noInput
    case emptyResponse
    case invalidJSON
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .noInput:
            return "Please provide either text or an image"
        case .emptyResponse:
            return "AI returned an empty response"
        case .invalidJSON:
            return "Failed to parse AI response"
        case .apiError(let message):
            return message
        }
    }
}
