import XCTest
import SwiftData
@testable import NutriOptimize

/// Verifies that deleting a patient cascades to all linked clinical records so
/// no orphaned consultations, labs, feedback, or drafts are left behind.
@MainActor
final class PatientStoreCascadeTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PatientRecord.self,
            PatientFeedbackRecord.self,
            ConsultationRecord.self,
            LabResultRecord.self,
            PlanDraftRecord.self,
            configurations: config
        )
        return ModelContext(container)
    }

    private func samplePatient(id: UUID = UUID()) -> Patient {
        Patient(
            id: id,
            fullName: "Test Patient",
            age: 40, sex: .male, weight: 80, height: 175,
            bodyFatPercentage: nil, allergies: [], medicalConditions: [],
            dietaryPreferences: [], clinicalGoals: "Test",
            availableCookingTime: 30, activityLevel: .sedentary
        )
    }

    func testDeleteCascadesAllClinicalRecords() throws {
        let context = try makeContext()
        let store = PatientStore(modelContext: context)

        let patientId = UUID()
        try store.create(samplePatient(id: patientId))

        // Seed one of each linked record type for this patient.
        context.insert(ConsultationRecord(patientId: patientId, weight: 80,
                                          totalCaloriesPrescribed: 2000, totalProtein: 100,
                                          totalCarbs: 200, totalFat: 60, planSummary: "x"))
        context.insert(LabResultRecord(patientId: patientId, testDate: .now,
                                       testName: "Glucosa", value: 90, unit: "mg/dL",
                                       referenceRange: "70-99"))
        context.insert(PatientFeedbackRecord(patientId: patientId, likedFoods: ["Pollo"]))
        let draft = PlanOptimizationDraft(
            id: UUID(), patientId: patientId, status: .pendingReview,
            calculatedRationale: "x",
            meals: [Meal(type: .breakfast, name: "x", ingredients: ["a"], macros: Macros(protein: 1, carbohydrates: 1, fat: 1))],
            createdAt: .now
        )
        context.insert(PlanDraftRecord(from: draft))
        try context.save()

        // Sanity: records exist before deletion.
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ConsultationRecord>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<LabResultRecord>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PatientFeedbackRecord>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanDraftRecord>()), 1)

        try store.delete(patientId: patientId)

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PatientRecord>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ConsultationRecord>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<LabResultRecord>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PatientFeedbackRecord>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanDraftRecord>()), 0)
    }

    func testDeleteOnlyRemovesTargetPatientsRecords() throws {
        let context = try makeContext()
        let store = PatientStore(modelContext: context)

        let keepId = UUID()
        let removeId = UUID()
        try store.create(samplePatient(id: keepId))
        try store.create(samplePatient(id: removeId))

        context.insert(ConsultationRecord(patientId: keepId, weight: 70,
                                          totalCaloriesPrescribed: 1800, totalProtein: 90,
                                          totalCarbs: 180, totalFat: 50, planSummary: "keep"))
        context.insert(ConsultationRecord(patientId: removeId, weight: 90,
                                          totalCaloriesPrescribed: 2200, totalProtein: 110,
                                          totalCarbs: 220, totalFat: 70, planSummary: "remove"))
        try context.save()

        try store.delete(patientId: removeId)

        let remaining = try context.fetch(FetchDescriptor<ConsultationRecord>())
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.patientId, keepId)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PatientRecord>()), 1)
    }
}
