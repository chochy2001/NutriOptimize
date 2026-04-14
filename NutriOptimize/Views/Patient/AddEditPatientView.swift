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
            errors.append("La edad debe estar entre 1 y 150 a\u{00F1}os.")
        } else if Int(age) == nil {
            errors.append("La edad debe ser un n\u{00FA}mero v\u{00E1}lido.")
        }
        if let w = Double(weight), w <= 0 {
            errors.append("El peso debe ser positivo.")
        } else if Double(weight) == nil {
            errors.append("El peso debe ser un n\u{00FA}mero v\u{00E1}lido.")
        }
        if let h = Double(height), h <= 0 {
            errors.append("La altura debe ser positiva.")
        } else if Double(height) == nil {
            errors.append("La altura debe ser un n\u{00FA}mero v\u{00E1}lido.")
        }
        if clinicalGoals.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("El objetivo cl\u{00ED}nico es obligatorio.")
        }
        if !monthlyFoodBudget.isEmpty, let budget = Double(monthlyFoodBudget), budget < 0 {
            errors.append("El presupuesto mensual no puede ser negativo.")
        }
        return errors
    }

    private var isValid: Bool {
        validationErrors.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                personalInfoSection
                anthropometricSection
                clinicalSection
                dietarySection
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

    // MARK: - Sections

    private var personalInfoSection: some View {
        Section("Informaci\u{00F3}n Personal") {
            TextField("Nombre completo", text: $fullName)
                .textContentType(.name)
                .autocorrectionDisabled()

            TextField("Edad", text: $age)
                .keyboardType(.numberPad)

            Picker("Sexo biol\u{00F3}gico", selection: $sex) {
                ForEach(Patient.BiologicalSex.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        }
    }

    private var anthropometricSection: some View {
        Section("Datos Antropom\u{00E9}tricos") {
            HStack {
                Text("Peso (kg)")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("0.0", text: $weight)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }

            HStack {
                Text("Altura (cm)")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("0", text: $height)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }

            HStack {
                Text("% Grasa corporal")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("Opcional", text: $bodyFatPercentage)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
        }
    }

    private var clinicalSection: some View {
        Section("Informaci\u{00F3}n Cl\u{00ED}nica") {
            TextField("Objetivo cl\u{00ED}nico", text: $clinicalGoals, axis: .vertical)
                .lineLimit(2...4)

            TextField("Condiciones m\u{00E9}dicas (separadas por coma)", text: $medicalConditionsText, axis: .vertical)
                .lineLimit(1...3)

            TextField("Alergias (separadas por coma)", text: $allergiesText, axis: .vertical)
                .lineLimit(1...3)
        }
    }

    private var dietarySection: some View {
        Section("Preferencias Alimenticias") {
            TextField("Preferencias (separadas por coma)", text: $dietaryPreferencesText, axis: .vertical)
                .lineLimit(1...3)
        }
    }

    private var lifestyleSection: some View {
        Section("Estilo de Vida") {
            Picker("Nivel de actividad", selection: $activityLevel) {
                ForEach(Patient.ActivityLevel.allCases, id: \.self) { level in
                    Text(level.rawValue).tag(level)
                }
            }

            HStack {
                Text("Tiempo disponible para cocinar (min)")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("30", text: $availableCookingTime)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }
    }

    private var budgetSection: some View {
        Section {
            HStack {
                Text("Presupuesto mensual (MXN)")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("Opcional", text: $monthlyFoodBudget)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
        } header: {
            Text("Presupuesto Alimenticio")
        } footer: {
            Text("El motor de optimizaci\u{00F3}n considerar\u{00E1} este presupuesto al seleccionar ingredientes.")
        }
    }

    private var validationSection: some View {
        Section {
            ForEach(validationErrors, id: \.self) { error in
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.danger)
            }
        }
    }

    // MARK: - Save

    private func savePatient() {
        showValidationErrors = true
        guard isValid else { return }

        let allergies = parseCommaSeparated(allergiesText)
        let conditions = parseCommaSeparated(medicalConditionsText)
        let preferences = parseCommaSeparated(dietaryPreferencesText)

        let patient = Patient(
            id: existingPatient?.id ?? UUID(),
            fullName: fullName.trimmingCharacters(in: .whitespaces),
            age: Int(age) ?? 0,
            sex: sex,
            weight: Double(weight) ?? 0,
            height: Double(height) ?? 0,
            bodyFatPercentage: Double(bodyFatPercentage),
            allergies: allergies,
            medicalConditions: conditions,
            dietaryPreferences: preferences,
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
