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

    /// Pre-defined meal templates for quick data entry.
    private struct MealTemplate: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let type: MealType
        let ingredients: String
        let protein: Double
        let carbs: Double
        let fat: Double
        let portion: String
    }

    private let mealTemplates: [MealTemplate] = [
        MealTemplate(
            name: "Desayuno ligero",
            icon: "sunrise.fill",
            type: .breakfast,
            ingredients: "Avena, Plátano, Miel, Leche",
            protein: 10, carbs: 55, fat: 6,
            portion: "1 taza avena, 1 plátano, 1 cdta miel"
        ),
        MealTemplate(
            name: "Desayuno proteico",
            icon: "bolt.fill",
            type: .breakfast,
            ingredients: "Huevos, Pan integral, Aguacate, Tomate",
            protein: 25, carbs: 30, fat: 18,
            portion: "3 huevos, 2 rebanadas pan, 1/4 aguacate"
        ),
        MealTemplate(
            name: "Comida balanceada",
            icon: "fork.knife",
            type: .lunch,
            ingredients: "Pechuga de pollo, Arroz integral, Brócoli, Zanahoria",
            protein: 35, carbs: 45, fat: 10,
            portion: "150g pollo, 1 taza arroz, 1 taza verduras"
        ),
        MealTemplate(
            name: "Cena ligera",
            icon: "moon.fill",
            type: .dinner,
            ingredients: "Lechuga, Pollo desmenuzado, Tomate, Pepino, Aderezo ligero",
            protein: 28, carbs: 12, fat: 8,
            portion: "Ensalada grande con 120g proteína"
        ),
        MealTemplate(
            name: "Snack saludable",
            icon: "leaf.fill",
            type: .snack,
            ingredients: "Yogur griego, Frutos secos, Arándanos",
            protein: 15, carbs: 18, fat: 10,
            portion: "150g yogur, 30g frutos secos, 1/2 taza arándanos"
        ),
    ]

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
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(mealTemplates) { template in
                                Button {
                                    HapticManager.selection()
                                    applyMealTemplate(template)
                                } label: {
                                    VStack(spacing: 5) {
                                        Image(systemName: template.icon)
                                            .font(.title3)
                                            .foregroundStyle(AppTheme.deepOrange)
                                        Text(template.name)
                                            .font(.system(.caption2, design: .rounded, weight: .medium))
                                            .foregroundStyle(.primary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                    .frame(width: 90, height: 64)
                                    .background(AppTheme.deepOrange.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Plantillas rápidas")
                }

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

    private func applyMealTemplate(_ template: MealTemplate) {
        name = template.name
        type = template.type
        ingredientsText = template.ingredients
        protein = String(format: "%.0f", template.protein)
        carbs = String(format: "%.0f", template.carbs)
        fat = String(format: "%.0f", template.fat)
        portionDescription = template.portion
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
    EditMealSheet { _ in }
}
