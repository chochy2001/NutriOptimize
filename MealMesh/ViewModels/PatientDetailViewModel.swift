import Foundation

@MainActor
final class PatientDetailViewModel: ObservableObject {
    @Published var patient: Patient
    @Published var isGenerating = false
    @Published var generatedDraft: MealPlanDraft?
    @Published var errorMessage: String?
    @Published var generationProgress: Double = 0

    private let mealPlanService: MealPlanServiceProtocol

    init(
        patient: Patient,
        mealPlanService: MealPlanServiceProtocol = MockMealPlanService()
    ) {
        self.patient = patient
        self.mealPlanService = mealPlanService
    }

    func generateProposal() async {
        isGenerating = true
        generationProgress = 0
        errorMessage = nil

        // Progress simulation runs concurrently with the actual generation call.
        // In production, the backend would provide real progress events via SSE or polling.
        let progressTask = Task {
            let steps = [0.15, 0.35, 0.55, 0.75, 0.90]
            for step in steps {
                try await Task.sleep(for: .milliseconds(500))
                if !Task.isCancelled {
                    generationProgress = step
                }
            }
        }

        do {
            let draft = try await mealPlanService.generateDraft(for: patient)
            progressTask.cancel()
            generationProgress = 1.0
            try await Task.sleep(for: .milliseconds(300))
            generatedDraft = draft
        } catch {
            progressTask.cancel()
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }

    func resetGeneration() {
        generatedDraft = nil
        generationProgress = 0
        errorMessage = nil
    }
}
