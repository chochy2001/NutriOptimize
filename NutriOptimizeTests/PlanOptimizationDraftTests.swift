import XCTest
@testable import NutriOptimize

final class PlanOptimizationDraftTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeDraft(meals: [Meal] = [], status: DraftStatus = .pendingReview) -> PlanOptimizationDraft {
        PlanOptimizationDraft(
            id: UUID(),
            patientId: UUID(),
            status: status,
            calculatedRationale: "Test rationale",
            meals: meals,
            createdAt: .now
        )
    }

    private func makeMeal(type: MealType, protein: Double, carbs: Double, fat: Double) -> Meal {
        Meal(
            type: type,
            name: "Test \(type.rawValue)",
            ingredients: ["Ingrediente A", "Ingrediente B"],
            macros: Macros(protein: protein, carbohydrates: carbs, fat: fat)
        )
    }

    private var sampleMeals: [Meal] {
        [
            makeMeal(type: .breakfast, protein: 20, carbs: 40, fat: 10),
            makeMeal(type: .lunch, protein: 35, carbs: 50, fat: 15),
            makeMeal(type: .snack, protein: 10, carbs: 15, fat: 8),
            makeMeal(type: .dinner, protein: 30, carbs: 35, fat: 18)
        ]
    }

    // MARK: - Total Calories Aggregation

    func testTotalCaloriesAggregation() {
        let draft = makeDraft(meals: sampleMeals)
        let expectedCalories = sampleMeals.reduce(0.0) { $0 + $1.macros.totalCalories }
        XCTAssertEqual(draft.totalCalories, expectedCalories, accuracy: 0.01)
        XCTAssertGreaterThan(draft.totalCalories, 0)
        XCTAssertEqual(draft.meals.count, 4)
    }

    func testTotalCaloriesEmptyMeals() {
        let draft = makeDraft(meals: [])
        XCTAssertEqual(draft.totalCalories, 0.0)
        XCTAssertTrue(draft.meals.isEmpty)
        XCTAssertEqual(draft.totalProtein, 0.0)
    }

    func testTotalCaloriesSingleMeal() {
        let meal = makeMeal(type: .breakfast, protein: 25, carbs: 30, fat: 12)
        let draft = makeDraft(meals: [meal])
        let expected = (25 * 4.0) + (30 * 4.0) + (12 * 9.0) // 100 + 120 + 108 = 328
        XCTAssertEqual(draft.totalCalories, expected, accuracy: 0.01)
        XCTAssertEqual(draft.meals.count, 1)
        XCTAssertEqual(draft.totalCalories, 328.0, accuracy: 0.01)
    }

    // MARK: - Total Protein

    func testTotalProtein() {
        let draft = makeDraft(meals: sampleMeals)
        let expectedProtein = 20.0 + 35.0 + 10.0 + 30.0 // 95
        XCTAssertEqual(draft.totalProtein, expectedProtein, accuracy: 0.01)
        XCTAssertEqual(draft.totalProtein, 95.0, accuracy: 0.01)
        XCTAssertGreaterThan(draft.totalProtein, 0)
    }

    // MARK: - Total Carbs

    func testTotalCarbs() {
        let draft = makeDraft(meals: sampleMeals)
        let expectedCarbs = 40.0 + 50.0 + 15.0 + 35.0 // 140
        XCTAssertEqual(draft.totalCarbs, expectedCarbs, accuracy: 0.01)
        XCTAssertEqual(draft.totalCarbs, 140.0, accuracy: 0.01)
        XCTAssertGreaterThan(draft.totalCarbs, 0)
    }

    // MARK: - Total Fat

    func testTotalFat() {
        let draft = makeDraft(meals: sampleMeals)
        let expectedFat = 10.0 + 15.0 + 8.0 + 18.0 // 51
        XCTAssertEqual(draft.totalFat, expectedFat, accuracy: 0.01)
        XCTAssertEqual(draft.totalFat, 51.0, accuracy: 0.01)
        XCTAssertGreaterThan(draft.totalFat, 0)
    }

    // MARK: - Meals By Type Grouping

    func testMealsByTypeGrouping() {
        let draft = makeDraft(meals: sampleMeals)
        let grouped = draft.mealsByType

        XCTAssertEqual(grouped[.breakfast]?.count, 1)
        XCTAssertEqual(grouped[.lunch]?.count, 1)
        XCTAssertEqual(grouped[.snack]?.count, 1)
        XCTAssertEqual(grouped[.dinner]?.count, 1)
    }

    func testMealsByTypeGroupingMultipleSameType() {
        let meals = [
            makeMeal(type: .snack, protein: 5, carbs: 10, fat: 3),
            makeMeal(type: .snack, protein: 8, carbs: 12, fat: 5),
            makeMeal(type: .breakfast, protein: 20, carbs: 30, fat: 10)
        ]
        let draft = makeDraft(meals: meals)
        let grouped = draft.mealsByType

        XCTAssertEqual(grouped[.snack]?.count, 2)
        XCTAssertEqual(grouped[.breakfast]?.count, 1)
        XCTAssertNil(grouped[.lunch])
    }

    func testMealsByTypeGroupingEmptyMeals() {
        let draft = makeDraft(meals: [])
        let grouped = draft.mealsByType

        XCTAssertTrue(grouped.isEmpty)
        XCTAssertNil(grouped[.breakfast])
        XCTAssertNil(grouped[.dinner])
    }

    // MARK: - Calorie Adherence Percentage

    func testCalorieAdherencePercentage() {
        let draft = makeDraft(meals: sampleMeals)
        let tdee = 2000.0
        let expected = (draft.totalCalories / tdee) * 100
        XCTAssertEqual(draft.calorieAdherencePercentage(tdee: tdee), expected, accuracy: 0.01)
        XCTAssertGreaterThan(draft.calorieAdherencePercentage(tdee: tdee), 0)
        XCTAssertTrue(draft.calorieAdherencePercentage(tdee: tdee).isFinite)
    }

    func testCalorieAdherencePercentageZeroTDEE() {
        let draft = makeDraft(meals: sampleMeals)
        XCTAssertEqual(draft.calorieAdherencePercentage(tdee: 0), 0)
        XCTAssertFalse(draft.calorieAdherencePercentage(tdee: 0).isNaN)
        XCTAssertFalse(draft.calorieAdherencePercentage(tdee: 0).isInfinite)
    }

    func testCalorieAdherencePercentage100Percent() {
        // Create meals that total exactly 2000 kcal
        // Need: (P*4 + C*4 + F*9) = 2000
        // P=50, C=50, F=200 -> 200 + 200 + 1800 = 2200 (too high)
        // P=100, C=200, F=80 -> 400 + 800 + 720 = 1920 (close)
        // Just test the math directly
        let meal = makeMeal(type: .breakfast, protein: 100, carbs: 200, fat: 80)
        let draft = makeDraft(meals: [meal])
        // totalCal = 400+800+720 = 1920
        let adherence = draft.calorieAdherencePercentage(tdee: 1920)
        XCTAssertEqual(adherence, 100.0, accuracy: 0.01)
        XCTAssertEqual(draft.totalCalories, 1920.0, accuracy: 0.01)
        XCTAssertTrue(adherence >= 99.9 && adherence <= 100.1)
    }

    // MARK: - Draft Status

    func testDraftStatusPendingReview() {
        let draft = makeDraft(status: .pendingReview)
        XCTAssertEqual(draft.status, .pendingReview)
        XCTAssertEqual(draft.status.rawValue, "pending_review")
        XCTAssertNotEqual(draft.status, .approved)
    }

    func testDraftStatusApproved() {
        let draft = makeDraft(status: .approved)
        XCTAssertEqual(draft.status, .approved)
        XCTAssertEqual(draft.status.rawValue, "approved")
        XCTAssertNotEqual(draft.status, .discarded)
    }

    func testDraftStatusDiscarded() {
        let draft = makeDraft(status: .discarded)
        XCTAssertEqual(draft.status, .discarded)
        XCTAssertEqual(draft.status.rawValue, "discarded")
        XCTAssertNotEqual(draft.status, .pendingReview)
    }
}
