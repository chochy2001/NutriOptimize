import Foundation

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "Desayuno"
    case lunch = "Comida"
    case dinner = "Cena"
    case snack = "Snack"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .breakfast: return "sun.horizon.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        }
    }

    var sortOrder: Int {
        switch self {
        case .breakfast: return 0
        case .snack: return 1
        case .lunch: return 2
        case .dinner: return 3
        }
    }
}

struct Macros: Codable, Equatable {
    var protein: Double
    var carbohydrates: Double
    var fat: Double

    var totalCalories: Double {
        (protein * 4.0) + (carbohydrates * 4.0) + (fat * 9.0)
    }

    /// Percentage breakdown for chart displays.
    var proteinPercentage: Double {
        guard totalCalories > 0 else { return 0 }
        return (protein * 4.0 / totalCalories) * 100
    }

    var carbPercentage: Double {
        guard totalCalories > 0 else { return 0 }
        return (carbohydrates * 4.0 / totalCalories) * 100
    }

    var fatPercentage: Double {
        guard totalCalories > 0 else { return 0 }
        return (fat * 9.0 / totalCalories) * 100
    }
}

struct Meal: Identifiable, Codable {
    let id: UUID
    var type: MealType
    var name: String
    var ingredients: [String]
    var macros: Macros
    var portionDescription: String

    init(
        id: UUID = UUID(),
        type: MealType,
        name: String,
        ingredients: [String],
        macros: Macros,
        portionDescription: String = ""
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.ingredients = ingredients
        self.macros = macros
        self.portionDescription = portionDescription
    }
}
