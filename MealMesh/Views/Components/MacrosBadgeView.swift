import SwiftUI

struct MacrosBadgeView: View {
    let macros: Macros
    let showCalories: Bool

    init(macros: Macros, showCalories: Bool = true) {
        self.macros = macros
        self.showCalories = showCalories
    }

    var body: some View {
        HStack(spacing: 16) {
            if showCalories {
                macroItem(
                    label: "kcal",
                    value: macros.totalCalories,
                    color: .orange,
                    icon: "flame.fill"
                )
            }
            macroItem(
                label: "Prot",
                value: macros.protein,
                color: .red,
                icon: "p.circle.fill",
                unit: "g"
            )
            macroItem(
                label: "Carbs",
                value: macros.carbohydrates,
                color: .blue,
                icon: "c.circle.fill",
                unit: "g"
            )
            macroItem(
                label: "Grasa",
                value: macros.fat,
                color: .yellow,
                icon: "f.circle.fill",
                unit: "g"
            )
        }
    }

    private func macroItem(
        label: String,
        value: Double,
        color: Color,
        icon: String,
        unit: String = ""
    ) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text("\(Int(value))\(unit)")
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MacrosBadgeView(
        macros: Macros(protein: 38, carbohydrates: 42, fat: 14)
    )
    .padding()
}
