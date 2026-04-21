import Foundation
import SwiftData

@MainActor
final class OptimizationDashboardViewModel: ObservableObject {
    @Published var patients: [Patient] = []
    @Published var pendingDrafts: [PlanOptimizationDraft] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var patientStore: PatientStore?
    private var modelContext: ModelContext?
    private let optimizationService: OptimizationServiceProtocol

    init(
        optimizationService: OptimizationServiceProtocol = MockOptimizationService()
    ) {
        self.optimizationService = optimizationService
    }

    /// Injects the SwiftData-backed patient store. Called once when the model context becomes available.
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        guard patientStore == nil else { return }
        patientStore = PatientStore(modelContext: modelContext)
    }

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        do {
            // Seed sample patients on first launch
            try patientStore?.seedIfEmpty()

            if let store = patientStore {
                patients = try store.fetchAll()
            } else {
                // Fallback when store is not yet configured
                patients = try await MockPatientService().fetchPatients()
            }

            pendingDrafts = fetchPendingDraftsFromStore()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Lightweight refresh for just the pending-drafts list (e.g. after approve/discard).
    func refreshPendingDrafts() {
        pendingDrafts = fetchPendingDraftsFromStore()
    }

    /// Removes the persisted record corresponding to a pending-review draft.
    func deletePendingDraft(_ draft: PlanOptimizationDraft) {
        guard let context = modelContext else { return }
        let targetId = draft.id
        let descriptor = FetchDescriptor<PlanDraftRecord>(
            predicate: #Predicate<PlanDraftRecord> { $0.draftId == targetId }
        )
        if let record = try? context.fetch(descriptor).first {
            context.delete(record)
            try? context.save()
        }
        pendingDrafts.removeAll { $0.id == draft.id }
    }

    private func fetchPendingDraftsFromStore() -> [PlanOptimizationDraft] {
        guard let context = modelContext else { return [] }
        let pendingRaw = DraftStatus.pendingReview.rawValue
        let descriptor = FetchDescriptor<PlanDraftRecord>(
            predicate: #Predicate<PlanDraftRecord> { $0.statusRaw == pendingRaw },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = (try? context.fetch(descriptor)) ?? []
        return records.map { $0.toDraft() }
    }

    func patientName(for draft: PlanOptimizationDraft) -> String {
        patients.first(where: { $0.id == draft.patientId })?.fullName ?? "Paciente"
    }

    // MARK: - Patient CRUD

    /// Persists a new patient and refreshes the in-memory list.
    func addPatient(_ patient: Patient) {
        do {
            try patientStore?.create(patient)
            patients = try patientStore?.fetchAll() ?? patients
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Updates an existing patient record and refreshes the in-memory list.
    func updatePatient(_ patient: Patient) {
        do {
            try patientStore?.update(patient)
            patients = try patientStore?.fetchAll() ?? patients
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Removes a patient by ID from persistent storage and the in-memory list.
    func deletePatient(_ patient: Patient) {
        do {
            try patientStore?.delete(patientId: patient.id)
            patients.removeAll(where: { $0.id == patient.id })
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
