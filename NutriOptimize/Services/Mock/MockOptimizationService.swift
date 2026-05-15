import Foundation

final class MockOptimizationService: OptimizationServiceProtocol {

    /// Builds a plan optimization draft tailored to the patient's clinical profile.
    /// The rationale references clinical formulas and the patient's restrictions
    /// so the reviewing professional can verify the system's reasoning.
    func generateDraft(for patient: Patient) async throws -> PlanOptimizationDraft {
        // Simulates engine processing - the production service calls the backend
        try await Task.sleep(for: .seconds(3))

        let rationale = buildRationale(for: patient)
        let meals = buildOptimizedMeals(for: patient)

        return PlanOptimizationDraft(
            id: UUID(),
            patientId: patient.id,
            status: .pendingReview,
            calculatedRationale: rationale,
            meals: meals,
            createdAt: .now
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
                calculatedRationale: "Plan libre de gluten con énfasis en regulación tiroidea. TDEE estimado: \(Int(patients[0].estimatedTDEE)) kcal.",
                meals: buildOptimizedMeals(for: patients[0]),
                createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: .now)!
            ),
            PlanOptimizationDraft(
                id: UUID(),
                patientId: patients[1].id,
                status: .pendingReview,
                calculatedRationale: "Distribución de carbohidratos controlada para manejo glucémico. Índice glucémico bajo priorizado.",
                meals: buildOptimizedMeals(for: patients[1]),
                createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: .now)!
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

    // MARK: - Optimization Engine Logic

    /// Produces a clinical rationale based on the patient's anthropometric
    /// data, medical conditions, and dietary constraints.
    private func buildRationale(for patient: Patient) -> String {
        var parts: [String] = []

        parts.append("TDEE estimado (Mifflin-St Jeor + PAL \(patient.activityLevel.rawValue)): \(Int(patient.estimatedTDEE)) kcal/día.")

        if !patient.allergies.isEmpty {
            parts.append("Exclusiones por alergias: \(patient.allergies.joined(separator: ", ")).")
        }

        if !patient.medicalConditions.isEmpty {
            parts.append("Ajuste de macros por condiciones: \(patient.medicalConditions.joined(separator: ", ")).")
        }

        if patient.availableCookingTime <= 30 {
            parts.append("Preparaciones simplificadas (≤\(patient.availableCookingTime) min) por disponibilidad del paciente.")
        }

        parts.append("Objetivo clínico: \(patient.clinicalGoals).")
        parts.append("IMC actual: \(String(format: "%.1f", patient.bmi)) (\(patient.bmiClassification)).")

        return parts.joined(separator: " ")
    }

    /// Generates a balanced meal set adjusted for the patient's goals.
    /// Protein and carb multipliers shift based on weight-loss vs. muscle-gain targets.
    private func buildOptimizedMeals(for patient: Patient) -> [Meal] {
        let isWeightLoss = patient.clinicalGoals.localizedCaseInsensitiveContains("pérdida")
            || patient.clinicalGoals.localizedCaseInsensitiveContains("reducción")
        let isMuscleGain = patient.clinicalGoals.localizedCaseInsensitiveContains("muscular")
            || patient.clinicalGoals.localizedCaseInsensitiveContains("ganancia")

        let protMult: Double = isMuscleGain ? 1.4 : (isWeightLoss ? 1.1 : 1.0)
        let carbMult: Double = isWeightLoss ? 0.7 : (isMuscleGain ? 1.3 : 1.0)

        return [
            Meal(
                type: .breakfast,
                name: "Bowl de avena con frutos rojos",
                ingredients: ["Avena", "Fresas", "Arándanos", "Miel", "Semillas de chía"],
                macros: Macros(protein: 12 * protMult, carbohydrates: 45 * carbMult, fat: 8),
                portionDescription: "1 bowl mediano (350 ml)"
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
                type: .dinner,
                name: "Salmón al horno con ensalada verde",
                ingredients: ["Filete de salmón", "Espinacas", "Aguacate", "Tomate cherry", "Limón"],
                macros: Macros(protein: 34 * protMult, carbohydrates: 12 * carbMult, fat: 22),
                portionDescription: "180g salmón, ensalada abundante"
            )
        ]
    }
}
