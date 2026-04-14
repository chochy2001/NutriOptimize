import Foundation

@MainActor
final class PatientDetailViewModel: ObservableObject {
    @Published var patient: Patient
    @Published var isGenerating = false
    @Published var generatedDraft: PlanOptimizationDraft?
    @Published var errorMessage: String?
    @Published var generationProgress: Double = 0

    private let mockService: OptimizationServiceProtocol
    private let engineService: OptimizationEngineProtocol

    init(
        patient: Patient,
        optimizationService: OptimizationServiceProtocol = MockOptimizationService(),
        engineService: OptimizationEngineProtocol = OpenRouterService()
    ) {
        self.patient = patient
        self.mockService = optimizationService
        self.engineService = engineService
    }

    /// Generates an optimized meal plan using the configured engine.
    /// Falls back to the mock service if no API key is configured.
    func generateOptimizedPlan() async {
        isGenerating = true
        generationProgress = 0
        errorMessage = nil

        // Progress simulation runs alongside the engine call.
        let progressTask = Task {
            let steps = [0.15, 0.35, 0.55, 0.75, 0.90]
            for step in steps {
                try await Task.sleep(for: .milliseconds(500))
                if !Task.isCancelled { generationProgress = step }
            }
        }

        do {
            let draft: PlanOptimizationDraft

            if OpenRouterService.isConfigured {
                let customPrompt = OpenRouterService.customPrompt
                draft = try await engineService.generateOptimizedPlan(
                    for: patient,
                    customPrompt: customPrompt.isEmpty ? nil : customPrompt
                )
            } else {
                draft = try await mockService.generateDraft(for: patient)
            }

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
