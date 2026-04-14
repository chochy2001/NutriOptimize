import Foundation

@MainActor
final class DraftEditorViewModel: ObservableObject {
    @Published var draft: PlanOptimizationDraft
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var wasApproved = false
    @Published var wasDiscarded = false

    let patientName: String

    private let optimizationService: OptimizationServiceProtocol

    init(
        draft: PlanOptimizationDraft,
        patientName: String,
        optimizationService: OptimizationServiceProtocol = MockOptimizationService()
    ) {
        self.draft = draft
        self.patientName = patientName
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

    func approveDraft() async {
        isProcessing = true
        errorMessage = nil

        do {
            let approved = try await optimizationService.approveDraft(draft)
            draft = approved
            wasApproved = true
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
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }
}
