import Foundation
import Supabase
import UIKit

// MARK: - Gemini Service
/// Handles AI-powered meal analysis using Supabase Edge Functions
/// Migrated from direct GoogleGenerativeAI usage to "ai-service" Edge Function
actor GeminiService: GeminiServiceProtocol {
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - DTOs
    /// Generic Request structure for the Edge Function
    struct AIRequest<T: Encodable>: Encodable {
        let action: String
        let payload: T
    }
    
    /// Generic Response structure from the Edge Function
    struct AIResponse: Decodable {
        let data: String
    }
    
    // MARK: - Analyze Meal
    /// Analyze meal from text description and/or image via Supabase
    func analyzeMeal(text: String?, image: UIImage?) async throws -> MealAnalysis {
        guard text != nil || image != nil else {
            throw GeminiError.noInput
        }
        
        struct AnalyzePayload: Encodable {
            let text: String?
            let imageBase64: String?
        }
        
        // Convert image to Base64
        let imageBase64 = image?.jpegData(compressionQuality: 0.8)?.base64EncodedString()
        let payload = AnalyzePayload(text: text, imageBase64: imageBase64)
        
        return try await invokeAI(action: "analyzeMeal", payload: payload, decoding: MealAnalysis.self)
    }
    
    // MARK: - Generate Recommendations
    /// Generate meal recommendations based on user context
    func generateRecommendations(
        targetCalories: Int,
        recentAvgCalories: Int,
        goal: String?,
        preferences: [String]?
    ) async throws -> [Recommendation] {
        
        struct RecommendPayload: Encodable {
            let targetCalories: Int
            let recentAvgCalories: Int
            let goal: String?
            let preferences: [String]?
        }
        
        let payload = RecommendPayload(
            targetCalories: targetCalories,
            recentAvgCalories: recentAvgCalories,
            goal: goal,
            preferences: preferences
        )
        
        return try await invokeAI(action: "recommend", payload: payload, decoding: [Recommendation].self)
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
        
        struct DayPlanPayload: Encodable {
            let targetCalories: Int
            let consumedCalories: Int
            let eatenMealTypes: [String]
            let remainingMealTypes: [String]
            let goal: String?
            let preferences: [String]?
        }
        
        let payload = DayPlanPayload(
            targetCalories: targetCalories,
            consumedCalories: consumedCalories,
            eatenMealTypes: eatenMealTypes,
            remainingMealTypes: remainingMealTypes,
            goal: goal,
            preferences: preferences
        )
        
        // Custom decoding for the tuple
        struct DayPlanResponse: Codable {
            var dayPlan: [DayPlanMeal]
            var summary: DayPlanSummary
        }
        
        let response = try await invokeAI(action: "dayPlan", payload: payload, decoding: DayPlanResponse.self)
        return (response.dayPlan, response.summary)
    }
    
    // MARK: - Generate AI Feedback
    /// Generate personalized feedback based on daily progress
    func generateFeedback(
        todayCalories: Int,
        weeklyAvgCalories: Int,
        targetCalories: Int,
        goal: String?
    ) async throws -> String {
        
        let todayPercent = targetCalories > 0 ? Int(round(Double(todayCalories) / Double(targetCalories) * 100)) : 0
        let weeklyPercent = targetCalories > 0 ? Int(round(Double(weeklyAvgCalories) / Double(targetCalories) * 100)) : 0
        
        struct FeedbackPayload: Encodable {
            let todayCalories: Int
            let weeklyAvgCalories: Int
            let targetCalories: Int
            let goal: String?
            let todayPercent: Int
            let weeklyPercent: Int
        }
        
        let payload = FeedbackPayload(
            todayCalories: todayCalories,
            weeklyAvgCalories: weeklyAvgCalories,
            targetCalories: targetCalories,
            goal: goal,
            todayPercent: todayPercent,
            weeklyPercent: weeklyPercent
        )
        
        return try await invokeAI(action: "feedback", payload: payload)
    }
    
    // MARK: - Generate Statistics Insight
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
        
        struct StatsPayload: Encodable {
            let periodLabel: String
            let totalDays: Int
            let daysWithMeals: Int
            let totalMeals: Int
            let avgCalories: Int
            let avgProtein: Int
            let avgCarbs: Int
            let avgFat: Int
            let targetCalories: Int
            let goalDescription: String?
            let avgPercent: Int
            let trackingRate: Int
        }
        
        let payload = StatsPayload(
            periodLabel: periodLabel,
            totalDays: totalDays,
            daysWithMeals: daysWithMeals,
            totalMeals: totalMeals,
            avgCalories: avgCalories,
            avgProtein: avgProtein,
            avgCarbs: avgCarbs,
            avgFat: avgFat,
            targetCalories: targetCalories,
            goalDescription: goalDescription,
            avgPercent: avgPercent,
            trackingRate: trackingRate
        )
        
        return try await invokeAI(action: "stats", payload: payload)
    }
    
    // MARK: - Helper Methods
    
    /// Generic method to invoke Supabase Edge Function and return String data
    private func invokeAI<T: Encodable>(action: String, payload: T) async throws -> String {
        let request = AIRequest(action: action, payload: payload)
        
        do {
            // Fix: Explicitly specify AIResponse type to trigger the generic 'decode' overload
            let response: AIResponse = try await supabase.functions
                .invoke("ai-service", options: FunctionInvokeOptions(body: request))
            
            return response.data
        } catch {
            throw mapError(error)
        }
    }
    
    /// Generic method to invoke Supabase Edge Function and decode JSON result
    private func invokeAI<T: Encodable, U: Decodable>(action: String, payload: T, decoding type: U.Type) async throws -> U {
        let jsonString = try await invokeAI(action: action, payload: payload)
        
        // Proactively clean the JSON string to remove Markdown code blocks
        let cleanedJSON = cleanJSON(jsonString)
        
        guard let data = cleanedJSON.data(using: .utf8) else {
            throw GeminiError.invalidJSON
        }
        
        do {
            return try JSONDecoder().decode(U.self, from: data)
        } catch {
            print("🤖 Supabase JSON Decode Error: \(error)")
            print("📝 Raw Response: \(jsonString)")
            throw GeminiError.invalidJSON
        }
    }
    
    /// Clean JSON string (removes Markdown formatting and extracts JSON object/array)
    internal func cleanJSON(_ text: String) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown backticks if present (e.g., ```json ... ```)
        // We simply filter out lines starting with ``` for a safer approach,
        // or just rely on finding the first valid JSON character.
        
        // Find the first occurrence of '{' or '['
        let firstBrace = cleaned.firstIndex(of: "{")
        let firstBracket = cleaned.firstIndex(of: "[")
        
        // Determine start index (whichever comes first)
        var startIndex: String.Index?
        var endIndex: String.Index?
        
        if let brace = firstBrace, let bracket = firstBracket {
            startIndex = brace < bracket ? brace : bracket
        } else {
            startIndex = firstBrace ?? firstBracket
        }
        
        guard let start = startIndex else { return cleaned }
        
        // Determine matching end character based on start
        let isObject = cleaned[start] == "{"
        
        if isObject {
            endIndex = cleaned.lastIndex(of: "}")
        } else {
            endIndex = cleaned.lastIndex(of: "]")
        }
        
        guard let end = endIndex, start <= end else { return cleaned }
        
        return String(cleaned[start...end])
    }
    
    // MARK: - Error Handling Helper
    private func mapError(_ error: Error) -> GeminiError {
        // If it's already a GeminiError, return it
        if let geminiError = error as? GeminiError {
            return geminiError
        }
        
        let nsError = error as NSError
        print("🤖 Supabase Error: \(nsError)")
        
        // Functions specific errors domain often appears as FunctionsError or similar in Supabase Swfit
        // But we check generic descriptions too
        let description = nsError.localizedDescription
        
        if description.contains("Functions") || nsError.domain.contains("Supabase") {
            return .apiError("⚠️ AI Service Error: Connection to backend failed.")
        }
        
        // Network connectivity
        if nsError.domain == NSURLErrorDomain {
            return .apiError("⚠️ Network Error: Please check your internet connection.")
        }
        
        return .apiError("⚠️ AI Service Error: \(description)")
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
