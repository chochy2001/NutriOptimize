import XCTest
@testable import NutriOptimize

final class PatientModelTests: XCTestCase {

    // MARK: - Test Helpers

    private func makePatient(
        sex: Patient.BiologicalSex = .male,
        weight: Double = 80.0,
        height: Double = 175.0,
        age: Int = 30,
        activityLevel: Patient.ActivityLevel = .moderatelyActive,
        monthlyBudget: Double? = nil
    ) -> Patient {
        Patient(
            id: UUID(),
            fullName: "Test Patient",
            age: age,
            sex: sex,
            weight: weight,
            height: height,
            bodyFatPercentage: nil,
            allergies: [],
            medicalConditions: [],
            dietaryPreferences: [],
            clinicalGoals: "Mantener peso",
            availableCookingTime: 30,
            activityLevel: activityLevel,
            monthlyFoodBudget: monthlyBudget
        )
    }

    // MARK: - BMI Calculation

    func testBMICalculation() {
        let patient = makePatient(weight: 80.0, height: 175.0)
        let expectedBMI = 80.0 / (1.75 * 1.75) // ~26.12
        XCTAssertEqual(patient.bmi, expectedBMI, accuracy: 0.01)
        XCTAssertGreaterThan(patient.bmi, 0)
        XCTAssertLessThan(patient.bmi, 100)
    }

    func testBMIWithZeroHeight() {
        let patient = makePatient(weight: 70.0, height: 0.0)
        XCTAssertEqual(patient.bmi, 0)
        XCTAssertFalse(patient.bmi.isNaN)
        XCTAssertFalse(patient.bmi.isInfinite)
    }

    func testBMIKnownValues() {
        // 70 kg, 170 cm -> BMI = 70 / (1.7^2) = 24.22
        let patient = makePatient(weight: 70.0, height: 170.0)
        XCTAssertEqual(patient.bmi, 70.0 / (1.70 * 1.70), accuracy: 0.01)
        XCTAssertEqual(patient.bmi, 24.22, accuracy: 0.01)
        XCTAssertTrue(patient.bmi > 18.5 && patient.bmi < 25)
    }

    // MARK: - BMI Classification

    func testBMIClassificationBajoPeso() {
        let patient = makePatient(weight: 45.0, height: 170.0) // BMI ~15.57
        XCTAssertEqual(patient.bmiClassification, "Bajo peso")
        XCTAssertLessThan(patient.bmi, 18.5)
        XCTAssertGreaterThan(patient.bmi, 0)
    }

    func testBMIClassificationNormal() {
        let patient = makePatient(weight: 65.0, height: 170.0) // BMI ~22.49
        XCTAssertEqual(patient.bmiClassification, "Normal")
        XCTAssertGreaterThanOrEqual(patient.bmi, 18.5)
        XCTAssertLessThan(patient.bmi, 25.0)
    }

    func testBMIClassificationSobrepeso() {
        let patient = makePatient(weight: 80.0, height: 170.0) // BMI ~27.68
        XCTAssertEqual(patient.bmiClassification, "Sobrepeso")
        XCTAssertGreaterThanOrEqual(patient.bmi, 25.0)
        XCTAssertLessThan(patient.bmi, 30.0)
    }

    func testBMIClassificationObesidad() {
        let patient = makePatient(weight: 110.0, height: 170.0) // BMI ~38.06
        XCTAssertEqual(patient.bmiClassification, "Obesidad")
        XCTAssertGreaterThanOrEqual(patient.bmi, 30.0)
        XCTAssertTrue(patient.bmiClassification == "Obesidad")
    }

    // MARK: - Estimated BMR (Mifflin-St Jeor)

    func testEstimatedBMRMale() {
        // Male, 80 kg, 175 cm, 30 years
        // (10 * 80) + (6.25 * 175) - (5 * 30) + 5 = 800 + 1093.75 - 150 + 5 = 1748.75
        let patient = makePatient(sex: .male, weight: 80.0, height: 175.0, age: 30)
        XCTAssertEqual(patient.estimatedBMR, 1748.75, accuracy: 0.01)
        XCTAssertGreaterThan(patient.estimatedBMR, 0)
        XCTAssertGreaterThan(patient.estimatedBMR, 1000)
    }

    func testEstimatedBMRFemale() {
        // Female, 60 kg, 160 cm, 25 years
        // (10 * 60) + (6.25 * 160) - (5 * 25) - 161 = 600 + 1000 - 125 - 161 = 1314
        let patient = makePatient(sex: .female, weight: 60.0, height: 160.0, age: 25)
        XCTAssertEqual(patient.estimatedBMR, 1314.0, accuracy: 0.01)
        XCTAssertGreaterThan(patient.estimatedBMR, 0)
        XCTAssertLessThan(patient.estimatedBMR, 3000)
    }

    func testEstimatedBMRDifferenceBetweenSexes() {
        let male = makePatient(sex: .male, weight: 70.0, height: 170.0, age: 30)
        let female = makePatient(sex: .female, weight: 70.0, height: 170.0, age: 30)
        // Male should have higher BMR (offset +5 vs -161)
        XCTAssertGreaterThan(male.estimatedBMR, female.estimatedBMR)
        XCTAssertEqual(male.estimatedBMR - female.estimatedBMR, 166.0, accuracy: 0.01)
        XCTAssertGreaterThan(female.estimatedBMR, 0)
    }

    // MARK: - Estimated TDEE

    func testEstimatedTDEESedentary() {
        let patient = makePatient(activityLevel: .sedentary)
        let expectedTDEE = patient.estimatedBMR * 1.2
        XCTAssertEqual(patient.estimatedTDEE, expectedTDEE, accuracy: 0.01)
        XCTAssertGreaterThan(patient.estimatedTDEE, patient.estimatedBMR)
        XCTAssertEqual(Patient.ActivityLevel.sedentary.palFactor, 1.2)
    }

    func testEstimatedTDEEAthlete() {
        let patient = makePatient(activityLevel: .athlete)
        let expectedTDEE = patient.estimatedBMR * 1.9
        XCTAssertEqual(patient.estimatedTDEE, expectedTDEE, accuracy: 0.01)
        XCTAssertGreaterThan(patient.estimatedTDEE, patient.estimatedBMR)
        XCTAssertEqual(Patient.ActivityLevel.athlete.palFactor, 1.9)
    }

    func testEstimatedTDEEIncreasesWithActivity() {
        let sedentary = makePatient(activityLevel: .sedentary)
        let light = makePatient(activityLevel: .lightlyActive)
        let moderate = makePatient(activityLevel: .moderatelyActive)
        let veryActive = makePatient(activityLevel: .veryActive)
        let athlete = makePatient(activityLevel: .athlete)

        XCTAssertLessThan(sedentary.estimatedTDEE, light.estimatedTDEE)
        XCTAssertLessThan(light.estimatedTDEE, moderate.estimatedTDEE)
        XCTAssertLessThan(moderate.estimatedTDEE, veryActive.estimatedTDEE)
        XCTAssertLessThan(veryActive.estimatedTDEE, athlete.estimatedTDEE)
    }

    // MARK: - Weekly Food Budget

    func testWeeklyFoodBudgetWithMonthlyBudget() {
        let patient = makePatient(monthlyBudget: 4000.0)
        XCTAssertNotNil(patient.weeklyFoodBudget)
        XCTAssertEqual(patient.weeklyFoodBudget!, 1000.0, accuracy: 0.01)
        XCTAssertEqual(patient.weeklyFoodBudget!, patient.monthlyFoodBudget! / 4.0)
    }

    func testWeeklyFoodBudgetWithNilBudget() {
        let patient = makePatient(monthlyBudget: nil)
        XCTAssertNil(patient.weeklyFoodBudget)
        XCTAssertNil(patient.monthlyFoodBudget)
        XCTAssertTrue(patient.weeklyFoodBudget == nil)
    }

    func testWeeklyFoodBudgetWithZeroBudget() {
        let patient = makePatient(monthlyBudget: 0.0)
        XCTAssertNotNil(patient.weeklyFoodBudget)
        XCTAssertEqual(patient.weeklyFoodBudget!, 0.0, accuracy: 0.01)
        XCTAssertEqual(patient.weeklyFoodBudget!, 0.0)
    }

    // MARK: - PAL Factors

    func testAllActivityLevelPALFactors() {
        XCTAssertEqual(Patient.ActivityLevel.sedentary.palFactor, 1.2)
        XCTAssertEqual(Patient.ActivityLevel.lightlyActive.palFactor, 1.375)
        XCTAssertEqual(Patient.ActivityLevel.moderatelyActive.palFactor, 1.55)
        XCTAssertEqual(Patient.ActivityLevel.veryActive.palFactor, 1.725)
        XCTAssertEqual(Patient.ActivityLevel.athlete.palFactor, 1.9)
    }
}
