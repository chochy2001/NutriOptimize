import SwiftUI

struct ProcessingStateView: View {
    let progress: Double
    @State private var isPulsing = false

    private let phases = [
        ("Analizando perfil clínico del paciente...", "person.text.rectangle"),
        ("Evaluando restricciones y contraindicaciones...", "exclamationmark.shield"),
        ("Calculando requerimientos energéticos (TDEE)...", "function"),
        ("Optimizando selección de alimentos...", "leaf.arrow.circlepath"),
        ("Generando propuesta del plan...", "doc.text")
    ]

    private var activePhase: Int {
        let step = 1.0 / Double(phases.count)
        return min(Int(progress / step), phases.count - 1)
    }

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            progressRing

            VStack(spacing: 20) {
                Text("Optimizando plan")
                    .font(AppTheme.headlineFont)

                phaseList
            }

            Spacer()

            footerText
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.lightOrange, lineWidth: 8)
                .frame(width: 130, height: 130)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [AppTheme.warmOrange, AppTheme.deepOrange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)

            Text("\(Int(progress * 100))%")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.deepOrange)
                .contentTransition(.numericText())
                .animation(.default, value: progress)
        }
    }

    // MARK: - Phase List

    private var phaseList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(phases.enumerated()), id: \.offset) { index, phase in
                HStack(spacing: 12) {
                    Image(systemName: phaseIcon(for: index))
                        .font(.body)
                        .foregroundStyle(phaseColor(for: index))
                        .frame(width: 26)
                        .scaleEffect(index == activePhase ? (isPulsing ? 1.2 : 1.0) : 1.0)
                        .animation(
                            index == activePhase
                                ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                                : .default,
                            value: isPulsing
                        )

                    Text(phase.0)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(index <= activePhase ? .primary : .tertiary)
                }
            }
            .onAppear { isPulsing = true }
        }
        .padding(.horizontal, 32)
    }

    private var footerText: some View {
        Text("El motor analiza las reglas clínicas,\nrestricciones y preferencias del paciente.")
            .font(AppTheme.captionFont)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .padding(.bottom, 32)
    }

    // MARK: - Helpers

    private func phaseIcon(for index: Int) -> String {
        if index < activePhase { return "checkmark.circle.fill" }
        if index == activePhase { return phases[index].1 }
        return "circle"
    }

    private func phaseColor(for index: Int) -> Color {
        if index < activePhase { return AppTheme.success }
        if index == activePhase { return AppTheme.deepOrange }
        return .gray.opacity(0.3)
    }
}

#Preview {
    ProcessingStateView(progress: 0.55)
}
