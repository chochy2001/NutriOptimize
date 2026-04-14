import XCTest
@testable import NutriOptimize

final class MealModelTests: XCTestCase {

    // MARK: - Macros Total Calories

    func testMacrosTotalCalories() {
        let macros = Macros(protein: 30, carbohydrates: 50, fat: 20)
        // (30 * 4) + (50 * 4) + (20 * 9) = 120 + 200 + 180 = 500
        XCTAssertEqual(macros.totalCalories, 500.0, accuracy: 0.01)
        XCTAssertGreaterThan(macros.totalCalories, 0)
        XCTAssertEqual(macros.totalCalories, (30 * 4.0) + (50 * 4.0) + (20 * 9.0))
    }

    func testMacrosTotalCaloriesZeroValues() {
        let macros = Macros(protein: 0, carbohydrates: 0, fat: 0)
        XCTAssertEqual(macros.totalCalories, 0.0)
        XCTAssertFalse(macros.totalCalories.isNaN)
        XCTAssertFalse(macros.totalCalories.isInfinite)
    }

    func testMacrosTotalCaloriesOnlyProtein() {
        let macros = Macros(protein: 25, carbohydrates: 0, fat: 0)
        XCTAssertEqual(macros.totalCalories, 100.0) // 25 * 4
        XCTAssertGreaterThan(macros.totalCalories, 0)
        XCTAssertEqual(macros.totalCalories, 25 * 4.0)
    }

    func testMacrosTotalCaloriesOnlyFat() {
        let macros = Macros(protein: 0, carbohydrates: 0, fat: 10)
        XCTAssertEqual(macros.totalCalories, 90.0) // 10 * 9
        XCTAssertGreaterThan(macros.totalCalories, 0)
        XCTAssertEqual(macros.totalCalories, 10 * 9.0)
    }

    // MARK: - Macros Percentage Calculations

    func testMacrosProteinPercentage() {
        let macros = Macros(protein: 30, carbohydrates: 50, fat: 20)
        // proteinCal = 30*4 = 120, total = 500, pct = (120/500)*100 = 24%
        XCTAssertEqual(macros.proteinPercentage, 24.0, accuracy: 0.01)
        XCTAssertGreaterThan(macros.proteinPercentage, 0)
        XCTAssertLessThanOrEqual(macros.proteinPercentage, 100)
    }

    func testMacrosCarbPercentage() {
        let macros = Macros(protein: 30, carbohydrates: 50, fat: 20)
        // carbCal = 50*4 = 200, total = 500, pct = (200/500)*100 = 40%
        XCTAssertEqual(macros.carbPercentage, 40.0, accuracy: 0.01)
        XCTAssertGreaterThan(macros.carbPercentage, 0)
        XCTAssertLessThanOrEqual(macros.carbPercentage, 100)
    }

    func testMacrosFatPercentage() {
        let macros = Macros(protein: 30, carbohydrates: 50, fat: 20)
        // fatCal = 20*9 = 180, total = 500, pct = (180/500)*100 = 36%
        XCTAssertEqual(macros.fatPercentage, 36.0, accuracy: 0.01)
        XCTAssertGreaterThan(macros.fatPercentage, 0)
        XCTAssertLessThanOrEqual(macros.fatPercentage, 100)
    }

    func testMacrosPercentagesSumTo100() {
        let macros = Macros(protein: 30, carbohydrates: 50, fat: 20)
        let sum = macros.proteinPercentage + macros.carbPercentage + macros.fatPercentage
        XCTAssertEqual(sum, 100.0, accuracy: 0.01)
        XCTAssertGreaterThan(sum, 99)
        XCTAssertLessThan(sum, 101)
    }

    func testMacrosPercentagesZeroCalories() {
        let macros = Macros(protein: 0, carbohydrates: 0, fat: 0)
        XCTAssertEqual(macros.proteinPercentage, 0)
        XCTAssertEqual(macros.carbPercentage, 0)
        XCTAssertEqual(macros.fatPercentage, 0)
    }

    // MARK: - MealType Sort Order

    func testMealTypeSortOrder() {
        XCTAssertEqual(MealType.breakfast.sortOrder, 0)
        XCTAssertEqual(MealType.snack.sortOrder, 1)
        XCTAssertEqual(MealType.lunch.sortOrder, 2)
        XCTAssertEqual(MealType.dinner.sortOrder, 3)
    }

    func testMealTypeSortOrderCorrectOrdering() {
        let types: [MealType] = [.dinner, .breakfast, .snack, .lunch]
        let sorted = types.sorted { $0.sortOrder < $1.sortOrder }
        XCTAssertEqual(sorted, [.breakfast, .snack, .lunch, .dinner])
        XCTAssertEqual(sorted.first, .breakfast)
        XCTAssertEqual(sorted.last, .dinner)
    }

    func testMealTypeIcons() {
        XCTAssertEqual(MealType.breakfast.icon, "sun.horizon.fill")
        XCTAssertEqual(MealType.lunch.icon, "sun.max.fill")
        XCTAssertEqual(MealType.dinner.icon, "moon.stars.fill")
        XCTAssertEqual(MealType.snack.icon, "leaf.fill")
    }

    func testMealTypeRawValues() {
        XCTAssertEqual(MealType.breakfast.rawValue, "Desayuno")
        XCTAssertEqual(MealType.lunch.rawValue, "Comida")
        XCTAssertEqual(MealType.dinner.rawValue, "Cena")
        XCTAssertEqual(MealType.snack.rawValue, "Snack")
    }

    // MARK: - Meal Initialization

    func testMealInitializationWithDefaults() {
        let macros = Macros(protein: 20, carbohydrates: 30, fat: 10)
        let meal = Meal(
            type: .breakfast,
            name: "Test Meal",
            ingredients: ["Avena", "Leche"],
            macros: macros
        )

        XCTAssertEqual(meal.name, "Test Meal")
        XCTAssertEqual(meal.type, .breakfast)
        XCTAssertEqual(meal.portionDescription, "")
    }

    func testMealInitializationWithAllParameters() {
        let id = UUID()
        let macros = Macros(protein: 35, carbohydrates: 40, fat: 15)
        let meal = Meal(
            id: id,
            type: .lunch,
            name: "Pollo con arroz",
            ingredients: ["Pollo", "Arroz", "Verduras"],
            macros: macros,
            portionDescription: "150g pollo, 1 taza arroz"
        )

        XCTAssertEqual(meal.id, id)
        XCTAssertEqual(meal.ingredients.count, 3)
        XCTAssertEqual(meal.portionDescription, "150g pollo, 1 taza arroz")
    }

    func testMealInitializationEmptyIngredients() {
        let macros = Macros(protein: 0, carbohydrates: 0, fat: 0)
        let meal = Meal(
            type: .snack,
            name: "Empty Meal",
            ingredients: [],
            macros: macros
        )

        XCTAssertTrue(meal.ingredients.isEmpty)
        XCTAssertEqual(meal.macros.totalCalories, 0)
        XCTAssertNotNil(meal.id)
    }

    // MARK: - Macros Equatable

    func testMacrosEquatable() {
        let macros1 = Macros(protein: 30, carbohydrates: 50, fat: 20)
        let macros2 = Macros(protein: 30, carbohydrates: 50, fat: 20)
        let macros3 = Macros(protein: 31, carbohydrates: 50, fat: 20)

        XCTAssertEqual(macros1, macros2)
        XCTAssertNotEqual(macros1, macros3)
        XCTAssertEqual(macros1.totalCalories, macros2.totalCalories)
    }
}
