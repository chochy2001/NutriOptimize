import Foundation
import SwiftData

/// Stores the nutritionist's feedback on specific foods and recommendations.
/// This data feeds back into the optimization engine to improve future suggestions.
@Model
final class PatientFeedbackRecord {
    @Attribute(.unique) var patientId: UUID
    var likedFoods: [String]
    var dislikedFoods: [String]
    var bannedFoods: [String]
    var generalNotes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        patientId: UUID,
        likedFoods: [String] = [],
        dislikedFoods: [String] = [],
        bannedFoods: [String] = [],
        generalNotes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.patientId = patientId
        self.likedFoods = likedFoods
        self.dislikedFoods = dislikedFoods
        self.bannedFoods = bannedFoods
        self.generalNotes = generalNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
