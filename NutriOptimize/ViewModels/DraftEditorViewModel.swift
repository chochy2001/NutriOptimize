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
