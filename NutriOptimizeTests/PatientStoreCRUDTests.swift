import XCTest
import SwiftData
@testable import NutriOptimize

/// Covers the non-delete CRUD surface of `PatientStore` (create/fetchAll/update/
/// isEmpty/seedIfEmpty) and the `PatientRecord` <-> `Patient` conversion, none of
/// which were exercised before (cascade delete already had its own suite).
@MainActor
final class PatientStoreCRUDTests: XCTestCase {

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

    private func patient(
        id: UUID = UUID(),
        name: String = "Ana López",
        sex: Patient.BiologicalSex = .female,
        activity: Patient.ActivityLevel = .moderatelyActive
    ) -> Patient {
        Patient(
            id: id, fullName: name, age: 35, sex: sex, weight: 68, height: 165,
            bodyFatPercentage: 24, allergies: ["Lactosa"], medicalConditions: ["Hipotiroidismo"],
            dietaryPreferences: ["Vegetariana"], clinicalGoals: "Pérdida de grasa",
            availableCookingTime: 45, activityLevel: activity, monthlyFoodBudget: 4000
        )
    }

    // MARK: - isEmpty / create / fetchAll

    func testIsEmptyOnFreshStore() throws {
        let store = PatientStore(modelContext: try makeContext())
        XCTAssertTrue(try store.isEmpty())
    }

    func testCreateThenFetchAllReturnsPatient() throws {
        let store = PatientStore(modelContext: try makeContext())
        let p = patient()
        try store.create(p)

        XCTAssertFalse(try store.isEmpty())
        let all = try store.fetchAll()
        XCTAssertEqual(all.count, 1)
        let fetched = try XCTUnwrap(all.first)
        XCTAssertEqual(fetched.id, p.id)
        XCTAssertEqual(fetched.fullName, "Ana López")
        XCTAssertEqual(fetched.allergies, ["Lactosa"])
        XCTAssertEqual(fetched.medicalConditions, ["Hipotiroidismo"])
        XCTAssertEqual(fetched.activityLevel, .moderatelyActive)
        XCTAssertEqual(fetched.monthlyFoodBudget, 4000)
    }

    func testFetchAllSortedByCreatedAtDescending() throws {
        let context = try makeContext()
        let store = PatientStore(modelContext: context)

        // Insert two records with explicit createdAt to assert ordering.
        let older = PatientRecord(fullName: "Older", age: 30, sex: "Femenino",
                                  weight: 60, height: 160,
                                  createdAt: Date(timeIntervalSince1970: 1_000))
        let newer = PatientRecord(fullName: "Newer", age: 30, sex: "Femenino",
                                  weight: 60, height: 160,
                                  createdAt: Date(timeIntervalSince1970: 2_000))
        context.insert(older)
        context.insert(newer)
        try context.save()

        let all = try store.fetchAll()
        XCTAssertEqual(all.map(\.fullName), ["Newer", "Older"])
    }

    // MARK: - update

    func testUpdatePersistsNewValues() throws {
        let store = PatientStore(modelContext: try makeContext())
        let id = UUID()
        try store.create(patient(id: id, name: "Original"))

        var updated = patient(id: id, name: "Actualizado")
        updated.weight = 72
        updated.clinicalGoals = "Mantenimiento"
        updated.allergies = ["Gluten", "Nueces"]
        try store.update(updated)

        let fetched = try XCTUnwrap(try store.fetchAll().first)
        XCTAssertEqual(fetched.fullName, "Actualizado")
        XCTAssertEqual(fetched.weight, 72)
        XCTAssertEqual(fetched.clinicalGoals, "Mantenimiento")
        XCTAssertEqual(fetched.allergies, ["Gluten", "Nueces"])
        XCTAssertEqual(try store.fetchAll().count, 1, "Update must not create a duplicate")
    }

    func testUpdateMissingPatientThrowsNotFound() throws {
        let store = PatientStore(modelContext: try makeContext())
        XCTAssertThrowsError(try store.update(patient())) { error in
            XCTAssertEqual(error as? ServiceError, .notFound)
        }
    }

    // MARK: - seedIfEmpty

    func testSeedIfEmptyPopulatesSampleData() throws {
        let store = PatientStore(modelContext: try makeContext())
        try store.seedIfEmpty()

        let seeded = try store.fetchAll()
        XCTAssertFalse(seeded.isEmpty, "Seeding must add the sample patients")
        XCTAssertEqual(seeded.count, MockPatientService.samplePatients.count)
    }

    func testSeedIfEmptyIsNoOpWhenAlreadyPopulated() throws {
        let store = PatientStore(modelContext: try makeContext())
        try store.create(patient())
        try store.seedIfEmpty()

        XCTAssertEqual(try store.fetchAll().count, 1,
                       "Seeding must not run when the store already has data")
    }

    // MARK: - PatientRecord conversion

    func testToPatientRoundTripPreservesFields() {
        let source = patient(name: "Round Trip", sex: .male, activity: .athlete)
        let record = PatientRecord.from(source)
        let back = record.toPatient()

        XCTAssertEqual(back.id, source.id)
        XCTAssertEqual(back.fullName, source.fullName)
        XCTAssertEqual(back.sex, .male)
        XCTAssertEqual(back.activityLevel, .athlete)
        XCTAssertEqual(back.dietaryPreferences, source.dietaryPreferences)
        XCTAssertEqual(back.monthlyFoodBudget, source.monthlyFoodBudget)
    }

    func testToPatientFallsBackOnInvalidRawValues() {
        // A record with corrupt enum strings must fall back to sane defaults
        // rather than crash: sex -> .female, activityLevel -> .sedentary.
        let record = PatientRecord(fullName: "Corrupt", age: 50,
                                   sex: "NOT_A_SEX", weight: 80, height: 180,
                                   activityLevel: "NOT_A_LEVEL")
        let patient = record.toPatient()
        XCTAssertEqual(patient.sex, .female)
        XCTAssertEqual(patient.activityLevel, .sedentary)
    }

    func testUpdateFromPatientMutatesRecordAndBumpsTimestamp() {
        let record = PatientRecord(fullName: "Before", age: 30, sex: "Femenino",
                                   weight: 60, height: 160,
                                   updatedAt: Date(timeIntervalSince1970: 0))
        var newValues = patient(id: record.patientId, name: "After", sex: .male)
        newValues.weight = 90
        record.update(from: newValues)

        XCTAssertEqual(record.fullName, "After")
        XCTAssertEqual(record.sex, "Masculino")
        XCTAssertEqual(record.weight, 90)
        XCTAssertGreaterThan(record.updatedAt.timeIntervalSince1970, 0,
                             "update(from:) must refresh updatedAt")
    }
}
