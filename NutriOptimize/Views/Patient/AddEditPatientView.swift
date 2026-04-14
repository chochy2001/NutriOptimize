import SwiftUI

/// Form view for creating or editing a patient's clinical profile.
/// Validates required fields and enforces positive ranges for anthropometric values.
struct AddEditPatientView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Patient Fields

    @State private var fullName: String
    @State private var age: String
    @State private var sex: Patient.BiologicalSex
    @State private var weight: String
    @State private var height: String
    @State private var bodyFatPercentage: String
    @State private var allergiesText: String
    @State private var medicalConditionsText: String
    @State private var dietaryPreferencesText: String
    @State private var clinicalGoals: String
    @State private var availableCookingTime: String
    @State private var activityLevel: Patient.ActivityLevel
    @State private var monthlyFoodBudget: String

    @State private var showValidationErrors = false

    private let existingPatient: Patient?
    private let onSave: (Patient) -> Void

    // MARK: - Initialization

    init(patient: Patient? = nil, onSave: @escaping (Patient) -> Void) {
        self.existingPatient = patient
        self.onSave = onSave

        _fullName = State(initialValue: patient?.fullName ?? "")
        _age = State(initialValue: patient.map { String($0.age) } ?? "")
        _sex = State(initialValue: patient?.sex ?? .female)
        _weight = State(initialValue: patient.map { String(format: "%.1f", $0.weight) } ?? "")
        _height = State(initialValue: patient.map { String(format: "%.0f", $0.height) } ?? "")
        _bodyFatPercentage = State(initialValue: patient?.bodyFatPercentage.map { String(format: "%.0f", $0) } ?? "")
        _allergiesText = State(initialValue: patient?.allergies.joined(separator: ", ") ?? "")
        _medicalConditionsText = State(initialValue: patient?.medicalConditions.joined(separator: ", ") ?? "")
        _dietaryPreferencesText = State(initialValue: patient?.dietaryPreferences.joined(separator: ", ") ?? "")
        _clinicalGoals = State(initialValue: patient?.clinicalGoals ?? "")
        _availableCookingTime = State(initialValue: patient.map { String($0.availableCookingTime) } ?? "30")
        _activityLevel = State(initialValue: patient?.activityLevel ?? .sedentary)
        _monthlyFoodBudget = State(initialValue: patient?.monthlyFoodBudget.map { String(format: "%.0f", $0) } ?? "")
    }

    // MARK: - Validation

    private var validationErrors: [String] {
        var errors: [String] = []
        if fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("El nombre es obligatorio.")
        }
        if let ageVal = Int(age), ageVal <= 0 || ageVal > 150 {
            errors.append("La edad debe estar entre 1 y 150 años.")
        } else if Int(age) == nil {
            errors.append("La edad debe ser un número válido.")
        }
        if let w = Double(weight), w <= 0 {
            errors.append("El peso debe ser positivo.")
        } else if Double(weight) == nil {
            errors.append("El peso debe ser un número válido.")
        }
        if let h = Double(height), h <= 0 {
            errors.append("La altura debe ser positiva.")
        } else if Double(height) == nil {
            errors.append("La altura debe ser un número válido.")
        }
        if clinicalGoals.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("El objetivo clínico es obligatorio.")
        }
        if !monthlyFoodBudget.isEmpty, let budget = Double(monthlyFoodBudget), budget < 0 {
            errors.append("El presupuesto mensual no puede ser negativo.")
        }
        return errors
    }

    private var isValid: Bool { validationErrors.isEmpty }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                personalInfoSection
                anthropometricSection
                clinicalGoalsSection
                allergiesSection
                conditionsSection
                preferencesSection
                lifestyleSection
                budgetSection

                if showValidationErrors && !isValid {
                    validationSection
                }
            }
            .navigationTitle(existingPatient == nil ? "Nuevo Paciente" : "Editar Paciente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { savePatient() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Personal Info

    private var personalInfoSection: some View {
        Section {
            TextField("Nombre completo", text: $fullName)
                .textContentType(.name)
                .autocorrectionDisabled()

            TextField("Edad", text: $age)
                .keyboardType(.numberPad)

            Picker("Sexo biológico", selection: $sex) {
                ForEach(Patient.BiologicalSex.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        } header: {
            Label("Información Personal", systemImage: "person.fill")
        }
    }

    // MARK: - Anthropometric

    private var anthropometricSection: some View {
        Section {
            labeledNumberField(label: "Peso", unit: "kg", text: $weight)
            labeledNumberField(label: "Altura", unit: "cm", text: $height)
            labeledNumberField(label: "Grasa corporal", unit: "%", text: $bodyFatPercentage, placeholder: "Opcional")
        } header: {
            Label("Datos Antropométricos", systemImage: "figure.stand")
        }
    }

    // MARK: - Clinical Goals

    private var clinicalGoalsSection: some View {
        Section {
            TextField("Ej: Pérdida de peso, control de glucosa...", text: $clinicalGoals, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Label("Objetivo Clínico", systemImage: "target")
        } footer: {
            Text("Describe el objetivo principal del tratamiento nutricional.")
        }
    }

    // MARK: - Allergies

    private var allergiesSection: some View {
        Section {
            TextField("Ej: Gluten, Mariscos, Huevo, Lácteos...", text: $allergiesText, axis: .vertical)
                .lineLimit(1...3)
        } header: {
            Label("Alergias Alimentarias", systemImage: "exclamationmark.triangle.fill")
        } footer: {
            Text("Separa cada alergia con coma. El motor excluirá estos alimentos automáticamente.")
        }
    }

    // MARK: - Medical Conditions

    private var conditionsSection: some View {
        Section {
            TextField("Ej: Diabetes tipo 2, Hipotiroidismo...", text: $medicalConditionsText, axis: .vertical)
                .lineLimit(1...3)
        } header: {
            Label("Condiciones Médicas", systemImage: "cross.case.fill")
        } footer: {
            Text("El motor ajusta la distribución de macronutrientes según las condiciones del paciente.")
        }
    }

    // MARK: - Dietary Preferences

    private var preferencesSection: some View {
        Section {
            TextField("Ej: Comida mexicana, Ensaladas, Pescado...", text: $dietaryPreferencesText, axis: .vertical)
                .lineLimit(1...3)
        } header: {
            Label("Preferencias Alimenticias", systemImage: "fork.knife")
        } footer: {
            Text("Alimentos y estilos de cocina que el paciente disfruta.")
        }
    }

    // MARK: - Lifestyle

    private var lifestyleSection: some View {
        Section {
            Picker("Nivel de actividad", selection: $activityLevel) {
                ForEach(Patient.ActivityLevel.allCases, id: \.self) { level in
                    Text(level.rawValue).tag(level)
                }
            }

            labeledNumberField(label: "Tiempo para cocinar", unit: "min", text: $availableCookingTime)
        } header: {
            Label("Estilo de Vida", systemImage: "figure.walk")
        }
    }

    // MARK: - Budget

    private var budgetSection: some View {
        Section {
            labeledNumberField(label: "Presupuesto mensual", unit: "MXN", text: $monthlyFoodBudget, placeholder: "Opcional")
        } header: {
            Label("Presupuesto Alimenticio", systemImage: "dollarsign.circle")
        } footer: {
            Text("El motor priorizará ingredientes costo-efectivos cuando se especifique un presupuesto.")
        }
    }

    // MARK: - Validation

    private var validationSection: some View {
        Section {
            ForEach(validationErrors, id: \.self) { error in
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.danger)
            }
        }
    }

    // MARK: - Reusable Components

    private func labeledNumberField(label: String, unit: String, text: Binding<String>, placeholder: String = "0") -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
        }
    }

    // MARK: - Save

    private func savePatient() {
        showValidationErrors = true
        guard isValid else { return }

        let patient = Patient(
            id: existingPatient?.id ?? UUID(),
            fullName: fullName.trimmingCharacters(in: .whitespaces),
            age: Int(age) ?? 0,
            sex: sex,
            weight: Double(weight) ?? 0,
            height: Double(height) ?? 0,
            bodyFatPercentage: Double(bodyFatPercentage),
            allergies: parseCommaSeparated(allergiesText),
            medicalConditions: parseCommaSeparated(medicalConditionsText),
            dietaryPreferences: parseCommaSeparated(dietaryPreferencesText),
            clinicalGoals: clinicalGoals.trimmingCharacters(in: .whitespaces),
            availableCookingTime: Int(availableCookingTime) ?? 30,
            activityLevel: activityLevel,
            monthlyFoodBudget: Double(monthlyFoodBudget)
        )

        HapticManager.notification(.success)
        onSave(patient)
        dismiss()
    }

    private func parseCommaSeparated(_ text: String) -> [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

#Preview {
    AddEditPatientView { _ in }
}
