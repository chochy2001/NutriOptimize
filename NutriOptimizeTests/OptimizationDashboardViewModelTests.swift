import XCTest
import SwiftData
@testable import NutriOptimize

/// Covers the dashboard view model: configuration, patient CRUD delegation to the
/// store, dashboard loading (seed + fetch + pending drafts), pending-draft refresh
/// and deletion, and the patient-name lookup. Uses an in-memory SwiftData store.
@MainActor
final class OptimizationDashboardViewModelTests: XCTestCase {

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

    private func patient(id: UUID = UUID(), name: String = "Paciente") -> Patient {
        Patient(
            id: id, fullName: name, age: 30, sex: .female, weight: 60, height: 160,
            bodyFatPercentage: nil, allergies: [], medicalConditions: [],
            dietaryPreferences: [], clinicalGoals: "Mantenimiento",
            availableCookingTime: 30, activityLevel: .sedentary
        )
    }

    private func pendingDraft(patientId: UUID) -> PlanOptimizationDraft {
        PlanOptimizationDraft(
            id: UUID(), patientId: patientId, status: .pendingReview,
            calculatedRationale: "x",
            meals: [Meal(type: .breakfast, name: "Desayuno", ingredients: ["Avena"],
                         macros: Macros(protein: 10, carbohydrates: 30, fat: 5))],
            createdAt: .now
        )
    }

    // MARK: - Patient CRUD

    func testAddPatientPersistsAndRefreshesList() throws {
        let context = try makeContext()
        let vm = OptimizationDashboardViewModel()
        vm.configure(modelContext: context)

        vm.addPatient(patient(name: "Nuevo"))

        XCTAssertEqual(vm.patients.count, 1)
        XCTAssertEqual(vm.patients.first?.fullName, "Nuevo")
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PatientRecord>()), 1)
    }

    func testUpdatePatientReflectsInList() throws {
        let context = try makeContext()
        let vm = OptimizationDashboardViewModel()
        vm.configure(modelContext: context)

        let id = UUID()
        vm.addPatient(patient(id: id, name: "Antes"))

        var edited = patient(id: id, name: "Después")
        edited.weight = 75
        vm.updatePatient(edited)

        XCTAssertEqual(vm.patients.count, 1)
        XCTAssertEqual(vm.patients.first?.fullName, "Después")
        XCTAssertEqual(vm.patients.first?.weight, 75)
        XCTAssertNil(vm.errorMessage)
    }

    func testUpdateUnknownPatientSurfacesError() throws {
        let context = try makeContext()
        let vm = OptimizationDashboardViewModel()
        vm.configure(modelContext: context)

        vm.updatePatient(patient(name: "Fantasma"))
        XCTAssertNotNil(vm.errorMessage, "Updating a nonexistent patient must surface an error")
    }

    func testDeletePatientRemovesFromListAndStore() throws {
        let context = try makeContext()
        let vm = OptimizationDashboardViewModel()
        vm.configure(modelContext: context)

        let id = UUID()
        vm.addPatient(patient(id: id, name: "A borrar"))
        XCTAssertEqual(vm.patients.count, 1)

        vm.deletePatient(patient(id: id))
        XCTAssertTrue(vm.patients.isEmpty)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PatientRecord>()), 0)
    }

    // MARK: - Dashboard loading

    func testLoadDashboardSeedsAndLoadsPatients() async throws {
        let context = try makeContext()
        let vm = OptimizationDashboardViewModel()
        vm.configure(modelContext: context)

        await vm.loadDashboard()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.patients.isEmpty, "loadDashboard must seed sample patients on empty store")
        XCTAssertEqual(vm.patients.count, MockPatientService.samplePatients.count)
    }

    func testLoadDashboardSurfacesPendingDrafts() async throws {
        let context = try makeContext()
        let vm = OptimizationDashboardViewModel()
        vm.configure(modelContext: context)

        // Seed a patient plus a persisted pending draft for that patient.
        let store = PatientStore(modelContext: context)
        let p = patient(name: "Con borrador")
        try store.create(p)
        context.insert(PlanDraftRecord(from: pendingDraft(patientId: p.id)))
        try context.save()

        await vm.loadDashboard()

        XCTAssertEqual(vm.pendingDrafts.count, 1)
        XCTAssertEqual(vm.pendingDrafts.first?.patientId, p.id)
        XCTAssertEqual(vm.patientName(for: vm.pendingDrafts[0]), "Con borrador")
    }

    func testPatientNameFallsBackWhenUnknown() {
        let vm = OptimizationDashboardViewModel()
        let orphan = pendingDraft(patientId: UUID())
        XCTAssertEqual(vm.patientName(for: orphan), "Paciente",
                       "An unknown patient id falls back to the generic label")
    }

    // MARK: - Pending-draft refresh / delete

    func testRefreshPendingDraftsIgnoresNonPending() async throws {
        let context = try makeContext()
        let vm = OptimizationDashboardViewModel()
        vm.configure(modelContext: context)

        let pid = UUID()
        // One pending draft (should show) and one approved (should not).
        context.insert(PlanDraftRecord(from: pendingDraft(patientId: pid)))
        var approved = pendingDraft(patientId: pid)
        approved.status = .approved
        context.insert(PlanDraftRecord(from: approved))
        try context.save()

        vm.refreshPendingDrafts()

        XCTAssertEqual(vm.pendingDrafts.count, 1, "Only pending_review drafts appear")
        XCTAssertEqual(vm.pendingDrafts.first?.status, .pendingReview)
    }

    func testDeletePendingDraftRemovesRecordAndListEntry() async throws {
        let context = try makeContext()
        let vm = OptimizationDashboardViewModel()
        vm.configure(modelContext: context)

        let draft = pendingDraft(patientId: UUID())
        context.insert(PlanDraftRecord(from: draft))
        try context.save()
        vm.refreshPendingDrafts()
        XCTAssertEqual(vm.pendingDrafts.count, 1)

        vm.deletePendingDraft(draft)

        XCTAssertTrue(vm.pendingDrafts.isEmpty)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanDraftRecord>()), 0)
    }
}
