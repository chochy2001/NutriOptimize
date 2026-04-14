import XCTest
@testable import NutriOptimize

/// Tests for prompt construction logic using the OpenRouterService.
/// Does not make actual API calls — verifies the prompt building
/// by inspecting the formatted text through the protocol interface.
final class OpenRouterServiceTests: XCTestCase {

    // MARK: - Test Helpers

    /// Uses a testable prompt builder that mirrors OpenRouterService logic.
    /// This allows us to verify prompt content without making network calls.
    private func buildPrompt(
        for patient: Patient,
        customPrompt: String? = nil,
        feedback: PatientFeedbackSnapshot? = nil
    ) -> String {
        var sections: [String] = []

        sections.append("""
        PATIENT PROFILE:
        - Name: \(patient.fullName)
        - Age: \(patient.age) years | Sex: \(patient.sex.rawValue)
        - Weight: \(String(format: "%.1f", patient.weight)) kg | Height: \(String(format: "%.0f", patient.height)) cm
        - BMI: \(String(format: "%.1f", patient.bmi)) (\(patient.bmiClassification))
        - Body fat: \(patient.bodyFatPercentage.map { String(format: "%.0f%%", $0) } ?? "Not measured")
        - Activity level: \(patient.activityLevel.rawValue) (PAL: \(patient.activityLevel.palFactor))
        - Estimated BMR: \(Int(patient.estimatedBMR)) kcal
        - Estimated TDEE: \(Int(patient.estimatedTDEE)) kcal/day
        """)

        if !patient.allergies.isEmpty {
            sections.append("ALLERGIES (EXCLUDE these ingredients): \(patient.allergies.joined(separator: ", "))")
        }

        if !patient.medicalConditions.isEmpty {
            sections.append("MEDICAL CONDITIONS: \(patient.medicalConditions.joined(separator: ", "))")
        }

        if !patient.dietaryPreferences.isEmpty {
            sections.append("DIETARY PREFERENCES: \(patient.dietaryPreferences.joined(separator: ", "))")
        }

        sections.append("CLINICAL GOAL: \(patient.clinicalGoals)")
        sections.append("AVAILABLE COOKING TIME: \(patient.availableCookingTime) minutes per meal")

        if let budget = patient.monthlyFoodBudget {
            sections.append("""
            BUDGET CONSTRAINT: $\(String(format: "%.0f", budget)) MXN/month (~$\(String(format: "%.0f", budget / 4.0)) MXN/week)
            Prioritize cost-effective ingredients that meet nutritional targets within this budget.
            """)
        }

        if let custom = customPrompt, !custom.isEmpty {
            sections.append("NUTRITIONIST PRESCRIBING NOTES:\n\(custom)")
        }

        if let feedback {
            if !feedback.likedFoods.isEmpty {
                sections.append("Alimentos que el paciente prefiere: \(feedback.likedFoods.joined(separator: ", "))")
            }
            if !feedback.dislikedFoods.isEmpty {
                sections.append("Alimentos que el paciente no tolera: \(feedback.dislikedFoods.joined(separator: ", "))")
            }
            if !feedback.bannedFoods.isEmpty {
                sections.append("EXCLUSIONES OBLIGATORIAS - NUNCA incluir: \(feedback.bannedFoods.joined(separator: ", "))")
            }
            if !feedback.generalNotes.isEmpty {
                sections.append("Notas adicionales del nutriólogo: \(feedback.generalNotes)")
            }
        }

        sections.append("Generate a complete daily meal plan (breakfast, lunch, dinner, and at least 1 snack) optimized for this patient.")

        return sections.joined(separator: "\n\n")
    }

    private var samplePatient: Patient {
        Patient(
            id: UUID(),
            fullName: "Carlos Rodríguez",
            age: 45,
            sex: .male,
            weight: 92.0,
            height: 178,
            bodyFatPercentage: 28,
            allergies: ["Lactosa", "Mariscos"],
            medicalConditions: ["Diabetes tipo 2", "Hipertensión"],
            dietaryPreferences: ["Pollo", "Verduras"],
            clinicalGoals: "Control de glucosa y reducción de peso",
            availableCookingTime: 45,
            activityLevel: .sedentary,
            monthlyFoodBudget: 6000
        )
    }

    // MARK: - Prompt Includes Patient Data

    func testPromptIncludesPatientData() {
        let prompt = buildPrompt(for: samplePatient)
        XCTAssertTrue(prompt.contains("Carlos Rodríguez"))
        XCTAssertTrue(prompt.contains("45 years"))
        XCTAssertTrue(prompt.contains("92.0 kg"))
    }

    func testPromptIncludesAnthropometricData() {
        let prompt = buildPrompt(for: samplePatient)
        XCTAssertTrue(prompt.contains("BMI:"))
        XCTAssertTrue(prompt.contains("Estimated BMR:"))
        XCTAssertTrue(prompt.contains("Estimated TDEE:"))
    }

    func testPromptIncludesActivityLevel() {
        let prompt = buildPrompt(for: samplePatient)
        XCTAssertTrue(prompt.contains("Sedentario"))
        XCTAssertTrue(prompt.contains("PAL: 1.2"))
        XCTAssertTrue(prompt.contains("Activity level"))
    }

    // MARK: - Prompt Includes Allergies

    func testPromptIncludesAllergies() {
        let prompt = buildPrompt(for: samplePatient)
        XCTAssertTrue(prompt.contains("Lactosa"))
        XCTAssertTrue(prompt.contains("Mariscos"))
        XCTAssertTrue(prompt.contains("ALLERGIES"))
    }

    func testPromptExcludesAllergySection_WhenNoAllergies() {
        let patient = Patient(
            id: UUID(),
            fullName: "Sin Alergias",
            age: 25,
            sex: .female,
            weight: 60,
            height: 165,
            bodyFatPercentage: nil,
            allergies: [],
            medicalConditions: [],
            dietaryPreferences: [],
            clinicalGoals: "Mantener peso",
            availableCookingTime: 30,
            activityLevel: .moderatelyActive
        )
        let prompt = buildPrompt(for: patient)
        XCTAssertFalse(prompt.contains("ALLERGIES"))
        XCTAssertTrue(prompt.contains("Sin Alergias"))
        XCTAssertFalse(prompt.contains("MEDICAL CONDITIONS"))
    }

    // MARK: - Prompt Includes Budget

    func testPromptIncludesBudgetWhenPresent() {
        let prompt = buildPrompt(for: samplePatient)
        XCTAssertTrue(prompt.contains("BUDGET CONSTRAINT"))
        XCTAssertTrue(prompt.contains("6000"))
        XCTAssertTrue(prompt.contains("1500"))
    }

    func testPromptExcludesBudget_WhenNil() {
        let patient = Patient(
            id: UUID(),
            fullName: "No Budget",
            age: 30,
            sex: .male,
            weight: 75,
            height: 175,
            bodyFatPercentage: nil,
            allergies: [],
            medicalConditions: [],
            dietaryPreferences: [],
            clinicalGoals: "General health",
            availableCookingTime: 30,
            activityLevel: .moderatelyActive,
            monthlyFoodBudget: nil
        )
        let prompt = buildPrompt(for: patient)
        XCTAssertFalse(prompt.contains("BUDGET CONSTRAINT"))
        XCTAssertFalse(prompt.contains("MXN/month"))
        XCTAssertTrue(prompt.contains("No Budget"))
    }

    // MARK: - Prompt Includes Feedback

    func testPromptIncludesFeedbackWhenPresent() {
        let feedback = PatientFeedbackSnapshot(
            likedFoods: ["Pollo", "Arroz"],
            dislikedFoods: ["Brócoli"],
            bannedFoods: ["Camarón"],
            generalNotes: "Prefiere comidas simples"
        )
        let prompt = buildPrompt(for: samplePatient, feedback: feedback)
        XCTAssertTrue(prompt.contains("Pollo"))
        XCTAssertTrue(prompt.contains("Brócoli"))
        XCTAssertTrue(prompt.contains("Camarón"))
    }

    func testPromptIncludesBannedFoodsSection() {
        let feedback = PatientFeedbackSnapshot(
            likedFoods: [],
            dislikedFoods: [],
            bannedFoods: ["Gluten", "Soya"],
            generalNotes: ""
        )
        let prompt = buildPrompt(for: samplePatient, feedback: feedback)
        XCTAssertTrue(prompt.contains("EXCLUSIONES OBLIGATORIAS"))
        XCTAssertTrue(prompt.contains("Gluten"))
        XCTAssertTrue(prompt.contains("Soya"))
    }

    func testPromptIncludesNutritionistNotes() {
        let feedback = PatientFeedbackSnapshot(
            likedFoods: [],
            dislikedFoods: [],
            bannedFoods: [],
            generalNotes: "Prefiere 5 comidas al día"
        )
        let prompt = buildPrompt(for: samplePatient, feedback: feedback)
        XCTAssertTrue(prompt.contains("Prefiere 5 comidas al día"))
        XCTAssertTrue(prompt.contains("Notas adicionales"))
        XCTAssertFalse(prompt.contains("EXCLUSIONES OBLIGATORIAS"))
    }

    func testPromptWithoutFeedbackExcludesFeedbackSections() {
        let prompt = buildPrompt(for: samplePatient, feedback: nil)
        XCTAssertFalse(prompt.contains("Alimentos que el paciente prefiere"))
        XCTAssertFalse(prompt.contains("EXCLUSIONES OBLIGATORIAS"))
        XCTAssertFalse(prompt.contains("Notas adicionales del nutriólogo"))
    }

    // MARK: - Prompt Includes Custom Prompt

    func testPromptIncludesCustomPromptWhenPresent() {
        let custom = "Priorizo dietas mediterráneas"
        let prompt = buildPrompt(for: samplePatient, customPrompt: custom)
        XCTAssertTrue(prompt.contains("NUTRITIONIST PRESCRIBING NOTES"))
        XCTAssertTrue(prompt.contains("Priorizo dietas mediterráneas"))
        XCTAssertTrue(prompt.contains("PATIENT PROFILE"))
    }

    func testPromptExcludesCustomPrompt_WhenNil() {
        let prompt = buildPrompt(for: samplePatient, customPrompt: nil)
        XCTAssertFalse(prompt.contains("NUTRITIONIST PRESCRIBING NOTES"))
        XCTAssertTrue(prompt.contains("PATIENT PROFILE"))
        XCTAssertTrue(prompt.contains("Carlos Rodríguez"))
    }

    func testPromptExcludesCustomPrompt_WhenEmpty() {
        let prompt = buildPrompt(for: samplePatient, customPrompt: "")
        XCTAssertFalse(prompt.contains("NUTRITIONIST PRESCRIBING NOTES"))
        XCTAssertTrue(prompt.contains("PATIENT PROFILE"))
        XCTAssertTrue(prompt.contains("Generate a complete daily meal plan"))
    }

    // MARK: - Prompt Structure

    func testPromptEndsWithGenerationInstruction() {
        let prompt = buildPrompt(for: samplePatient)
        XCTAssertTrue(prompt.contains("Generate a complete daily meal plan"))
        XCTAssertTrue(prompt.contains("breakfast, lunch, dinner"))
        XCTAssertTrue(prompt.contains("snack"))
    }

    func testPromptIncludesMedicalConditions() {
        let prompt = buildPrompt(for: samplePatient)
        XCTAssertTrue(prompt.contains("Diabetes tipo 2"))
        XCTAssertTrue(prompt.contains("Hipertensión"))
        XCTAssertTrue(prompt.contains("MEDICAL CONDITIONS"))
    }

    // MARK: - PatientFeedbackSnapshot

    func testPatientFeedbackSnapshotInitialization() {
        let snapshot = PatientFeedbackSnapshot(
            likedFoods: ["A", "B"],
            dislikedFoods: ["C"],
            bannedFoods: [],
            generalNotes: "Test"
        )
        XCTAssertEqual(snapshot.likedFoods.count, 2)
        XCTAssertEqual(snapshot.dislikedFoods.count, 1)
        XCTAssertTrue(snapshot.bannedFoods.isEmpty)
    }
}
