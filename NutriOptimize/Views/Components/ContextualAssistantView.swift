import SwiftUI

/// Contextual assistant card that appears in clinical sections.
/// Analyzes patient data within its section and provides insights,
/// questions, and recommendations to the nutritionist.
///
/// The assistant operates as a "thinking out loud" companion:
/// it surfaces observations the nutritionist might miss and asks
/// targeted questions to support clinical decision-making.
struct ContextualAssistantView: View {
    let insights: [AssistantInsight]
    let isLoading: Bool

    @State private var isExpanded = true
    @State private var selectedInsight: AssistantInsight?

    init(insights: [AssistantInsight], isLoading: Bool = false) {
        self.insights = insights
        self.isLoading = isLoading
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerButton

            if isExpanded {
                Divider().padding(.horizontal)

                if isLoading {
                    loadingState
                } else if insights.isEmpty {
                    noInsightsState
                } else {
                    insightsList
                }
            }
        }
        .background(.white, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.deepOrange.opacity(0.08), radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.deepOrange.opacity(0.15), lineWidth: 1)
        )
    }

    private var headerButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                HapticManager.selection()
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(AppTheme.deepOrange)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Asistente clínico")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(isExpanded ? "Observaciones sobre esta sección" : "Toca para ver observaciones")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !insights.isEmpty {
                    Text("\(insights.count)")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.deepOrange, in: Capsule())
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }

    private var loadingState: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(AppTheme.deepOrange)
            Text("Analizando datos del paciente...")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var noInsightsState: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.success)
            Text("Sin observaciones adicionales en este momento.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var insightsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(insights) { insight in
                insightRow(insight)
            }
        }
        .padding()
    }

    private func insightRow(_ insight: AssistantInsight) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: insight.type.icon)
                .font(.caption)
                .foregroundStyle(insight.type.color)
                .frame(width: 20, height: 20)
                .background(insight.type.color.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.message)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let action = insight.suggestedAction {
                    Text(action)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(AppTheme.deepOrange)
                }
            }
        }
    }
}

// MARK: - Data Types

struct AssistantInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let message: String
    let suggestedAction: String?

    init(_ type: InsightType, message: String, action: String? = nil) {
        self.type = type
        self.message = message
        self.suggestedAction = action
    }
}

enum InsightType {
    case question
    case observation
    case warning
    case suggestion

    var icon: String {
        switch self {
        case .question: return "questionmark"
        case .observation: return "eye"
        case .warning: return "exclamationmark.triangle.fill"
        case .suggestion: return "lightbulb.fill"
        }
    }

    var color: Color {
        switch self {
        case .question: return AppTheme.info
        case .observation: return AppTheme.deepOrange
        case .warning: return AppTheme.danger
        case .suggestion: return AppTheme.success
        }
    }
}

// MARK: - Insight Generators

/// Builds contextual insights from patient clinical data.
/// Each generator analyzes a specific section and returns relevant observations.
enum InsightGenerator {

    /// Generates insights for the consultation history section.
    static func forHistory(consultations: [ConsultationRecord], patientGoals: String) -> [AssistantInsight] {
        guard !consultations.isEmpty else { return [] }
        var insights: [AssistantInsight] = []

        let sorted = consultations.sorted { $0.date < $1.date }

        // Weight trend analysis
        if sorted.count >= 2, let firstRecord = sorted.first, let lastRecord = sorted.last {
            let first = firstRecord.weight
            let last = lastRecord.weight
            let diff = last - first
            let isLoss = patientGoals.localizedCaseInsensitiveContains("pérdida")
                || patientGoals.localizedCaseInsensitiveContains("reducción")

            if isLoss && diff > 0 {
                insights.append(AssistantInsight(.warning,
                    message: "El paciente ha subido \(String(format: "%.1f", diff)) kg, pero su objetivo es pérdida de peso. ¿Ha habido cambios en su adherencia al plan?",
                    action: "Considerar ajustar el déficit calórico o revisar adherencia"))
            } else if isLoss && diff < -1 {
                let weeklyRate = abs(diff) / Double(sorted.count)
                if weeklyRate > 1.0 {
                    insights.append(AssistantInsight(.warning,
                        message: "La pérdida es de \(String(format: "%.1f", abs(diff))) kg en \(sorted.count) consultas. Un ritmo mayor a 1 kg/semana puede comprometer masa muscular.",
                        action: "Verificar que la pérdida no sea de masa magra"))
                } else {
                    insights.append(AssistantInsight(.observation,
                        message: "Buena tendencia: pérdida de \(String(format: "%.1f", abs(diff))) kg de forma gradual y sostenida. El ritmo es saludable."))
                }
            }
        }

        // Calorie consistency
        if sorted.count >= 3 {
            let calories = sorted.map { $0.totalCaloriesPrescribed }
            let avg = calories.reduce(0, +) / Double(calories.count)
            guard let lastConsult = sorted.last else { return insights }
            let lastCal = lastConsult.totalCaloriesPrescribed
            if abs(lastCal - avg) > 200 {
                insights.append(AssistantInsight(.question,
                    message: "La última prescripción calórica (\(Int(lastCal)) kcal) difiere significativamente del promedio (\(Int(avg)) kcal). ¿Fue un ajuste intencional?"))
            }
        }

        // Body composition check
        if let lastWaist = sorted.last?.waistCircumference,
           let firstWaist = sorted.first?.waistCircumference,
           lastWaist > firstWaist {
            insights.append(AssistantInsight(.warning,
                message: "La circunferencia de cintura aumentó de \(String(format: "%.0f", firstWaist)) a \(String(format: "%.0f", lastWaist)) cm. Esto puede indicar acumulación de grasa visceral.",
                action: "Considerar incluir más actividad cardiovascular"))
        }

        // Adherence question
        if sorted.count >= 2 {
            insights.append(AssistantInsight(.question,
                message: "¿El paciente ha seguido el plan tal como se prescribió? ¿Ha reportado dificultades con algún alimento o porción?",
                action: "Revisar adherencia en la próxima consulta"))
        }

        return insights
    }

    /// Generates insights for the lab results section.
    static func forLabResults(results: [LabResultRecord]) -> [AssistantInsight] {
        guard !results.isEmpty else { return [] }
        var insights: [AssistantInsight] = []

        let outOfRange = results.filter { $0.isOutOfRange }
        if !outOfRange.isEmpty {
            let names = Array(Set(outOfRange.map { $0.testName })).prefix(3)
            insights.append(AssistantInsight(.warning,
                message: "Hay \(outOfRange.count) valores fuera de rango, incluyendo: \(names.joined(separator: ", ")). ¿El plan actual considera estos resultados?",
                action: "Ajustar macronutrientes según valores alterados"))
        }

        // Check for glucose trends
        let glucoseResults = results.filter { $0.testName.contains("Glucosa") }
            .sorted { $0.testDate < $1.testDate }
        if glucoseResults.count >= 2 {
            guard let lastGlucose = glucoseResults.last, let firstGlucose = glucoseResults.first else { return insights }
            let trend = lastGlucose.value - firstGlucose.value
            if trend > 10 {
                insights.append(AssistantInsight(.warning,
                    message: "La glucosa en ayunas ha aumentado \(Int(trend)) mg/dL entre mediciones. ¿El paciente está controlando sus carbohidratos?"))
            } else if trend < -10 {
                insights.append(AssistantInsight(.observation,
                    message: "La glucosa en ayunas mejoró \(Int(abs(trend))) mg/dL. El control glucémico va en la dirección correcta."))
            }
        }

        // Lipid panel check
        let cholesterol = results.filter { $0.testName.contains("Colesterol total") }
            .sorted { $0.testDate < $1.testDate }
        if let last = cholesterol.last, last.isOutOfRange {
            insights.append(AssistantInsight(.suggestion,
                message: "Colesterol total elevado (\(Int(last.value)) mg/dL). ¿Se están priorizando grasas monoinsaturadas y omega-3 en el plan?",
                action: "Incluir más pescado graso, aguacate y aceite de oliva"))
        }

        // Missing common tests
        let testNames = Set(results.map { $0.testName })
        if !testNames.contains("HbA1c") && testNames.contains("Glucosa en ayunas") {
            if let glucose = results.first(where: { $0.testName.contains("Glucosa") && $0.isOutOfRange }) {
                insights.append(AssistantInsight(.suggestion,
                    message: "La glucosa está alterada (\(Int(glucose.value)) mg/dL) pero no hay registro de HbA1c. ¿Sería útil solicitarla para evaluar control a 3 meses?"))
            }
        }

        return insights
    }

    /// Generates insights for the patient feedback section.
    static func forFeedback(feedback: PatientFeedbackRecord?, patientName: String) -> [AssistantInsight] {
        guard let feedback else {
            return [AssistantInsight(.suggestion,
                message: "No hay preferencias registradas para \(patientName). Registrar gustos y exclusiones mejora la precisión de las propuestas.",
                action: "Agregar alimentos preferidos y a evitar")]
        }

        var insights: [AssistantInsight] = []

        if feedback.likedFoods.isEmpty && feedback.dislikedFoods.isEmpty {
            insights.append(AssistantInsight(.question,
                message: "¿Qué alimentos disfruta más el paciente? Conocer sus preferencias permite generar planes más adherentes.",
                action: "Preguntar por sus 3-5 comidas favoritas"))
        }

        if !feedback.bannedFoods.isEmpty {
            insights.append(AssistantInsight(.observation,
                message: "Hay \(feedback.bannedFoods.count) alimentos en exclusión permanente: \(feedback.bannedFoods.joined(separator: ", ")). El motor los excluye automáticamente."))
        }

        if feedback.dislikedFoods.count > 5 {
            insights.append(AssistantInsight(.question,
                message: "El paciente tiene \(feedback.dislikedFoods.count) alimentos marcados como no preferidos. ¿Alguno podría reintroducirse con diferente preparación?",
                action: "Revisar si alguna aversión es por preparación y no por el alimento"))
        }

        if feedback.generalNotes.isEmpty {
            insights.append(AssistantInsight(.suggestion,
                message: "Las notas clínicas están vacías. Agregar observaciones sobre patrones de prescripción ayuda al motor a personalizar mejor.",
                action: "Describir el estilo de prescripción para este paciente"))
        }

        return insights
    }

    /// Generates insights for the patient detail/profile section.
    static func forPatientProfile(patient: Patient) -> [AssistantInsight] {
        var insights: [AssistantInsight] = []

        if patient.bmi >= 30 {
            insights.append(AssistantInsight(.observation,
                message: "IMC de \(String(format: "%.1f", patient.bmi)) indica obesidad. ¿Se ha considerado un enfoque multidisciplinario (psicología, actividad física)?",
                action: "Evaluar derivación a equipo multidisciplinario"))
        } else if patient.bmi < 18.5 {
            insights.append(AssistantInsight(.warning,
                message: "IMC de \(String(format: "%.1f", patient.bmi)) indica bajo peso. ¿Hay riesgo de desnutrición o trastorno alimentario?"))
        }

        if patient.allergies.count >= 3 {
            insights.append(AssistantInsight(.question,
                message: "El paciente tiene \(patient.allergies.count) alergias. ¿Se han confirmado con estudios de alergia o son intolerancias reportadas?",
                action: "Verificar diagnóstico de alergias con alergólogo"))
        }

        if patient.availableCookingTime <= 15 {
            insights.append(AssistantInsight(.suggestion,
                message: "Solo \(patient.availableCookingTime) minutos para cocinar. ¿Se han considerado opciones de meal prep semanal para mejorar adherencia?",
                action: "Sugerir preparación de comidas los domingos"))
        }

        if let budget = patient.monthlyFoodBudget, budget < 3000 {
            insights.append(AssistantInsight(.observation,
                message: "Presupuesto mensual de $\(Int(budget)) MXN. El motor priorizará ingredientes económicos. ¿El paciente tiene acceso a mercados locales?"))
        }

        return insights
    }
}

#Preview {
    VStack {
        ContextualAssistantView(insights: [
            AssistantInsight(.question, message: "¿El paciente ha seguido el plan como se prescribió?", action: "Revisar adherencia"),
            AssistantInsight(.warning, message: "La glucosa subió 15 mg/dL entre mediciones."),
            AssistantInsight(.suggestion, message: "Considerar agregar omega-3 al plan.", action: "Incluir salmón o sardinas"),
        ])
        .padding()
    }
}
