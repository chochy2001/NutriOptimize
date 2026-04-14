import XCTest
@testable import NutriOptimize

final class PDFExportServiceTests: XCTestCase {

    private let pdfService = PDFExportService()

    private var samplePatient: Patient {
        Patient(
            id: UUID(),
            fullName: "María García López",
            age: 35,
            sex: .female,
            weight: 68.5,
            height: 162,
            bodyFatPercentage: 32,
            allergies: ["Gluten", "Mariscos"],
            medicalConditions: ["Hipotiroidismo"],
            dietaryPreferences: ["Comida mexicana"],
            clinicalGoals: "Pérdida de peso gradual",
            availableCookingTime: 30,
            activityLevel: .lightlyActive,
            monthlyFoodBudget: 4500
        )
    }

    private var sampleDraft: PlanOptimizationDraft {
        PlanOptimizationDraft(
            id: UUID(),
            patientId: samplePatient.id,
            status: .approved,
            calculatedRationale: "Plan diseñado para pérdida de peso gradual con TDEE estimado de 1800 kcal.",
            meals: [
                Meal(type: .breakfast, name: "Bowl de avena", ingredients: ["Avena", "Fresas"], macros: Macros(protein: 12, carbohydrates: 45, fat: 8)),
                Meal(type: .lunch, name: "Pollo con quinoa", ingredients: ["Pollo", "Quinoa", "Brócoli"], macros: Macros(protein: 38, carbohydrates: 42, fat: 14)),
                Meal(type: .snack, name: "Yogur con almendras", ingredients: ["Yogur", "Almendras"], macros: Macros(protein: 10, carbohydrates: 15, fat: 12)),
                Meal(type: .dinner, name: "Salmón con ensalada", ingredients: ["Salmón", "Espinacas", "Aguacate"], macros: Macros(protein: 34, carbohydrates: 12, fat: 22))
            ],
            createdAt: .now
        )
    }

    // MARK: - PDF Generation

    func testPDFGenerationReturnsNonEmptyData() {
        let data = pdfService.generatePDF(for: sampleDraft, patient: samplePatient)
        XCTAssertFalse(data.isEmpty)
        XCTAssertGreaterThan(data.count, 0)
        XCTAssertGreaterThan(data.count, 100)
    }

    func testPDFDataIsValidPDF() {
        let data = pdfService.generatePDF(for: sampleDraft, patient: samplePatient)
        // PDF files start with %PDF header
        let headerBytes = [UInt8](data.prefix(4))
        let headerString = String(bytes: headerBytes, encoding: .ascii)
        XCTAssertEqual(headerString, "%PDF")
        XCTAssertFalse(data.isEmpty)
        XCTAssertGreaterThan(data.count, 4)
    }

    func testPDFGenerationWithMinimalDraft() {
        let minimalDraft = PlanOptimizationDraft(
            id: UUID(),
            patientId: samplePatient.id,
            status: .pendingReview,
            calculatedRationale: "Minimal test",
            meals: [
                Meal(type: .breakfast, name: "Test", ingredients: ["A"], macros: Macros(protein: 10, carbohydrates: 20, fat: 5))
            ],
            createdAt: .now
        )
        let data = pdfService.generatePDF(for: minimalDraft, patient: samplePatient)
        XCTAssertFalse(data.isEmpty)
        let headerBytes = [UInt8](data.prefix(4))
        let headerString = String(bytes: headerBytes, encoding: .ascii)
        XCTAssertEqual(headerString, "%PDF")
        XCTAssertGreaterThan(data.count, 100)
    }

    func testPDFGenerationWithPatientWithoutAllergies() {
        let patient = Patient(
            id: UUID(),
            fullName: "Sin Alergias",
            age: 25,
            sex: .male,
            weight: 75.0,
            height: 178,
            bodyFatPercentage: nil,
            allergies: [],
            medicalConditions: [],
            dietaryPreferences: [],
            clinicalGoals: "Mantener peso",
            availableCookingTime: 45,
            activityLevel: .moderatelyActive
        )
        let data = pdfService.generatePDF(for: sampleDraft, patient: patient)
        XCTAssertFalse(data.isEmpty)
        XCTAssertGreaterThan(data.count, 0)
        let headerString = String(bytes: [UInt8](data.prefix(4)), encoding: .ascii)
        XCTAssertEqual(headerString, "%PDF")
    }

    func testPDFGenerationWithManyMeals() {
        let meals = (0..<10).map { i in
            Meal(
                type: MealType.allCases[i % MealType.allCases.count],
                name: "Comida \(i)",
                ingredients: ["Ingrediente A", "Ingrediente B", "Ingrediente C"],
                macros: Macros(protein: Double(10 + i), carbohydrates: Double(20 + i), fat: Double(5 + i))
            )
        }
        let draft = PlanOptimizationDraft(
            id: UUID(),
            patientId: samplePatient.id,
            status: .approved,
            calculatedRationale: "Plan con muchas comidas para probar paginación",
            meals: meals,
            createdAt: .now
        )
        let data = pdfService.generatePDF(for: draft, patient: samplePatient)
        XCTAssertFalse(data.isEmpty)
        XCTAssertGreaterThan(data.count, 0)
        let headerString = String(bytes: [UInt8](data.prefix(4)), encoding: .ascii)
        XCTAssertEqual(headerString, "%PDF")
    }
}
