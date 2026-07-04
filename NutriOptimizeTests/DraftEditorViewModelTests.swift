import XCTest
import SwiftData
@testable import NutriOptimize

/// Covers the clinical-history lifecycle of `DraftEditorViewModel`: meal editing,
/// approval that persists a `ConsultationRecord`, the guard against approving a
/// draft whose patient was deleted, and the pending-review upsert. Uses an
/// in-memory SwiftData container and the real `MockOptimizationService`.
@MainActor
final class DraftEditorViewModelTests: XCTestCase {

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

    private func makeDraft(patientId: UUID = UUID()) -> PlanOptimizationDraft {
        PlanOptimizationDraft(
            id: UUID(),
            patientId: patientId,
            status: .pendingReview,
            calculatedRationale: "Rationale de prueba",
            meals: [
                Meal(type: .dinner, name: "Cena", ingredients: ["Salmón"],
                     macros: Macros(protein: 30, carbohydrates: 10, fat: 20)),
                Meal(type: .breakfast, name: "Desayuno", ingredients: ["Avena"],
                     macros: Macros(protein: 12, carbohydrates: 40, fat: 8))
            ],
            createdAt: .now
        )
    }

    private func seedPatient(_ context: ModelContext, id: UUID) throws {
        let store = PatientStore(modelContext: context)
        try store.create(Patient(
            id: id, fullName: "Paciente Prueba", age: 40, sex: .male,
            weight: 80, height: 175, bodyFatPercentage: nil, allergies: [],
            medicalConditions: [], dietaryPreferences: [], clinicalGoals: "Test",
            availableCookingTime: 30, activityLevel: .sedentary
        ))
    }

    // MARK: - Meal editing

    func testAddUpdateDeleteMeal() {
        let vm = DraftEditorViewModel(draft: makeDraft(), patientName: "X")
        let originalCount = vm.draft.meals.count

        let newMeal = Meal(type: .snack, name: "Snack", ingredients: ["Manzana"],
                           macros: Macros(protein: 1, carbohydrates: 20, fat: 0))
        vm.addMeal(newMeal)
        XCTAssertEqual(vm.draft.meals.count, originalCount + 1)

        var edited = newMeal
        edited.name = "Snack editado"
        vm.updateMeal(edited)
        XCTAssertEqual(vm.draft.meals.first(where: { $0.id == newMeal.id })?.name, "Snack editado")

        vm.deleteMeal(newMeal)
        XCTAssertEqual(vm.draft.meals.count, originalCount)
        XCTAssertNil(vm.draft.meals.first(where: { $0.id == newMeal.id }))
    }

    func testUpdateUnknownMealIsNoOp() {
        let vm = DraftEditorViewModel(draft: makeDraft(), patientName: "X")
        let snapshot = vm.draft.meals.map(\.id)
        vm.updateMeal(Meal(type: .lunch, name: "Ghost", ingredients: [],
                           macros: Macros(protein: 0, carbohydrates: 0, fat: 0)))
        XCTAssertEqual(vm.draft.meals.map(\.id), snapshot, "Updating an unknown meal id must not mutate the list")
    }

    // MARK: - Approval persists a consultation

    func testApproveDraftPersistsConsultationRecord() async throws {
        let context = try makeContext()
        let patientId = UUID()
        try seedPatient(context, id: patientId)

        let draft = makeDraft(patientId: patientId)
        let vm = DraftEditorViewModel(draft: draft, patientName: "Paciente Prueba")
        vm.modelContext = context

        await vm.approveDraft(patientWeight: 82)

        XCTAssertTrue(vm.wasApproved)
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.draft.status, .approved)

        let records = try context.fetch(FetchDescriptor<ConsultationRecord>())
        XCTAssertEqual(records.count, 1)
        let record = try XCTUnwrap(records.first)
        XCTAssertEqual(record.patientId, patientId)
        XCTAssertEqual(record.weight, 82)
        XCTAssertEqual(record.totalCaloriesPrescribed, draft.totalCalories, accuracy: 0.001)
        XCTAssertEqual(record.totalProtein, draft.totalProtein, accuracy: 0.001)
        // Plan summary must be ordered breakfast before dinner (sortOrder).
        XCTAssertEqual(record.planSummary, "Desayuno, Cena")
        XCTAssertEqual(record.clinicalNotes, "Rationale de prueba")
    }

    func testApproveDraftDefaultsWeightToZeroWhenNil() async throws {
        let context = try makeContext()
        let patientId = UUID()
        try seedPatient(context, id: patientId)

        let vm = DraftEditorViewModel(draft: makeDraft(patientId: patientId), patientName: "Paciente Prueba")
        vm.modelContext = context

        await vm.approveDraft(patientWeight: nil)

        let record = try XCTUnwrap(try context.fetch(FetchDescriptor<ConsultationRecord>()).first)
        XCTAssertEqual(record.weight, 0, "A nil patient weight persists as 0")
    }

    func testApproveDraftRemovesPendingRecord() async throws {
        let context = try makeContext()
        let patientId = UUID()
        try seedPatient(context, id: patientId)

        let draft = makeDraft(patientId: patientId)
        // Pre-seed a pending record for this draft.
        context.insert(PlanDraftRecord(from: draft))
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanDraftRecord>()), 1)

        let vm = DraftEditorViewModel(draft: draft, patientName: "Paciente Prueba")
        vm.modelContext = context
        await vm.approveDraft(patientWeight: 80)

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanDraftRecord>()), 0,
                       "Approving a draft must clear its pending-review record")
    }

    // MARK: - Guard: patient no longer exists

    func testApproveDraftBlockedWhenPatientDeleted() async throws {
        let context = try makeContext()
        // Note: NO patient seeded, so the guard must trip.
        let vm = DraftEditorViewModel(draft: makeDraft(patientId: UUID()), patientName: "Fantasma")
        vm.modelContext = context

        await vm.approveDraft(patientWeight: 80)

        XCTAssertFalse(vm.wasApproved, "Approval must be refused for a deleted patient")
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ConsultationRecord>()), 0,
                       "No orphaned consultation may be persisted")
        XCTAssertFalse(vm.isProcessing)
    }

    // MARK: - saveToPendingReview upsert

    func testSaveToPendingReviewInsertsThenUpdatesInPlace() async throws {
        let context = try makeContext()
        var draft = makeDraft()
        let vm = DraftEditorViewModel(draft: draft, patientName: "X")
        vm.modelContext = context

        // First save inserts a record.
        await vm.saveToPendingReview()
        XCTAssertTrue(vm.wasSavedToPending)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanDraftRecord>()), 1)

        // Mutate the draft and save again: must UPDATE the same row, not insert.
        draft.meals.append(Meal(type: .lunch, name: "Comida nueva", ingredients: ["Pollo"],
                                macros: Macros(protein: 40, carbohydrates: 30, fat: 10)))
        vm.draft = draft
        await vm.saveToPendingReview()

        let records = try context.fetch(FetchDescriptor<PlanDraftRecord>())
        XCTAssertEqual(records.count, 1, "Second save must upsert, not duplicate")
        XCTAssertEqual(records.first?.toDraft().meals.count, 3,
                       "The updated row must carry the edited meals")
    }

    func testSaveToPendingReviewWithoutContextSetsError() async {
        let vm = DraftEditorViewModel(draft: makeDraft(), patientName: "X")
        vm.modelContext = nil
        await vm.saveToPendingReview()
        XCTAssertFalse(vm.wasSavedToPending)
        XCTAssertEqual(vm.errorMessage, "No se pudo guardar el borrador")
    }

    // MARK: - discard

    func testDiscardDraftRemovesPendingRecord() async throws {
        let context = try makeContext()
        let draft = makeDraft()
        context.insert(PlanDraftRecord(from: draft))
        try context.save()

        let vm = DraftEditorViewModel(draft: draft, patientName: "X")
        vm.modelContext = context
        await vm.discardDraft()

        XCTAssertTrue(vm.wasDiscarded)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanDraftRecord>()), 0)
    }
}
