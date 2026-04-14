import Foundation

@MainActor
final class DraftReviewViewModel: ObservableObject {
    @Published var draft: MealPlanDraft
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var wasApproved = false
    @Published var wasDiscarded = false

    let patientName: String

    private let mealPlanService: MealPlanServiceProtocol

    init(
        draft: MealPlanDraft,
        patientName: String,
        mealPlanService: MealPlanServiceProtocol = MockMealPlanService()
    ) {
        self.draft = draft
        self.patientName = patientName
        self.mealPlanService = mealPlanService
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

    func moveMeals(from source: IndexSet, to destination: Int) {
        draft.meals.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Draft Actions

    func approveDraft() async {
        isProcessing = true
        errorMessage = nil

        do {
            let approved = try await mealPlanService.approveDraft(draft)
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
            try await mealPlanService.discardDraft(draft)
            wasDiscarded = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }
}
