import Foundation
import SwiftData

@MainActor
final class DraftEditorViewModel: ObservableObject {
    @Published var draft: PlanOptimizationDraft
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var wasApproved = false
    @Published var wasDiscarded = false
    @Published var wasSavedToPending = false

    let patientName: String
    let patientId: UUID

    /// Injected from the view to persist consultation records on approval.
    var modelContext: ModelContext?

    private let optimizationService: OptimizationServiceProtocol
    private let pdfService = PDFExportService()

    init(
        draft: PlanOptimizationDraft,
        patientName: String,
        optimizationService: OptimizationServiceProtocol = MockOptimizationService()
    ) {
        self.draft = draft
        self.patientName = patientName
        self.patientId = draft.patientId
        self.optimizationService = optimizationService
    }

    // MARK: - Meal Editing

    func updateMeal(_ updatedMeal: Meal) {
        guard let index = draft.meals.firstIndex(where: { $0.id == updatedMeal.id }) else { return }
        draft.meals[index] = updatedMeal
    }

    func deleteMeal(_ meal: Meal) {
        draft.meals.removeAll(where: { $0.id == meal.id })
    }

    func addMeal(_ meal: Meal) {
        draft.meals.append(meal)
    }

    // MARK: - Draft Lifecycle

    func approveDraft(patientWeight: Double? = nil) async {
        isProcessing = true
        errorMessage = nil

        // Refuse to approve a draft whose patient no longer exists, which would
        // otherwise persist an orphaned consultation (e.g. with weight 0) tied
        // to a deleted patient. With cascade-delete this is rare, but the guard
        // makes the failure explicit instead of silently corrupting history.
        if let context = modelContext, !patientStillExists(context: context) {
            errorMessage = "El paciente de este borrador ya no existe. No es posible aprobarlo."
            isProcessing = false
            return
        }

        do {
            let approved = try await optimizationService.approveDraft(draft)
            draft = approved
            wasApproved = true

            // Persist a consultation record from the approved draft
            if let context = modelContext {
                let weight = patientWeight ?? 0
                let sortedMealNames = draft.meals
                    .sorted { $0.type.sortOrder < $1.type.sortOrder }
                    .map(\.name)
                    .joined(separator: ", ")

                let record = ConsultationRecord(
                    patientId: patientId,
                    date: .now,
                    weight: weight,
                    totalCaloriesPrescribed: draft.totalCalories,
                    totalProtein: draft.totalProtein,
                    totalCarbs: draft.totalCarbs,
                    totalFat: draft.totalFat,
                    planSummary: sortedMealNames,
                    clinicalNotes: draft.calculatedRationale
                )
                context.insert(record)
                try? context.save()

                // Clean up the pending-review record if one exists, so the
                // approved draft no longer appears in the pending list.
                deletePendingRecordIfAny(context: context)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    func discardDraft() async {
        isProcessing = true
        errorMessage = nil

        do {
            try await optimizationService.discardDraft(draft)
            wasDiscarded = true

            if let context = modelContext {
                deletePendingRecordIfAny(context: context)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    /// Persists the current draft to SwiftData so the professional can review it later,
    /// even after dismissing the editor. If a record for this draft already exists it is
    /// updated in place (keeping meal edits intact across sessions).
    func saveToPendingReview() async {
        guard let context = modelContext else {
            errorMessage = "No se pudo guardar el borrador"
            return
        }
        isProcessing = true
        errorMessage = nil

        let targetId = draft.id
        let descriptor = FetchDescriptor<PlanDraftRecord>(
            predicate: #Predicate<PlanDraftRecord> { $0.draftId == targetId }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.update(from: draft)
        } else {
            let record = PlanDraftRecord(from: draft)
            context.insert(record)
        }
        try? context.save()

        wasSavedToPending = true
        isProcessing = false
    }

    /// Returns whether a `PatientRecord` with this draft's `patientId` still
    /// exists in the store.
    private func patientStillExists(context: ModelContext) -> Bool {
        let targetId = patientId
        var descriptor = FetchDescriptor<PatientRecord>(
            predicate: #Predicate<PatientRecord> { $0.patientId == targetId }
        )
        descriptor.fetchLimit = 1
        return ((try? context.fetch(descriptor).first) ?? nil) != nil
    }

    private func deletePendingRecordIfAny(context: ModelContext) {
        let targetId = draft.id
        let descriptor = FetchDescriptor<PlanDraftRecord>(
            predicate: #Predicate<PlanDraftRecord> { $0.draftId == targetId }
        )
        if let record = try? context.fetch(descriptor).first {
            context.delete(record)
            try? context.save()
        }
    }

    // MARK: - PDF Export

    /// Generates a PDF document for the current draft and patient data.
    func exportPDF(patient: Patient) -> Data {
        pdfService.generatePDF(for: draft, patient: patient)
    }
}
