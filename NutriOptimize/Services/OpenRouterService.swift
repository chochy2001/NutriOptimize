import Foundation
import Security
import SwiftData

/// Protocol for the optimization engine that generates meal plan proposals.
/// Decoupled from the specific backend to allow mock and production implementations.
protocol OptimizationEngineProtocol: Sendable {
    func generateOptimizedPlan(for patient: Patient, customPrompt: String?, feedback: PatientFeedbackSnapshot?) async throws -> PlanOptimizationDraft
}

/// Lightweight, Sendable snapshot of patient feedback for use in async contexts.
struct PatientFeedbackSnapshot: Sendable {
    let likedFoods: [String]
    let dislikedFoods: [String]
    let bannedFoods: [String]
    let generalNotes: String
}

// MARK: - Keychain Helper

/// Provides secure storage for sensitive strings using the system Keychain.
/// Uses kSecClassGenericPassword items with a fixed service identifier.
private enum KeychainHelper {

    private static let service = "com.nutrioptimize.api"

    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Remove any existing item first to avoid errSecDuplicateItem
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String:   data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)
    }
}

/// Production implementation of the optimization engine backed by OpenRouter.
/// Sends patient clinical data to a large language model and parses structured
/// meal plan responses with macro breakdowns and rationale.
final class OpenRouterService: OptimizationEngineProtocol, Sendable {

    private static let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    private static let model = "google/gemini-2.5-flash"
    private static let apiKeyKey = "openrouter_api_key"
    private static let customPromptKey = "custom_optimization_prompt"
    private static let dataProcessingConsentKey = "data_processing_consent_accepted"

    // MARK: - Settings Accessors

    static var apiKey: String {
        get { KeychainHelper.load(key: apiKeyKey) ?? "" }
        set { KeychainHelper.save(key: apiKeyKey, value: newValue) }
    }

    static var customPrompt: String {
        get { UserDefaults.standard.string(forKey: customPromptKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: customPromptKey) }
    }

    static var isConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Whether the professional has accepted the data-processing disclosure.
    /// This consent gate must be `true` before any patient clinical data is
    /// sent to the external optimization engine (OpenRouter / Gemini). It is
    /// persisted per device/professional in `UserDefaults`.
    static var hasDataProcessingConsent: Bool {
        get { UserDefaults.standard.bool(forKey: dataProcessingConsentKey) }
        set { UserDefaults.standard.set(newValue, forKey: dataProcessingConsentKey) }
    }

    // MARK: - Plan Generation

    func generateOptimizedPlan(for patient: Patient, customPrompt: String?, feedback: PatientFeedbackSnapshot? = nil) async throws -> PlanOptimizationDraft {
        let apiKey = Self.apiKey
        guard !apiKey.isEmpty else { throw ServiceError.invalidData }

        // Gate: never send patient clinical data off-device without an
        // explicit, recorded data-processing consent from the professional.
        guard Self.hasDataProcessingConsent else { throw ServiceError.consentRequired }

        let systemPrompt = buildSystemPrompt()
        let userPrompt = Self.buildUserPrompt(for: patient, customPrompt: customPrompt, feedback: feedback)

        let requestBody = OpenRouterRequest(
            model: Self.model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt)
            ],
            temperature: 0.4,
            maxTokens: 4096,
            responseFormat: .init(type: "json_object")
        )

        var request = URLRequest(url: URL(string: Self.baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("NutriOptimize/1.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("NutriOptimize", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONEncoder().encode(requestBody)
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ServiceError.networkFailure
        }

        let openRouterResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)

        guard let content = openRouterResponse.choices.first?.message.content else {
            throw ServiceError.optimizationFailed
        }

        // Store the raw exchange for the debug view
        EngineDebugStore.shared.lastPrompt = userPrompt
        EngineDebugStore.shared.lastResponse = content

        return try parsePlanResponse(content, patientId: patient.id)
    }

    // MARK: - Prompt Construction

    private func buildSystemPrompt() -> String {
        """
        You are a clinical nutrition optimization engine. You analyze patient profiles \
        and generate evidence-based meal plans with precise macronutrient calculations.

        CRITICAL RULES:
        - All meals must respect the patient's allergies and medical conditions
        - Use Mifflin-St Jeor equation for BMR and apply the PAL factor for TDEE
        - Provide a clinical rationale explaining your macro distribution choices
        - If a budget constraint exists, prioritize cost-effective ingredients
        - Respond ONLY with valid JSON matching the specified schema
        - All food names and descriptions must be in Spanish (Mexico)
        - Portion descriptions must include gram weights or volume measures

        JSON RESPONSE SCHEMA:
        {
          "rationale": "string - Clinical reasoning for this plan",
          "meals": [
            {
              "type": "breakfast|lunch|dinner|snack",
              "name": "string - Meal name in Spanish",
              "ingredients": ["string"],
              "protein": number,
              "carbohydrates": number,
              "fat": number,
              "portionDescription": "string - Portion sizes"
            }
          ]
        }
        """
    }

    /// Builds the user prompt sent to the language model.
    ///
    /// The patient's full name is deliberately NOT transmitted: the model never
    /// needs it to generate a plan (the response is correlated back to the
    /// patient locally via `patientId`). We send a non-identifying pseudonym
    /// (initials) instead, minimizing the PHI that leaves the device.
    ///
    /// Exposed as `static` so the unit tests can verify the real production
    /// builder instead of duplicating its logic.
    static func buildUserPrompt(for patient: Patient, customPrompt: String?, feedback: PatientFeedbackSnapshot? = nil) -> String {
        var sections: [String] = []

        sections.append("""
        PATIENT PROFILE:
        - Reference: \(patient.pseudonym)
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

        // Patient feedback from the nutritionist's preference tracking
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

    // MARK: - Response Parsing

    private func parsePlanResponse(_ json: String, patientId: UUID) throws -> PlanOptimizationDraft {
        guard let data = json.data(using: .utf8) else {
            throw ServiceError.invalidData
        }

        let parsed = try JSONDecoder().decode(EngineResponse.self, from: data)

        let meals = parsed.meals.map { mealData -> Meal in
            Meal(
                type: mealData.parsedType,
                name: mealData.name,
                ingredients: mealData.ingredients,
                macros: Macros(
                    protein: mealData.protein,
                    carbohydrates: mealData.carbohydrates,
                    fat: mealData.fat
                ),
                portionDescription: mealData.portionDescription
            )
        }

        return PlanOptimizationDraft(
            id: UUID(),
            patientId: patientId,
            status: .pendingReview,
            calculatedRationale: parsed.rationale,
            meals: meals,
            createdAt: .now
        )
    }
}

// MARK: - Request/Response DTOs

private struct OpenRouterRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let maxTokens: Int
    let responseFormat: ResponseFormat

    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct ResponseFormat: Encodable {
        let type: String
    }

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
        case responseFormat = "response_format"
    }
}

private struct OpenRouterResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String?
    }
}

private struct EngineResponse: Decodable {
    let rationale: String
    let meals: [MealData]

    struct MealData: Decodable {
        let type: String
        let name: String
        let ingredients: [String]
        let protein: Double
        let carbohydrates: Double
        let fat: Double
        let portionDescription: String

        var parsedType: MealType {
            switch type.lowercased() {
            case "breakfast", "desayuno": return .breakfast
            case "lunch", "comida", "almuerzo": return .lunch
            case "dinner", "cena": return .dinner
            case "snack", "colacion", "colaci\u{00F3}n": return .snack
            default: return .snack
            }
        }
    }
}

// MARK: - Debug Store

/// Stores the last prompt/response exchange for professional inspection.
/// Allows nutritionists to verify the engine's reasoning and input data.
final class EngineDebugStore: ObservableObject {
    static let shared = EngineDebugStore()

    @Published var lastPrompt: String = ""
    @Published var lastResponse: String = ""

    private init() {}
}
