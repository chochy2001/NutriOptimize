import Foundation

protocol MealPlanServiceProtocol: Sendable {
    func generateDraft(for patient: Patient) async throws -> MealPlanDraft
    func fetchPendingDrafts() async throws -> [MealPlanDraft]
    func approveDraft(_ draft: MealPlanDraft) async throws -> MealPlanDraft
    func discardDraft(_ draft: MealPlanDraft) async throws
}
