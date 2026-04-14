import Foundation

/// Defines the contract for the plan optimization engine.
/// Implementations can range from a local rule-based engine
/// to a remote microservice that runs more sophisticated calculations.
protocol OptimizationServiceProtocol: Sendable {
    func generateDraft(for patient: Patient) async throws -> PlanOptimizationDraft
    func fetchPendingDrafts() async throws -> [PlanOptimizationDraft]
    func approveDraft(_ draft: PlanOptimizationDraft) async throws -> PlanOptimizationDraft
    func discardDraft(_ draft: PlanOptimizationDraft) async throws
}
