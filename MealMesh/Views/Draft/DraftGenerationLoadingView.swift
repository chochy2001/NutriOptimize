import SwiftUI

struct DraftGenerationLoadingView: View {
    let progress: Double

    @State private var currentPhaseIndex = 0

    private let phases = [
        ("Analizando perfil del paciente...", "person.text.rectangle"),
        ("Evaluando restricciones y alergias...", "exclamationmark.shield"),
        ("Calculando requerimientos calóricos...", "function"),
        ("Seleccionando alimentos óptimos...", "leaf.arrow.circlepath"),
        ("Generando propuesta de plan...", "doc.text")
    ]

    /// Maps linear progress (0...1) to the corresponding analysis phase.
    private var activePhase: Int {
        let step = 1.0 / Double(phases.count)
        return min(Int(progress / step), phases.count - 1)
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 6)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.tint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: progress)

                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.title.bold())
                        .contentTransition(.numericText())
                        .animation(.default, value: progress)
                }
            }

            VStack(spacing: 16) {
                Text("Generando propuesta")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(phases.enumerated()), id: \.offset) { index, phase in
                        HStack(spacing: 10) {
                            Image(systemName: phaseIcon(for: index))
                                .font(.body)
                                .foregroundStyle(phaseColor(for: index))
                                .frame(width: 24)

                            Text(phase.0)
                                .font(.subheadline)
                                .foregroundStyle(index <= activePhase ? .primary : .tertiary)
                        }
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            Text("Este proceso toma unos segundos.\nEl motor analiza las reglas clínicas y preferencias del paciente.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func phaseIcon(for index: Int) -> String {
        if index < activePhase {
            return "checkmark.circle.fill"
        } else if index == activePhase {
            return phases[index].1
        }
        return "circle"
    }

    private func phaseColor(for index: Int) -> Color {
        if index < activePhase { return .green }
        if index == activePhase { return .accentColor }
        return .gray.opacity(0.3)
    }
}

#Preview {
    DraftGenerationLoadingView(progress: 0.55)
}
