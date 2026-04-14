import XCTest
@testable import NutriOptimize

final class MockOptimizationServiceTests: XCTestCase {

    private let service = MockOptimizationService()

    private var samplePatient: Patient {
        Patient(
            id: UUID(),
            fullName: "Test Patient",
            age: 30,
            sex: .male,
            weight: 75.0,
            height: 175.0,
            bodyFatPercentage: 20,
            allergies: ["Mariscos"],
            medicalConditions: ["Hipertensión"],
            dietaryPreferences: ["Pollo", "Arroz"],
            clinicalGoals: "Pérdida de peso gradual",
            availableCookingTime: 30,
            activityLevel: .moderatelyActive,
            monthlyFoodBudget: 5000
        )
    }

    // MARK: - Generate Draft

    func testGenerateDraftReturnsValidDraft() async throws {
        let draft = try await service.generateDraft(for: samplePatient)
        XCTAssertNotNil(draft)
        XCTAssertFalse(draft.calculatedRationale.isEmpty)
        XCTAssertFalse(draft.meals.isEmpty)
    }

    func testGenerateDraftHasCorrectPatientId() async throws {
        let patient = samplePatient
        let draft = try await service.generateDraft(for: patient)
        XCTAssertEqual(draft.patientId, patient.id)
        XCTAssertNotNil(draft.patientId)
        XCTAssertNotEqual(draft.id, patient.id)
    }

    func testGenerateDraftStatusIsPendingReview() async throws {
        let draft = try await service.generateDraft(for: samplePatient)
        XCTAssertEqual(draft.status, .pendingReview)
        XCTAssertNotEqual(draft.status, .approved)
        XCTAssertNotEqual(draft.status, .discarded)
    }

    func testGenerateDraftMealsArrayIsNotEmpty() async throws {
        let draft = try await service.generateDraft(for: samplePatient)
        XCTAssertFalse(draft.meals.isEmpty)
        XCTAssertGreaterThanOrEqual(draft.meals.count, 4)
        XCTAssertTrue(draft.meals.count >= 1)
    }

    func testGenerateDraftHasAllMealTypes() async throws {
        let draft = try await service.generateDraft(for: samplePatient)
        let types = Set(draft.meals.map(\.type))
        XCTAssertTrue(types.contains(.breakfast))
        XCTAssertTrue(types.contains(.lunch))
        XCTAssertTrue(types.contains(.dinner))
    }

    func testGenerateDraftRationaleIncludesTDEE() async throws {
        let draft = try await service.generateDraft(for: samplePatient)
        XCTAssertTrue(draft.calculatedRationale.contains("TDEE"))
        XCTAssertTrue(draft.calculatedRationale.contains("kcal"))
        XCTAssertFalse(draft.calculatedRationale.isEmpty)
    }

    func testGenerateDraftMealsHaveMacros() async throws {
        let draft = try await service.generateDraft(for: samplePatient)
        for meal in draft.meals {
            XCTAssertGreaterThan(meal.macros.totalCalories, 0)
            XCTAssertGreaterThan(meal.macros.protein, 0)
            XCTAssertFalse(meal.name.isEmpty)
        }
    }

    // MARK: - Approve Draft

    func testApproveDraftChangesStatus() async throws {
        let draft = try await service.generateDraft(for: samplePatient)
        XCTAssertEqual(draft.status, .pendingReview)

        let approved = try await service.approveDraft(draft)
        XCTAssertEqual(approved.status, .approved)
        XCTAssertEqual(approved.patientId, draft.patientId)
    }

    func testApproveDraftPreservesMeals() async throws {
        let draft = try await service.generateDraft(for: samplePatient)
        let approved = try await service.approveDraft(draft)
        XCTAssertEqual(approved.meals.count, draft.meals.count)
        XCTAssertEqual(approved.calculatedRationale, draft.calculatedRationale)
        XCTAssertEqual(approved.totalCalories, draft.totalCalories, accuracy: 0.01)
    }

    // MARK: - Fetch Pending Drafts

    func testFetchPendingDraftsReturnsData() async throws {
        let drafts = try await service.fetchPendingDrafts()
        XCTAssertFalse(drafts.isEmpty)
        XCTAssertGreaterThanOrEqual(drafts.count, 1)
        XCTAssertTrue(drafts.allSatisfy { $0.status == .pendingReview })
    }

    func testFetchPendingDraftsAllPending() async throws {
        let drafts = try await service.fetchPendingDrafts()
        for draft in drafts {
            XCTAssertEqual(draft.status, .pendingReview)
            XCTAssertFalse(draft.meals.isEmpty)
            XCTAssertFalse(draft.calculatedRationale.isEmpty)
        }
    }

    func testFetchPendingDraftsHaveValidDates() async throws {
        let drafts = try await service.fetchPendingDrafts()
        for draft in drafts {
            XCTAssertLessThanOrEqual(draft.createdAt, Date.now)
            XCTAssertNotNil(draft.createdAt)
            XCTAssertNotNil(draft.id)
        }
    }

    // MARK: - Discard Draft

    func testDiscardDraftDoesNotThrow() async throws {
        let draft = try await service.generateDraft(for: samplePatient)
        do {
            try await service.discardDraft(draft)
            XCTAssertTrue(true, "discardDraft completed without error")
        } catch {
            XCTFail("discardDraft should not throw, but threw: \(error)")
        }
        XCTAssertEqual(draft.status, .pendingReview)
        XCTAssertFalse(draft.meals.isEmpty)
    }
}
