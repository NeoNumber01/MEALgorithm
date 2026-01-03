import Foundation
import SwiftData

// MARK: - SwiftData Meal Model
/// Offline-first representation of a Meal
@Model
final class SDMeal {
    // Primary Key
    @Attribute(.unique) var id: UUID
    
    // Core Data
    var userId: UUID
    var imagePath: String?
    var textContent: String?
    
    // Storing complex objects as Data (JSON) for robustness V1
    var analysisData: Data?
    
    var mealTypeRaw: String?
    var createdAt: Date
    
    // Sync Metadata
    var syncStatusRaw: String // "synced", "pending", "failed"
    var lastModified: Date
    var syncErrorMessage: String?
    
    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
    
    var mealType: MealType? {
        get { mealTypeRaw.flatMap { MealType(rawValue: $0) } }
        set { mealTypeRaw = newValue?.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        imagePath: String? = nil,
        textContent: String? = nil,
        analysis: MealAnalysis? = nil,
        mealType: MealType? = nil,
        createdAt: Date = Date(),
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.userId = userId
        self.imagePath = imagePath
        self.textContent = textContent
        self.mealTypeRaw = mealType?.rawValue
        self.createdAt = createdAt
        self.syncStatusRaw = syncStatus.rawValue
        self.lastModified = Date()
        
        if let analysis = analysis {
            self.analysisData = try? JSONEncoder().encode(analysis)
        }
    }
    
    /// Convert back to domain model
    func toDomain() -> Meal? {
        var analysis: MealAnalysis? = nil
        if let data = analysisData {
            analysis = try? JSONDecoder().decode(MealAnalysis.self, from: data)
        }
        
        return Meal(
            id: id,
            userId: userId,
            imagePath: imagePath,
            textContent: textContent,
            analysis: analysis,
            mealType: mealType,
            createdAt: createdAt
        )
    }
}

// MARK: - Sync Status
enum SyncStatus: String, Codable {
    case synced
    case pending
    case failed
}
