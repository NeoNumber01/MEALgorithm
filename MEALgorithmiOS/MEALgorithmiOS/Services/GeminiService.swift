import Foundation
import GoogleGenerativeAI
import UIKit

// MARK: - Gemini Service
/// Handles AI-powered meal analysis using Google Gemini
actor GeminiService: GeminiServiceProtocol {
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
        // PRIORITY ORDER:
        // 1. Environment variable (most reliable for debugging)
        // 2. Info.plist (via xcconfig substitution)
        
        let apiKey: String
        
        // Try environment variable first
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
           !envKey.isEmpty,
           envKey.count > 10 {
            apiKey = envKey
            print("🤖 GeminiService: Using environment variable (len: \(envKey.count))")
        }
        // Try Info.plist
        else if let plistKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String,
                !plistKey.hasPrefix("$("),
                !plistKey.isEmpty,
                plistKey.count > 10 {
            apiKey = plistKey
            print("🤖 GeminiService: Using Info.plist (len: \(plistKey.count))")
        }
        // Debug: show what we got
        else {
            let envVal = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "nil"
            let plistVal = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? "nil"
            print("❌ GeminiService Debug:")
            print("   ENV value: '\(envVal)' (len: \(envVal.count))")
            print("   PLIST value: '\(plistVal)' (len: \(plistVal.count))")
            fatalError("GEMINI_API_KEY not found. Check Xcode console for debug info.")
        }
        
        model = GenerativeModel(name: "gemini-2.5-flash", apiKey: apiKey)
        print("🤖 GeminiService: Initialized with gemini-2.5-flash")
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
        
        // No retry logic - strict pass/fail
        do {
            let response = try await model.generateContent(parts)
            guard let responseText = response.text else {
                throw GeminiError.emptyResponse
            }
            
            // Try to parse
            do {
                return try parseAnalysis(from: responseText)
            } catch {
                // One-time correction attempt for JSON issues (not a network retry)
                print("🤖 Gemini: First parse failed, attempting JSON correction...")
                let correctionParts: [any ThrowingPartsRepresentable] = parts + [
                    "\nPrevious Output: \(responseText)",
                    "\nError: The JSON was invalid. Please fix it to match the schema strictly. JSON only."
                ]
                
                let retryResponse = try await model.generateContent(correctionParts)
                guard let retryText = retryResponse.text else {
                    throw GeminiError.emptyResponse
                }
                return try parseAnalysis(from: retryText)
            }
        } catch {
            throw mapError(error)
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
        
        do {
            let response = try await model.generateContent(prompt)
            guard let responseText = response.text else {
                throw GeminiError.emptyResponse
            }
            return try parseRecommendations(from: responseText)
        } catch {
            throw mapError(error)
        }
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
        
        do {
            let response = try await model.generateContent(prompt)
            guard let responseText = response.text else {
                throw GeminiError.emptyResponse
            }
            return try parseDayPlan(from: responseText)
        } catch {
            throw mapError(error)
        }
    }
    
    // MARK: - Generate AI Feedback
    /// Generate personalized feedback based on daily progress (matching Web implementation)
    func generateFeedback(
        todayCalories: Int,
        weeklyAvgCalories: Int,
        targetCalories: Int,
        goal: String?
    ) async throws -> String {
        // Calculate percentages (matching Web implementation)
        let todayPercent = targetCalories > 0 ? Int(round(Double(todayCalories) / Double(targetCalories) * 100)) : 0
        let weeklyPercent = targetCalories > 0 ? Int(round(Double(weeklyAvgCalories) / Double(targetCalories) * 100)) : 0
        
        let prompt = """
        You are a supportive and motivating nutritionist AI coach.
        Based on the following data, provide a brief 1-2 sentence personalized feedback focused on TODAY's intake.
        
        Today's Calories: \(todayCalories) kcal (\(todayPercent)% of target)
        Weekly Average: \(weeklyAvgCalories) kcal (\(weeklyPercent)% of target)
        Daily Target: \(targetCalories) kcal
        User's Goal: \(goal ?? "General health and wellness")
        
        Guidelines:
        - Focus primarily on TODAY's performance
        - If today is on target (80-120%), be encouraging and celebrate
        - If today is under target, suggest easy ways to add healthy calories
        - If today is over target, be gentle and suggest balance
        - Keep it positive and actionable
        - Use an emoji at the start that matches the mood
        - If there's no data today, encourage them to log their first meal
        
        Respond with just the feedback text, no JSON or markdown.
        """
        
        do {
            let response = try await model.generateContent(prompt)
            if let text = response.text {
                return cleanFeedbackResponse(text)
            }
            return "🎯 Keep tracking your meals to get personalized feedback!"
        } catch {
            throw mapError(error)
        }
    }
    
    /// Clean AI response text (matching Web cleanResponse function)
    private func cleanFeedbackResponse(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks
        cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```text", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        
        // Remove surrounding quotes if present
        if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
            cleaned = String(cleaned.dropFirst().dropLast())
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    // MARK: - Generate Statistics Insight (matching Web implementation)
    /// Generate AI insight for statistics view based on weekly data
    func generateStatisticsInsight(
        periodLabel: String,
        totalDays: Int,
        daysWithMeals: Int,
        totalMeals: Int,
        avgCalories: Int,
        avgProtein: Int,
        avgCarbs: Int,
        avgFat: Int,
        targetCalories: Int,
        goalDescription: String?
    ) async throws -> String {
        let avgPercent = targetCalories > 0 ? Int(round(Double(avgCalories) / Double(targetCalories) * 100)) : 0
        let trackingRate = totalDays > 0 ? Int(round(Double(daysWithMeals) / Double(totalDays) * 100)) : 0
        
        let prompt = """
        You are a supportive nutritionist AI analyzing a user's eating habits over a time period.
        Based on the following statistics, provide 2-3 sentences of insightful feedback and actionable advice.
        
        Period: \(periodLabel)
        Days in Period: \(totalDays)
        Days with Logged Meals: \(daysWithMeals) (\(trackingRate)% tracking rate)
        Total Meals: \(totalMeals)
        
        Daily Averages:
        - Calories: \(avgCalories) kcal (\(avgPercent)% of \(targetCalories) kcal target)
        - Protein: \(avgProtein)g
        - Carbs: \(avgCarbs)g
        - Fat: \(avgFat)g
        
        User's Goal: \(goalDescription ?? "General health and wellness")
        
        Guidelines:
        - Analyze patterns and trends they should be aware of
        - Highlight what they're doing well (be specific)
        - Give one concrete, actionable suggestion for improvement
        - If tracking rate is low, encourage more consistent logging
        - Consider macro balance (protein for muscle, not just calories)
        - Use an emoji at the start
        - Be encouraging and insightful, not preachy
        
        Respond with just the feedback text, no JSON or markdown.
        """
        
        do {
            let response = try await model.generateContent(prompt)
            if let text = response.text {
                return cleanFeedbackResponse(text)
            }
            return "📊 Keep logging your meals consistently to get detailed insights about your eating patterns!"
        } catch {
            throw mapError(error)
        }
    }
    
    // MARK: - Error Handling Helper
    private func mapError(_ error: Error) -> GeminiError {
        // If it's already a GeminiError, return it
        if let geminiError = error as? GeminiError {
            return geminiError
        }
        
        let nsError = error as NSError
        let errorString = "\(error)"
        
        // 429 / Quota Detection
        let isRateLimit = nsError.code == 429 ||
                          nsError.localizedDescription.contains("429") ||
                          nsError.localizedDescription.contains("Resource exhausted") ||
                          nsError.localizedDescription.contains("quota") ||
                          errorString.contains("429") ||
                          errorString.contains("Resource exhausted")
        
        if isRateLimit {
            // Precise messaging for Quota vs Rate Limit
            if errorString.contains("PerDay") || errorString.contains("quota exceeded") {
                return .apiError("⚠️ Daily Limit Reached: You have used your AI usage quota for today. Please wait until tomorrow or upgrade your plan.")
            } else {
                return .apiError("⚠️ System Busy: Too many requests at once. Please try again in a few minutes.")
            }
        }
        
        // Network connectivity
        if nsError.domain == NSURLErrorDomain {
            return .apiError("⚠️ Network Error: Please check your internet connection and try again.")
        }
        
        // Other API errors
        return .apiError("⚠️ AI Service Error: \(nsError.localizedDescription)")
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
            return "Please provide text or an image to analyze."
        case .emptyResponse:
            return "The AI returned an empty response. Please try again."
        case .invalidJSON:
            return "Failed to process AI response. The data format was incorrect."
        case .apiError(let message):
            return message
        }
    }
}
