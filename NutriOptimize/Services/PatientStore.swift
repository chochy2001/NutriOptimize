import Foundation
import SwiftData
import SwiftUI

/// Persistent patient record backed by SwiftData.
/// Mirrors the `Patient` value type for local storage while keeping
/// the lightweight struct available for view-layer consumption.
@Model
final class PatientRecord {
    @Attribute(.unique) var patientId: UUID
    var fullName: String
    var age: Int
    var sex: String
    var weight: Double
    var height: Double
    var bodyFatPercentage: Double?
    var allergies: [String]
    var medicalConditions: [String]
    var dietaryPreferences: [String]
    var clinicalGoals: String
    var availableCookingTime: Int
    var activityLevel: String
    var monthlyFoodBudget: Double?
    var createdAt: Date
    var updatedAt: Date

    init(
        patientId: UUID = UUID(),
        fullName: String,
        age: Int,
        sex: String,
        weight: Double,
        height: Double,
        bodyFatPercentage: Double? = nil,
        allergies: [String] = [],
        medicalConditions: [String] = [],
        dietaryPreferences: [String] = [],
        clinicalGoals: String = "",
        availableCookingTime: Int = 30,
        activityLevel: String = Patient.ActivityLevel.sedentary.rawValue,
        monthlyFoodBudget: Double? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.patientId = patientId
        self.fullName = fullName
        self.age = age
        self.sex = sex
        self.weight = weight
        self.height = height
        self.bodyFatPercentage = bodyFatPercentage
        self.allergies = allergies
        self.medicalConditions = medicalConditions
        self.dietaryPreferences = dietaryPreferences
        self.clinicalGoals = clinicalGoals
        self.availableCookingTime = availableCookingTime
        self.activityLevel = activityLevel
        self.monthlyFoodBudget = monthlyFoodBudget
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Conversion

    /// Converts the persistent record into a lightweight value type for the view layer.
    func toPatient() -> Patient {
        Patient(
            id: patientId,
            fullName: fullName,
            age: age,
            sex: Patient.BiologicalSex(rawValue: sex) ?? .female,
            weight: weight,
            height: height,
            bodyFatPercentage: bodyFatPercentage,
            allergies: allergies,
            medicalConditions: medicalConditions,
            dietaryPreferences: dietaryPreferences,
            clinicalGoals: clinicalGoals,
            availableCookingTime: availableCookingTime,
            activityLevel: Patient.ActivityLevel(rawValue: activityLevel) ?? .sedentary,
            monthlyFoodBudget: monthlyFoodBudget
        )
    }

    /// Updates the record fields from a `Patient` value type.
    func update(from patient: Patient) {
        fullName = patient.fullName
        age = patient.age
        sex = patient.sex.rawValue
        weight = patient.weight
        height = patient.height
        bodyFatPercentage = patient.bodyFatPercentage
        allergies = patient.allergies
        medicalConditions = patient.medicalConditions
        dietaryPreferences = patient.dietaryPreferences
        clinicalGoals = patient.clinicalGoals
        availableCookingTime = patient.availableCookingTime
        activityLevel = patient.activityLevel.rawValue
        monthlyFoodBudget = patient.monthlyFoodBudget
        updatedAt = .now
    }

    /// Creates a new record from a `Patient` value type.
    static func from(_ patient: Patient) -> PatientRecord {
        PatientRecord(
            patientId: patient.id,
            fullName: patient.fullName,
            age: patient.age,
            sex: patient.sex.rawValue,
            weight: patient.weight,
            height: patient.height,
            bodyFatPercentage: patient.bodyFatPercentage,
            allergies: patient.allergies,
            medicalConditions: patient.medicalConditions,
            dietaryPreferences: patient.dietaryPreferences,
            clinicalGoals: patient.clinicalGoals,
            availableCookingTime: patient.availableCookingTime,
            activityLevel: patient.activityLevel.rawValue,
            monthlyFoodBudget: patient.monthlyFoodBudget
        )
    }
}

// MARK: - Patient Store

/// Provides CRUD operations for patient records using SwiftData.
/// Operates on the main actor to ensure safe model context access from SwiftUI views.
@MainActor
final class PatientStore: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Persists a new patient record derived from the given `Patient` value.
    func create(_ patient: Patient) throws {
        let record = PatientRecord.from(patient)
        modelContext.insert(record)
        try modelContext.save()
    }

    /// Retrieves all patient records sorted by creation date (newest first).
    func fetchAll() throws -> [Patient] {
        let descriptor = FetchDescriptor<PatientRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = try modelContext.fetch(descriptor)
        return records.map { $0.toPatient() }
    }

    /// Updates the stored record matching the given patient's ID.
    func update(_ patient: Patient) throws {
        let targetId = patient.id
        var descriptor = FetchDescriptor<PatientRecord>(
            predicate: #Predicate<PatientRecord> { $0.patientId == targetId }
        )
        descriptor.fetchLimit = 1
        guard let record = try modelContext.fetch(descriptor).first else {
            throw ServiceError.notFound
        }
        record.update(from: patient)
        try modelContext.save()
    }

    /// Removes the patient record with the specified ID from the store, together
    /// with ALL of the patient's clinical data: consultations, lab results,
    /// feedback, plan drafts, and progress-photo files on disk.
    ///
    /// These records are linked by raw `patientId` (no SwiftData relationships),
    /// so deleting the `PatientRecord` alone would orphan the rest. Cascading the
    /// cleanup here keeps deletion compliant with data-retention expectations for
    /// clinical data.
    func delete(patientId: UUID) throws {
        var descriptor = FetchDescriptor<PatientRecord>(
            predicate: #Predicate<PatientRecord> { $0.patientId == patientId }
        )
        descriptor.fetchLimit = 1
        guard let record = try modelContext.fetch(descriptor).first else {
            throw ServiceError.notFound
        }

        // Cascade: remove every linked clinical record for this patient.
        try modelContext.delete(model: ConsultationRecord.self, where: #Predicate { $0.patientId == patientId })
        try modelContext.delete(model: LabResultRecord.self, where: #Predicate { $0.patientId == patientId })
        try modelContext.delete(model: PatientFeedbackRecord.self, where: #Predicate { $0.patientId == patientId })
        try modelContext.delete(model: PlanDraftRecord.self, where: #Predicate { $0.patientId == patientId })

        modelContext.delete(record)
        try modelContext.save()

        // Cascade: remove the patient's progress-photo files from disk.
        Self.deleteProgressPhotos(for: patientId)
    }

    /// Deletes all progress-photo JPEGs stored under Documents/ProgressPhotos
    /// whose filename begins with the patient's full UUID string followed by an
    /// underscore (the `<uuid>_<timestamp>.jpg` convention used by
    /// `ProgressPhotoView`). The full UUID + underscore prefix is collision-safe.
    static func deleteProgressPhotos(for patientId: UUID) {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let documentsDir else { return }
        let photosDir = documentsDir.appendingPathComponent("ProgressPhotos", isDirectory: true)
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: photosDir.path) else { return }

        let prefix = patientId.uuidString + "_"
        for file in files where file.hasPrefix(prefix) {
            try? FileManager.default.removeItem(at: photosDir.appendingPathComponent(file))
        }
    }

    /// Checks whether any patient records exist in the store.
    func isEmpty() throws -> Bool {
        let descriptor = FetchDescriptor<PatientRecord>()
        let count = try modelContext.fetchCount(descriptor)
        return count == 0
    }

    /// Seeds the store with sample data if it is currently empty.
    /// Used only on first launch to provide demo patients.
    func seedIfEmpty() throws {
        guard try isEmpty() else { return }
        for patient in MockPatientService.samplePatients {
            let record = PatientRecord.from(patient)
            modelContext.insert(record)
        }
        try modelContext.save()
    }
}
