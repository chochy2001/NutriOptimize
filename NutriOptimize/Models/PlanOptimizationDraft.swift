import Foundation

enum DraftStatus: String, Codable {
    case pendingReview = "pending_review"
    case approved = "approved"
    case discarded = "discarded"
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
