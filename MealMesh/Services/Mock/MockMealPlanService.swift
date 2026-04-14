import Foundation

final class MockMealPlanService: MealPlanServiceProtocol {

    /// Generates a draft tailored to the patient's profile.
    /// The rationale reflects clinical considerations based on the patient's conditions,
    /// allergies, and stated goals to simulate a real recommendation engine output.
    func generateDraft(for patient: Patient) async throws -> MealPlanDraft {
        // Simulates engine processing time — the real service will call the backend API
        try await Task.sleep(for: .seconds(3))

        let rationale = buildRationale(for: patient)
        let meals = buildMeals(for: patient)

        return MealPlanDraft(
            id: UUID(),
            patientId: patient.id,
            status: .pendingReview,
            engineRationale: rationale,
            meals: meals,
            createdAt: .now
        )
    }

    func fetchPendingDrafts() async throws -> [MealPlanDraft] {
        try await Task.sleep(for: .milliseconds(400))

        let samplePatients = MockPatientService.samplePatients
        guard samplePatients.count >= 2 else { return [] }

        return [
            MealPlanDraft(
                id: UUID(),
                patientId: samplePatients[0].id,
                status: .pendingReview,
                engineRationale: "Plan enfocado en alimentos sin gluten con énfasis en regulación tiroidea.",
                meals: buildMeals(for: samplePatients[0]),
                createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: .now)!
            ),
            MealPlanDraft(
                id: UUID(),
                patientId: samplePatients[1].id,
                status: .pendingReview,
                engineRationale: "Distribución de carbohidratos controlada para manejo glucémico.",
                meals: buildMeals(for: samplePatients[1]),
                createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: .now)!
            )
        ]
    }

    func approveDraft(_ draft: MealPlanDraft) async throws -> MealPlanDraft {
        try await Task.sleep(for: .milliseconds(500))
        var approved = draft
        approved.status = .approved
        return approved
    }

    func discardDraft(_ draft: MealPlanDraft) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }

    // MARK: - Draft Generation Helpers

    private func buildRationale(for patient: Patient) -> String {
        var parts: [String] = []

        if !patient.allergies.isEmpty {
            let allergyList = patient.allergies.joined(separator: ", ")
            parts.append("Se excluyeron alimentos que contienen \(allergyList) por alergias reportadas.")
        }

        if !patient.conditions.isEmpty {
            let conditionList = patient.conditions.joined(separator: ", ")
            parts.append("La distribución de macronutrientes fue ajustada considerando: \(conditionList).")
        }

        if patient.cookingTime <= 30 {
            parts.append("Se priorizaron recetas de preparación rápida (≤\(patient.cookingTime) min) según la disponibilidad del paciente.")
        }

        parts.append("Objetivo del paciente: \(patient.goals).")
        parts.append("El plan propuesto busca un balance calórico adecuado al IMC actual (\(String(format: "%.1f", patient.bmi)) - \(patient.bmiCategory)).")

        return parts.joined(separator: " ")
    }

    private func buildMeals(for patient: Patient) -> [Meal] {
        // Adjusts base portions depending on whether the goal is weight loss or muscle gain
        let isWeightLoss = patient.goals.lowercased().contains("pérdida")
            || patient.goals.lowercased().contains("reducción")
        let isMuscleBuild = patient.goals.lowercased().contains("muscular")
            || patient.goals.lowercased().contains("ganancia")

        let proteinMultiplier: Double = isMuscleBuild ? 1.4 : (isWeightLoss ? 1.1 : 1.0)
        let carbMultiplier: Double = isWeightLoss ? 0.7 : (isMuscleBuild ? 1.3 : 1.0)

        return [
            Meal(
                type: .breakfast,
                name: "Bowl de avena con frutos rojos",
                ingredients: ["Avena", "Fresas", "Arándanos", "Miel", "Semillas de chía"],
                macros: Macros(
                    protein: 12 * proteinMultiplier,
                    carbohydrates: 45 * carbMultiplier,
                    fat: 8
                ),
                portionDescription: "1 bowl mediano (350 ml)"
            ),
            Meal(
                type: .lunch,
                name: "Pechuga de pollo con quinoa y verduras",
                ingredients: ["Pechuga de pollo", "Quinoa", "Brócoli", "Zanahoria", "Aceite de oliva"],
                macros: Macros(
                    protein: 38 * proteinMultiplier,
                    carbohydrates: 42 * carbMultiplier,
                    fat: 14
                ),
                portionDescription: "150g pollo, 1 taza quinoa, 1 taza verduras"
            ),
            Meal(
                type: .snack,
                name: "Yogur natural con almendras",
                ingredients: ["Yogur natural", "Almendras", "Canela"],
                macros: Macros(
                    protein: 10 * proteinMultiplier,
                    carbohydrates: 15 * carbMultiplier,
                    fat: 12
                ),
                portionDescription: "200g yogur, 15g almendras"
            ),
            Meal(
                type: .dinner,
                name: "Salmón al horno con ensalada verde",
                ingredients: ["Filete de salmón", "Espinacas", "Aguacate", "Tomate cherry", "Limón"],
                macros: Macros(
                    protein: 34 * proteinMultiplier,
                    carbohydrates: 12 * carbMultiplier,
                    fat: 22
                ),
                portionDescription: "180g salmón, ensalada abundante"
            )
        ]
    }
}
