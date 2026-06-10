import Foundation
import SwiftData

@MainActor
final class PatientDetailViewModel: ObservableObject {
    @Published var patient: Patient
    @Published var isGenerating = false
    @Published var generatedDraft: PlanOptimizationDraft?
    @Published var errorMessage: String?
    @Published var generationProgress: Double = 0
    /// Set when the configured engine requires data-processing consent that the
    /// professional has not yet granted. The view observes this to present the
    /// consent disclosure before any patient data leaves the device.
    @Published var needsDataProcessingConsent = false

    private let mockService: OptimizationServiceProtocol
    private let engineService: OptimizationEngineProtocol
    var modelContext: ModelContext?

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
    ///
    /// When the real engine is configured but the professional has not yet
    /// granted data-processing consent, this surfaces `needsDataProcessingConsent`
    /// instead of sending any patient data, so the view can present the
    /// disclosure first.
    func generateOptimizedPlan() async {
        if OpenRouterService.isConfigured && !OpenRouterService.hasDataProcessingConsent {
            needsDataProcessingConsent = true
            return
        }
        await runGeneration()
    }

    /// Called by the view once the professional accepts the data-processing
    /// disclosure, to proceed with the engine call.
    func confirmConsentAndGenerate() async {
        OpenRouterService.hasDataProcessingConsent = true
        needsDataProcessingConsent = false
        await runGeneration()
    }

    private func runGeneration() async {
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

            // Load patient feedback snapshot for the optimization engine
            let feedbackSnapshot = loadFeedbackSnapshot()

            if OpenRouterService.isConfigured {
                let customPrompt = OpenRouterService.customPrompt
                draft = try await engineService.generateOptimizedPlan(
                    for: patient,
                    customPrompt: customPrompt.isEmpty ? nil : customPrompt,
                    feedback: feedbackSnapshot
                )
            } else {
                // No engine configured: produce a demonstration draft locally.
                // It is explicitly tagged as a demo so the UI can warn the
                // professional that it is NOT an engine-generated plan.
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

    /// Loads the patient's feedback record and creates a sendable snapshot
    /// for use by the optimization engine in async contexts.
    private func loadFeedbackSnapshot() -> PatientFeedbackSnapshot? {
        guard let modelContext else { return nil }
        let targetId = patient.id
        let descriptor = FetchDescriptor<PatientFeedbackRecord>(
            predicate: #Predicate<PatientFeedbackRecord> { $0.patientId == targetId }
        )
        guard let record = try? modelContext.fetch(descriptor).first else { return nil }
        let hasData = !record.likedFoods.isEmpty || !record.dislikedFoods.isEmpty
            || !record.bannedFoods.isEmpty || !record.generalNotes.isEmpty
        guard hasData else { return nil }
        return PatientFeedbackSnapshot(
            likedFoods: record.likedFoods,
            dislikedFoods: record.dislikedFoods,
            bannedFoods: record.bannedFoods,
            generalNotes: record.generalNotes
        )
    }
}
