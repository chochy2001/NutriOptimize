import XCTest
@testable import NutriOptimize

/// Tests for prompt construction logic using the OpenRouterService.
/// Does not make actual API calls - verifies the prompt building
/// by inspecting the formatted text through the protocol interface.
final class OpenRouterServiceTests: XCTestCase {

    // MARK: - Test Helpers

    /// Calls the REAL production prompt builder (now exposed as a static method)
    /// so these tests verify the shipped behavior instead of a divergent copy.
    private func buildPrompt(
        for patient: Patient,
        customPrompt: String? = nil,
        feedback: PatientFeedbackSnapshot? = nil
    ) -> String {
        OpenRouterService.buildUserPrompt(for: patient, customPrompt: customPrompt, feedback: feedback)
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
        XCTAssertTrue(prompt.contains("45 years"))
        XCTAssertTrue(prompt.contains("92.0 kg"))
    }

    /// The patient's full name must NOT be transmitted; only a non-identifying
    /// initials-based pseudonym is sent.
    func testPromptDoesNotIncludeFullName() {
        let prompt = buildPrompt(for: samplePatient)
        XCTAssertFalse(prompt.contains("Carlos Rodríguez"))
        XCTAssertFalse(prompt.contains("Name:"))
        XCTAssertTrue(prompt.contains("Reference:"))
        XCTAssertTrue(prompt.contains(samplePatient.pseudonym))
        XCTAssertEqual(samplePatient.pseudonym, "C.R.")
    }

    func testPseudonymUsesInitials() {
        let patient = Patient(
            id: UUID(),
            fullName: "Roberto Hernández Díaz",
            age: 45, sex: .male, weight: 100, height: 175,
            bodyFatPercentage: nil, allergies: [], medicalConditions: [],
            dietaryPreferences: [], clinicalGoals: "Test",
            availableCookingTime: 30, activityLevel: .sedentary
        )
        XCTAssertEqual(patient.pseudonym, "R.H.D.")
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
        XCTAssertTrue(prompt.contains("PATIENT PROFILE"))
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
        XCTAssertTrue(prompt.contains("PATIENT PROFILE"))
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
        XCTAssertTrue(prompt.contains(samplePatient.pseudonym))
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

    // MARK: - Data-processing consent gate

    func testConsentFlagRoundTrips() {
        let original = OpenRouterService.hasDataProcessingConsent
        defer { OpenRouterService.hasDataProcessingConsent = original }

        OpenRouterService.hasDataProcessingConsent = false
        XCTAssertFalse(OpenRouterService.hasDataProcessingConsent)
        OpenRouterService.hasDataProcessingConsent = true
        XCTAssertTrue(OpenRouterService.hasDataProcessingConsent)
    }

    /// With consent NOT granted, the engine must refuse to run and surface the
    /// consent error rather than sending any patient data. (The Keychain write
    /// of the API key may not persist on every test host; when it does, we
    /// expect `.consentRequired`, otherwise the earlier `.invalidData` key
    /// guard fires — either way no network request is made.)
    func testGenerateThrowsConsentRequired_WhenConsentMissing() async {
        let originalConsent = OpenRouterService.hasDataProcessingConsent
        let originalKey = OpenRouterService.apiKey
        defer {
            OpenRouterService.hasDataProcessingConsent = originalConsent
            OpenRouterService.apiKey = originalKey
        }

        OpenRouterService.apiKey = "test-key-not-used-because-consent-blocks-first"
        OpenRouterService.hasDataProcessingConsent = false

        do {
            _ = try await OpenRouterService().generateOptimizedPlan(for: samplePatient, customPrompt: nil, feedback: nil)
            XCTFail("Expected the engine to refuse without consent")
        } catch let error as ServiceError {
            if OpenRouterService.apiKey.isEmpty {
                XCTAssertEqual(error, .invalidData, "Key did not persist; expected the key guard to fire")
            } else {
                XCTAssertEqual(error, .consentRequired)
            }
        } catch {
            XCTFail("Expected a ServiceError, got \(error)")
        }
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
