import Foundation

@MainActor
final class PatientDetailViewModel: ObservableObject {
    @Published var patient: Patient
    @Published var isGenerating = false
    @Published var generatedDraft: PlanOptimizationDraft?
    @Published var errorMessage: String?
    @Published var generationProgress: Double = 0

    private let optimizationService: OptimizationServiceProtocol

    init(
        patient: Patient,
        optimizationService: OptimizationServiceProtocol = MockOptimizationService()
    ) {
        self.patient = patient
        self.optimizationService = optimizationService
    }

    func generateOptimizedPlan() async {
        isGenerating = true
        generationProgress = 0
        errorMessage = nil

        // Progress simulation runs alongside the real engine call.
        // The production backend would emit server-sent events for real progress.
        let progressTask = Task {
            let steps = [0.15, 0.35, 0.55, 0.75, 0.90]
            for step in steps {
                try await Task.sleep(for: .milliseconds(500))
                if !Task.isCancelled { generationProgress = step }
            }
        }

        do {
            let draft = try await optimizationService.generateDraft(for: patient)
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
