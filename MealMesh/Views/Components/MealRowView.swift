import SwiftUI

struct MealRowView: View {
    let meal: Meal
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: meal.type.icon)
                    .foregroundStyle(.tint)
                Text(meal.type.rawValue)
                    .font(.caption.bold())
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)

                Spacer()

                if let onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle")
                            .font(.title3)
                    }
                }
                if let onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash.circle")
                            .font(.title3)
                    }
                }
            }

            Text(meal.name)
                .font(.headline)

            if !meal.portionDescription.isEmpty {
                Text(meal.portionDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(meal.ingredients.joined(separator: " · "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            MacrosBadgeView(macros: meal.macros, showCalories: true)
                .padding(.top, 4)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    MealRowView(
        meal: Meal(
            type: .lunch,
            name: "Pechuga de pollo con quinoa",
            ingredients: ["Pollo", "Quinoa", "Brócoli", "Aceite de oliva"],
            macros: Macros(protein: 38, carbohydrates: 42, fat: 14),
            portionDescription: "150g pollo, 1 taza quinoa"
        ),
        onEdit: {},
        onDelete: {}
    )
    .padding()
}
