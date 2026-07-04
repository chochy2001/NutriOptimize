import XCTest
@testable import NutriOptimize

/// Verifies the `PlanOptimizationDraft` <-> `PlanDraftRecord` round trip. A
/// regression here corrupts saved drafts (meals encoded as JSON in `mealsData`).
final class PlanDraftRecordRoundTripTests: XCTestCase {

    private func sampleDraft(source: EngineSource = .engine) -> PlanOptimizationDraft {
        PlanOptimizationDraft(
            id: UUID(),
            patientId: UUID(),
            status: .pendingReview,
            calculatedRationale: "Motivo clínico",
            meals: [
                Meal(type: .breakfast, name: "Avena", ingredients: ["Avena", "Fresas"],
                     macros: Macros(protein: 12, carbohydrates: 45, fat: 8),
                     portionDescription: "1 bowl"),
                Meal(type: .lunch, name: "Pollo", ingredients: ["Pollo", "Quinoa"],
                     macros: Macros(protein: 38, carbohydrates: 42, fat: 14))
            ],
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            engineSource: source
        )
    }

    func testInitFromDraftThenToDraftPreservesEverything() {
        let draft = sampleDraft()
        let record = PlanDraftRecord(from: draft)
        let back = record.toDraft()

        XCTAssertEqual(back.id, draft.id)
        XCTAssertEqual(back.patientId, draft.patientId)
        XCTAssertEqual(back.status, draft.status)
        XCTAssertEqual(back.calculatedRationale, draft.calculatedRationale)
        XCTAssertEqual(back.createdAt, draft.createdAt)
        XCTAssertEqual(back.engineSource, draft.engineSource)
        XCTAssertEqual(back.meals.count, 2)
        XCTAssertEqual(back.meals.map(\.name), ["Avena", "Pollo"])
        XCTAssertEqual(back.meals[0].macros, draft.meals[0].macros)
        XCTAssertEqual(back.meals[0].portionDescription, "1 bowl")
    }

    func testDemoSourceSurvivesRoundTrip() {
        let record = PlanDraftRecord(from: sampleDraft(source: .demo))
        XCTAssertEqual(record.toDraft().engineSource, .demo)
        XCTAssertTrue(record.toDraft().isDemo)
    }

    func testUpdateFromDraftReplacesMealsAndStatus() {
        let record = PlanDraftRecord(from: sampleDraft())
        XCTAssertEqual(record.toDraft().meals.count, 2)

        var mutated = sampleDraft()
        mutated.status = .approved
        mutated.meals = [Meal(type: .dinner, name: "Cena única", ingredients: ["Pescado"],
                              macros: Macros(protein: 25, carbohydrates: 5, fat: 10))]
        record.update(from: mutated)

        let back = record.toDraft()
        XCTAssertEqual(back.status, .approved)
        XCTAssertEqual(back.meals.count, 1)
        XCTAssertEqual(back.meals.first?.name, "Cena única")
    }

    func testNilEngineSourceRawDefaultsToEngine() {
        // Simulate a legacy row created before engineSourceRaw existed.
        let record = PlanDraftRecord(from: sampleDraft(source: .demo))
        record.engineSourceRaw = nil
        XCTAssertEqual(record.toDraft().engineSource, .engine,
                       "A missing engine source must default to .engine, not mislabel as demo")
    }

    func testCorruptMealsDataDecodesToEmptyMeals() {
        let record = PlanDraftRecord(from: sampleDraft())
        record.mealsData = Data("not valid meal json".utf8)
        XCTAssertTrue(record.toDraft().meals.isEmpty, "Undecodable meal data yields an empty meal list, not a crash")
    }
}
