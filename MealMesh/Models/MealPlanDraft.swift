import Foundation

enum DraftStatus: String, Codable {
    case pendingReview = "pending_review"
    case approved = "approved"
}

struct MealPlanDraft: Identifiable, Codable {
    let id: UUID
    let patientId: UUID
    var status: DraftStatus
    var engineRationale: String
    var meals: [Meal]
    let createdAt: Date

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

    /// Groups meals by type for structured display in the review interface.
    var mealsByType: [MealType: [Meal]] {
        Dictionary(grouping: meals, by: \.type)
    }
}
