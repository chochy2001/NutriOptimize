import Foundation
import SwiftData

/// Represents a completed nutrition consultation with its approved plan snapshot.
/// Used to track patient progress and build a timeline of interventions.
@Model
final class ConsultationRecord {
    var id: UUID
    var patientId: UUID
    var date: Date
    var weight: Double
    var bodyFatPercentage: Double?
    var waistCircumference: Double?
    var hipCircumference: Double?
    var armCircumference: Double?
    var totalCaloriesPrescribed: Double
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
    var planSummary: String
    var clinicalNotes: String
    var progressPhotoPath: String?

    init(patientId: UUID, date: Date = .now, weight: Double, bodyFatPercentage: Double? = nil,
         waistCircumference: Double? = nil, hipCircumference: Double? = nil, armCircumference: Double? = nil,
         totalCaloriesPrescribed: Double, totalProtein: Double, totalCarbs: Double, totalFat: Double,
         planSummary: String, clinicalNotes: String = "", progressPhotoPath: String? = nil) {
        self.id = UUID()
        self.patientId = patientId
        self.date = date
        self.weight = weight
        self.bodyFatPercentage = bodyFatPercentage
        self.waistCircumference = waistCircumference
        self.hipCircumference = hipCircumference
        self.armCircumference = armCircumference
        self.totalCaloriesPrescribed = totalCaloriesPrescribed
        self.totalProtein = totalProtein
        self.totalCarbs = totalCarbs
        self.totalFat = totalFat
        self.planSummary = planSummary
        self.clinicalNotes = clinicalNotes
        self.progressPhotoPath = progressPhotoPath
    }
}
