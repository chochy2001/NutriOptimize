import XCTest
import SwiftData
@testable import NutriOptimize

/// Covers the clinical-history lifecycle of `DraftEditorViewModel`: meal editing,
/// approval that persists a `ConsultationRecord`, the guard against approving a
/// draft whose patient was deleted, the pending-review upsert, and single-flight
/// re-entrancy guards across `DraftEditorViewModel` and `PatientDetailViewModel`.
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

    private func makeSamplePatient(id: UUID = UUID()) -> Patient {
        Patient(
            id: id, fullName: "Paciente Prueba", age: 40, sex: .male,
            weight: 80, height: 175, bodyFatPercentage: nil, allergies: [],
            medicalConditions: [], dietaryPreferences: [], clinicalGoals: "Test",
            availableCookingTime: 30, activityLevel: .sedentary
        )
    }

    private func seedPatient(_ context: ModelContext, id: UUID) throws {
        let store = PatientStore(modelContext: context)
        try store.create(makeSamplePatient(id: id))
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

    // MARK: - Single-flight re-entrancy guards

    func testApproveDraftIgnoresConcurrentAndPostApprovalCalls() async throws {
        let context = try makeContext()
        let patientId = UUID()
        try seedPatient(context, id: patientId)

        let service = CountingOptimizationService()
        let vm = DraftEditorViewModel(
            draft: makeDraft(patientId: patientId),
            patientName: "Paciente Prueba",
            optimizationService: service
        )
        vm.modelContext = context

        async let first: Void = vm.approveDraft(patientWeight: 80)
        async let second: Void = vm.approveDraft(patientWeight: 80)
        _ = await (first, second)

        // A third call after approval must also be ignored.
        await vm.approveDraft(patientWeight: 80)

        let calls = await service.approveCount
        XCTAssertEqual(calls, 1, "Concurrent and post-approval approveDraft calls must execute only once")
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ConsultationRecord>()), 1)
    }

    func testDiscardDraftIgnoresConcurrentCalls() async throws {
        let service = CountingOptimizationService()
        let vm = DraftEditorViewModel(
            draft: makeDraft(),
            patientName: "X",
            optimizationService: service
        )

        async let first: Void = vm.discardDraft()
        async let second: Void = vm.discardDraft()
        _ = await (first, second)

        let calls = await service.discardCount
        XCTAssertEqual(calls, 1, "Concurrent discardDraft calls must execute only once")
        XCTAssertTrue(vm.wasDiscarded)
    }

    func testPatientDetailViewModelIgnoresDuplicateGenerationAndDoubleConsent() async throws {
        let patient = makeSamplePatient()
        let mockService = CountingOptimizationService()
        let engineService = CountingEngineService()

        let previousKey = OpenRouterService.apiKey
        let previousConsent = OpenRouterService.hasDataProcessingConsent
        defer {
            OpenRouterService.apiKey = previousKey
            OpenRouterService.hasDataProcessingConsent = previousConsent
        }

        // Case 1: unconfigured engine -> mockService single-flight
        OpenRouterService.apiKey = ""
        OpenRouterService.hasDataProcessingConsent = false

        let vm = PatientDetailViewModel(
            patient: patient,
            optimizationService: mockService,
            engineService: engineService
        )

        async let genA: Void = vm.generateOptimizedPlan()
        async let genB: Void = vm.generateOptimizedPlan()
        _ = await (genA, genB)

        let mockCalls = await mockService.generateCount
        XCTAssertEqual(mockCalls, 1, "Concurrent generateOptimizedPlan calls must execute only once")
        XCTAssertNotNil(vm.generatedDraft)

        // Case 2: configured engine -> double confirmConsentAndGenerate during sheet dismiss
        OpenRouterService.apiKey = "sk-or-test-key"
        OpenRouterService.hasDataProcessingConsent = false
        vm.resetGeneration()

        async let consentA: Void = vm.confirmConsentAndGenerate()
        async let consentB: Void = vm.confirmConsentAndGenerate()
        _ = await (consentA, consentB)

        let engineCalls = await engineService.generateCount
        XCTAssertEqual(engineCalls, 1, "Double-tapping consent accept must invoke OpenRouter engine only once")
    }
}

private actor CountingOptimizationService: OptimizationServiceProtocol {
    private(set) var generateCount = 0
    private(set) var approveCount = 0
    private(set) var discardCount = 0

    func generateDraft(for patient: Patient) async throws -> PlanOptimizationDraft {
        generateCount += 1
        try await Task.sleep(for: .milliseconds(50))
        return PlanOptimizationDraft(
            id: UUID(),
            patientId: patient.id,
            status: .pendingReview,
            calculatedRationale: "Demo",
            meals: [],
            createdAt: .now,
            isDemo: true
        )
    }

    func fetchPendingDrafts() async throws -> [PlanOptimizationDraft] {
        []
    }

    func approveDraft(_ draft: PlanOptimizationDraft) async throws -> PlanOptimizationDraft {
        approveCount += 1
        try await Task.sleep(for: .milliseconds(50))
        var copy = draft
        copy.status = .approved
        return copy
    }

    func discardDraft(_ draft: PlanOptimizationDraft) async throws {
        discardCount += 1
        try await Task.sleep(for: .milliseconds(50))
    }
}

private actor CountingEngineService: OptimizationEngineProtocol {
    private(set) var generateCount = 0

    func generateOptimizedPlan(
        for patient: Patient,
        customPrompt: String?,
        feedback: PatientFeedbackSnapshot?
    ) async throws -> PlanOptimizationDraft {
        generateCount += 1
        try await Task.sleep(for: .milliseconds(50))
        return PlanOptimizationDraft(
            id: UUID(),
            patientId: patient.id,
            status: .pendingReview,
            calculatedRationale: "Engine",
            meals: [],
            createdAt: .now,
            isDemo: false
        )
    }
}
