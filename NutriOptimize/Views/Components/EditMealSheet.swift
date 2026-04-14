import SwiftUI

struct EditMealSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var type: MealType
    @State private var ingredientsText: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var portionDescription: String

    private let mealId: UUID
    private let onSave: (Meal) -> Void

    init(existingMeal: Meal? = nil, onSave: @escaping (Meal) -> Void) {
        self.mealId = existingMeal?.id ?? UUID()
        self.onSave = onSave
        _name = State(initialValue: existingMeal?.name ?? "")
        _type = State(initialValue: existingMeal?.type ?? .lunch)
        _ingredientsText = State(initialValue: existingMeal?.ingredients.joined(separator: ", ") ?? "")
        _protein = State(initialValue: existingMeal.map { String(format: "%.0f", $0.macros.protein) } ?? "")
        _carbs = State(initialValue: existingMeal.map { String(format: "%.0f", $0.macros.carbohydrates) } ?? "")
        _fat = State(initialValue: existingMeal.map { String(format: "%.0f", $0.macros.fat) } ?? "")
        _portionDescription = State(initialValue: existingMeal?.portionDescription ?? "")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && !ingredientsText.trimmingCharacters(in: .whitespaces).isEmpty
        && Double(protein) != nil
        && Double(carbs) != nil
        && Double(fat) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Información general") {
                    TextField("Nombre del platillo", text: $name)
                    Picker("Tipo de comida", selection: $type) {
                        ForEach(MealType.allCases) { mealType in
                            Label(mealType.rawValue, systemImage: mealType.icon)
                                .tag(mealType)
                        }
                    }
                }

                Section("Ingredientes") {
                    TextField("Separados por coma", text: $ingredientsText, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Macronutrientes (g)") {
                    HStack {
                        macroField("Proteína", text: $protein)
                        macroField("Carbohidratos", text: $carbs)
                        macroField("Grasa", text: $fat)
                    }
                }

                Section("Porción") {
                    TextField("Ej: 150g pollo, 1 taza quinoa", text: $portionDescription)
                }
            }
            .navigationTitle(name.isEmpty ? "Nueva comida" : "Editar comida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
        }
    }

    private func macroField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(AppTheme.captionFont)
                .foregroundStyle(.secondary)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func save() {
        let ingredients = ingredientsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let meal = Meal(
            id: mealId,
            type: type,
            name: name.trimmingCharacters(in: .whitespaces),
            ingredients: ingredients,
            macros: Macros(
                protein: Double(protein) ?? 0,
                carbohydrates: Double(carbs) ?? 0,
                fat: Double(fat) ?? 0
            ),
            portionDescription: portionDescription.trimmingCharacters(in: .whitespaces)
        )

        onSave(meal)
        dismiss()
    }
}

#Preview {
    EditMealSheet { meal in
        print("Saved: \(meal.name)")
    }
}
