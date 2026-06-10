import Foundation
import SwiftData

enum DraftStatus: String, Codable {
    case pendingReview = "pending_review"
    case approved = "approved"
    case discarded = "discarded"
}

/// Identifies what produced a draft. Demo drafts are generated locally when no
/// optimization engine is configured and must be presented to the professional
/// as a non-clinical sample, never as an engine-validated proposal.
enum EngineSource: String, Codable {
    case engine
    case demo
}

/// Represents a system-generated meal plan proposal that awaits professional review.
/// The `calculatedRationale` field contains the engine's reasoning: why these macros
/// and food selections were proposed based on the patient's clinical profile.
struct PlanOptimizationDraft: Identifiable, Codable {
    let id: UUID
    let patientId: UUID
    var status: DraftStatus
    var calculatedRationale: String
    var meals: [Meal]
    let createdAt: Date
    /// What produced this draft. Defaults to `.engine` so drafts decoded from
    /// older payloads (which predate this field) are not mislabeled as demos.
    var engineSource: EngineSource = .engine

    /// Whether this draft is a local demonstration sample rather than a real
    /// engine-generated proposal.
    var isDemo: Bool { engineSource == .demo }

    // MARK: - Aggregate Macros

    var totalCalories: Double {
        meals.reduce(0) { $0 + $1.macros.totalCalories }
    }

    var totalProtein: Double {
        meals.reduce(0) { $0 + $1.macros.protein }
    }

    var totalCarbs: Double {
        meals.reduce(0) { $0 + $1.macros.carbohydrates }
    }

    var totalFat: Double {
        meals.reduce(0) { $0 + $1.macros.fat }
    }

    var mealsByType: [MealType: [Meal]] {
        Dictionary(grouping: meals, by: \.type)
    }

    /// Compares the draft's total calories against the patient's estimated TDEE
    /// to provide a quick adherence check for the reviewing professional.
    func calorieAdherencePercentage(tdee: Double) -> Double {
        guard tdee > 0 else { return 0 }
        return (totalCalories / tdee) * 100
    }
}

/// SwiftData-backed persistence record for a plan draft awaiting professional review.
/// Meals are encoded as JSON so we don't have to declare each nested struct as a
/// separate @Model - the `Meal` / `Macros` value types stay pure Codable.
@Model
final class PlanDraftRecord {
    @Attribute(.unique) var draftId: UUID
    var patientId: UUID
    var statusRaw: String
    var calculatedRationale: String
    var mealsData: Data
    var createdAt: Date
    /// Optional so existing SwiftData rows (created before this field existed)
    /// decode as `nil` and default to `.engine` when converted back to a draft.
    var engineSourceRaw: String?

    init(from draft: PlanOptimizationDraft) {
        self.draftId = draft.id
        self.patientId = draft.patientId
        self.statusRaw = draft.status.rawValue
        self.calculatedRationale = draft.calculatedRationale
        self.createdAt = draft.createdAt
        self.engineSourceRaw = draft.engineSource.rawValue
        self.mealsData = (try? JSONEncoder().encode(draft.meals)) ?? Data()
    }

    func update(from draft: PlanOptimizationDraft) {
        self.patientId = draft.patientId
        self.statusRaw = draft.status.rawValue
        self.calculatedRationale = draft.calculatedRationale
        self.engineSourceRaw = draft.engineSource.rawValue
        self.mealsData = (try? JSONEncoder().encode(draft.meals)) ?? self.mealsData
    }

    func toDraft() -> PlanOptimizationDraft {
        let meals = (try? JSONDecoder().decode([Meal].self, from: mealsData)) ?? []
        let status = DraftStatus(rawValue: statusRaw) ?? .pendingReview
        let source = engineSourceRaw.flatMap(EngineSource.init(rawValue:)) ?? .engine
        return PlanOptimizationDraft(
            id: draftId,
            patientId: patientId,
            status: status,
            calculatedRationale: calculatedRationale,
            meals: meals,
            createdAt: createdAt,
            engineSource: source
        )
    }
}
