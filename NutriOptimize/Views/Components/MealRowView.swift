import SwiftUI

struct MealRowView: View {
    let meal: Meal
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var onLike: (() -> Void)?
    var onDislike: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: meal.type.icon)
                        .foregroundStyle(AppTheme.deepOrange)
                        .font(.subheadline)
                    Text(meal.type.rawValue)
                        .font(AppTheme.captionFont)
                        .textCase(.uppercase)
                        .foregroundStyle(AppTheme.deepOrange)
                }

                Spacer()

                if let onLike {
                    Button(action: onLike) {
                        Image(systemName: "hand.thumbsup.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.success)
                    }
                }
                if let onDislike {
                    Button(action: onDislike) {
                        Image(systemName: "hand.thumbsdown.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.danger)
                    }
                }
                if let onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.deepOrange)
                    }
                }
                if let onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.danger.opacity(0.7))
                    }
                }
            }

            Text(meal.name)
                .font(.system(.headline, design: .rounded))

            if !meal.portionDescription.isEmpty {
                Text(meal.portionDescription)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            Text(meal.ingredients.joined(separator: " · "))
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.tertiary)
                .lineLimit(2)

            MacrosBadgeView(macros: meal.macros, showCalories: true)
                .padding(.top, 4)
        }
        .cardStyle()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
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
