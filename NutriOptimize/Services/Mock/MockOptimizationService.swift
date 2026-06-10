import Foundation

final class MockOptimizationService: OptimizationServiceProtocol {

    /// Builds a DEMONSTRATION plan optimization draft.
    ///
    /// This service runs only when no optimization engine is configured. It
    /// produces a sample plan that the UI must surface as a demo (never as a
    /// validated clinical proposal). Meals that conflict with the patient's
    /// recorded allergies are removed so the demo never proposes an allergen,
    /// and the rationale states explicitly that no engine ran.
    func generateDraft(for patient: Patient) async throws -> PlanOptimizationDraft {
        // Simulates engine processing - the production service calls the backend
        try await Task.sleep(for: .seconds(3))

        let meals = buildOptimizedMeals(for: patient)
        let rationale = buildRationale(for: patient, filteredMealCount: meals.count)

        return PlanOptimizationDraft(
            id: UUID(),
            patientId: patient.id,
            status: .pendingReview,
            calculatedRationale: rationale,
            meals: meals,
            createdAt: .now,
            engineSource: .demo
        )
    }

    func fetchPendingDrafts() async throws -> [PlanOptimizationDraft] {
        try await Task.sleep(for: .milliseconds(400))

        let patients = MockPatientService.samplePatients
        guard patients.count >= 2 else { return [] }

        return [
            PlanOptimizationDraft(
                id: UUID(),
                patientId: patients[0].id,
                status: .pendingReview,
                calculatedRationale: "[Demostración] Plan de ejemplo con énfasis en regulación tiroidea. TDEE estimado: \(Int(patients[0].estimatedTDEE)) kcal. Generado sin motor de optimización.",
                meals: buildOptimizedMeals(for: patients[0]),
                createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: .now)!,
                engineSource: .demo
            ),
            PlanOptimizationDraft(
                id: UUID(),
                patientId: patients[1].id,
                status: .pendingReview,
                calculatedRationale: "[Demostración] Distribución de carbohidratos de ejemplo para manejo glucémico. Generado sin motor de optimización.",
                meals: buildOptimizedMeals(for: patients[1]),
                createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: .now)!,
                engineSource: .demo
            )
        ]
    }

    func approveDraft(_ draft: PlanOptimizationDraft) async throws -> PlanOptimizationDraft {
        try await Task.sleep(for: .milliseconds(500))
        var approved = draft
        approved.status = .approved
        return approved
    }

    func discardDraft(_ draft: PlanOptimizationDraft) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }

    // MARK: - Demonstration Plan Logic

    /// Produces a rationale for the demonstration draft. It is explicit that no
    /// optimization engine ran, and never claims allergy exclusions it cannot
    /// verify (the previous false "Exclusiones por alergias" line is removed).
    private func buildRationale(for patient: Patient, filteredMealCount: Int) -> String {
        var parts: [String] = []

        parts.append("[Demostración] Generado sin motor de optimización.")
        parts.append("TDEE estimado (Mifflin-St Jeor + PAL \(patient.activityLevel.rawValue)): \(Int(patient.estimatedTDEE)) kcal/día.")

        if !patient.allergies.isEmpty {
            parts.append("Comidas de muestra que coincidían con las alergias registradas (\(patient.allergies.joined(separator: ", "))) fueron omitidas. Revisa manualmente cada ingrediente antes de prescribir.")
        }

        if !patient.medicalConditions.isEmpty {
            parts.append("Condiciones registradas: \(patient.medicalConditions.joined(separator: ", ")). El plan de muestra no las ajusta automáticamente.")
        }

        parts.append("Objetivo clínico: \(patient.clinicalGoals).")
        parts.append("IMC actual: \(String(format: "%.1f", patient.bmi)) (\(patient.bmiClassification)).")

        if filteredMealCount == 0 {
            parts.append("No hay comidas de muestra compatibles con las restricciones registradas; configura el motor de optimización para generar un plan adecuado.")
        }

        return parts.joined(separator: " ")
    }

    /// Maps a recorded allergy/restriction term to the ingredient keywords it
    /// implies, so a textual allergy like "Lactosa" can match foods like
    /// "Yogur natural" that don't contain the word "Lactosa".
    private static let allergenIngredientKeywords: [String: [String]] = [
        "lactosa": ["yogur", "leche", "queso", "crema", "mantequilla"],
        "lácteos": ["yogur", "leche", "queso", "crema", "mantequilla"],
        "lacteos": ["yogur", "leche", "queso", "crema", "mantequilla"],
        "nueces": ["almendra", "nuez", "nueces", "avellana", "pistache", "cacahuate"],
        "frutos secos": ["almendra", "nuez", "nueces", "avellana", "pistache"],
        "almendra": ["almendra"],
        "soya": ["soya", "soja", "tofu", "edamame"],
        "gluten": ["avena", "trigo", "pan", "pasta", "cebada", "centeno", "harina"],
        "trigo": ["trigo", "pan", "pasta", "harina"],
        "mariscos": ["camarón", "camaron", "marisco", "langosta", "cangrejo", "almeja"],
        "pescado": ["salmón", "salmon", "atún", "atun", "pescado", "filete de salmón"],
        "huevo": ["huevo"],
        "miel": ["miel"]
    ]

    /// Returns true if any ingredient of `meal` matches any restriction in
    /// `restrictions` (directly or via the allergen→ingredient keyword map).
    private func meal(_ meal: Meal, conflictsWith restrictions: [String]) -> Bool {
        let ingredients = meal.ingredients.map { $0.folded() }
        for restriction in restrictions {
            let term = restriction.folded()
            guard !term.isEmpty else { continue }
            // Direct substring match in either direction.
            if ingredients.contains(where: { $0.contains(term) || term.contains($0) }) {
                return true
            }
            // Keyword-expanded match (e.g. "lactosa" -> "yogur").
            if let keywords = Self.allergenIngredientKeywords[term] {
                if ingredients.contains(where: { ingredient in
                    keywords.contains { ingredient.contains($0.folded()) }
                }) {
                    return true
                }
            }
        }
        return false
    }

    /// Generates a balanced sample meal set adjusted for the patient's goals,
    /// then removes any meal that conflicts with the patient's allergies so the
    /// demonstration never proposes a recorded allergen.
    private func buildOptimizedMeals(for patient: Patient) -> [Meal] {
        let isWeightLoss = patient.clinicalGoals.localizedCaseInsensitiveContains("pérdida")
            || patient.clinicalGoals.localizedCaseInsensitiveContains("reducción")
        let isMuscleGain = patient.clinicalGoals.localizedCaseInsensitiveContains("muscular")
            || patient.clinicalGoals.localizedCaseInsensitiveContains("ganancia")

        let protMult: Double = isMuscleGain ? 1.4 : (isWeightLoss ? 1.1 : 1.0)
        let carbMult: Double = isWeightLoss ? 0.7 : (isMuscleGain ? 1.3 : 1.0)

        let candidates = [
            Meal(
                type: .breakfast,
                name: "Bowl de avena con frutos rojos",
                ingredients: ["Avena", "Fresas", "Arándanos", "Miel", "Semillas de chía"],
                macros: Macros(protein: 12 * protMult, carbohydrates: 45 * carbMult, fat: 8),
                portionDescription: "1 bowl mediano (350 ml)"
            ),
            Meal(
                type: .breakfast,
                name: "Huevos revueltos con espinaca y aguacate",
                ingredients: ["Huevo", "Espinacas", "Aguacate", "Tomate"],
                macros: Macros(protein: 16 * protMult, carbohydrates: 10 * carbMult, fat: 14),
                portionDescription: "2 huevos, 1/2 aguacate"
            ),
            Meal(
                type: .lunch,
                name: "Pechuga de pollo con quinoa y verduras",
                ingredients: ["Pechuga de pollo", "Quinoa", "Brócoli", "Zanahoria", "Aceite de oliva"],
                macros: Macros(protein: 38 * protMult, carbohydrates: 42 * carbMult, fat: 14),
                portionDescription: "150g pollo, 1 taza quinoa, 1 taza verduras"
            ),
            Meal(
                type: .snack,
                name: "Yogur natural con almendras",
                ingredients: ["Yogur natural", "Almendras", "Canela"],
                macros: Macros(protein: 10 * protMult, carbohydrates: 15 * carbMult, fat: 12),
                portionDescription: "200g yogur, 15g almendras"
            ),
            Meal(
                type: .snack,
                name: "Manzana con crema de cacahuate",
                ingredients: ["Manzana", "Crema de cacahuate", "Canela"],
                macros: Macros(protein: 6 * protMult, carbohydrates: 22 * carbMult, fat: 9),
                portionDescription: "1 manzana, 1 cda crema"
            ),
            Meal(
                type: .snack,
                name: "Bastones de zanahoria con hummus",
                ingredients: ["Zanahoria", "Hummus", "Pepino"],
                macros: Macros(protein: 6 * protMult, carbohydrates: 18 * carbMult, fat: 8),
                portionDescription: "1 taza verduras, 3 cdas hummus"
            ),
            Meal(
                type: .dinner,
                name: "Salmón al horno con ensalada verde",
                ingredients: ["Filete de salmón", "Espinacas", "Aguacate", "Tomate cherry", "Limón"],
                macros: Macros(protein: 34 * protMult, carbohydrates: 12 * carbMult, fat: 22),
                portionDescription: "180g salmón, ensalada abundante"
            ),
            Meal(
                type: .dinner,
                name: "Pavo a la plancha con verduras asadas",
                ingredients: ["Pechuga de pavo", "Calabacita", "Pimiento", "Aceite de oliva"],
                macros: Macros(protein: 32 * protMult, carbohydrates: 14 * carbMult, fat: 12),
                portionDescription: "160g pavo, verduras asadas"
            )
        ]

        let restrictions = patient.allergies
        let safe = candidates.filter { !meal($0, conflictsWith: restrictions) }

        // Keep one meal per type, preferring the first safe candidate so the
        // demo stays a single-day plan rather than listing every alternative.
        var seenTypes: Set<MealType> = []
        var result: [Meal] = []
        for meal in safe where !seenTypes.contains(meal.type) {
            seenTypes.insert(meal.type)
            result.append(meal)
        }
        return result
    }
}

private extension String {
    /// Lowercased, diacritic-insensitive form for robust ingredient matching.
    func folded() -> String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_MX"))
            .trimmingCharacters(in: .whitespaces)
    }
}
