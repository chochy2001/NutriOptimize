import Foundation
import SwiftData

/// Stores laboratory test results linked to a patient.
/// Common tests nutritionists review: glucose, lipid panel, thyroid, etc.
@Model
final class LabResultRecord {
    var id: UUID
    var patientId: UUID
    var testDate: Date
    var testName: String
    var value: Double
    var unit: String
    var referenceRange: String
    var isOutOfRange: Bool
    var notes: String

    init(patientId: UUID, testDate: Date, testName: String, value: Double,
         unit: String, referenceRange: String, isOutOfRange: Bool = false, notes: String = "") {
        self.id = UUID()
        self.patientId = patientId
        self.testDate = testDate
        self.testName = testName
        self.value = value
        self.unit = unit
        self.referenceRange = referenceRange
        self.isOutOfRange = isOutOfRange
        self.notes = notes
    }
}
