import SwiftUI

struct MacrosBadgeView: View {
    let macros: Macros
    let showCalories: Bool

    init(macros: Macros, showCalories: Bool = true) {
        self.macros = macros
        self.showCalories = showCalories
    }

    var body: some View {
        HStack(spacing: 14) {
            if showCalories {
                macroItem(label: "kcal", value: macros.totalCalories, color: AppTheme.calorieColor, icon: "flame.fill")
                    .accessibilityLabel("\(Int(macros.totalCalories)) kilocalorías")
            }
            macroItem(label: "Prot", value: macros.protein, color: AppTheme.proteinColor, icon: "bolt.fill", unit: "g")
                .accessibilityLabel("\(Int(macros.protein)) gramos de proteína")
            macroItem(label: "Carbs", value: macros.carbohydrates, color: AppTheme.carbColor, icon: "leaf.fill", unit: "g")
                .accessibilityLabel("\(Int(macros.carbohydrates)) gramos de carbohidratos")
            macroItem(label: "Grasa", value: macros.fat, color: AppTheme.fatColor, icon: "drop.fill", unit: "g")
                .accessibilityLabel("\(Int(macros.fat)) gramos de grasa")
        }
    }

    private func macroItem(label: String, value: Double, color: Color, icon: String, unit: String = "") -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text("\(Int(value))\(unit)")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MacrosBadgeView(macros: Macros(protein: 38, carbohydrates: 42, fat: 14))
        .padding()
}
