import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showPlate = false
    @State private var showNotebook = false
    @State private var showPencil = false
    @State private var showName = false
    @State private var pencilWiggle: Double = 0
    @State private var checkProgress: CGFloat = 0

    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.primaryOrange, AppTheme.deepOrange],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                logoGroup
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("NutriOptimize")

                VStack(spacing: 6) {
                    Text("NutriOptimize")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text(L10n.splashTagline)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .opacity(showName ? 1 : 0)
                .offset(y: showName ? 0 : 20)
            }
        }
        .onAppear(perform: runIntro)
    }

    private var logoGroup: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 140, height: 140)
                .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
                .scaleEffect(showPlate ? 1 : 0)

            Image(systemName: "note.text")
                .font(.system(size: 60, weight: .regular))
                .foregroundStyle(AppTheme.primaryOrange)
                .opacity(showNotebook ? 1 : 0)
                .scaleEffect(showNotebook ? 1 : 0.4)

            CheckMarkShape()
                .trim(from: 0, to: checkProgress)
                .stroke(AppTheme.primaryOrange, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .frame(width: 28, height: 20)
                .offset(x: 0, y: 2)

            Image(systemName: "pencil")
                .font(.system(size: 38, weight: .regular))
                .foregroundStyle(AppTheme.deepOrange)
                .rotationEffect(.degrees(-35 + pencilWiggle))
                .offset(x: 24, y: -16)
                .opacity(showPencil ? 1 : 0)
                .scaleEffect(showPencil ? 1 : 0.4)
        }
        .frame(width: 220, height: 220)
    }

    private func runIntro() {
        guard !reduceMotion else {
            showPlate = true
            showNotebook = true
            showPencil = true
            showName = true
            pencilWiggle = 0
            checkProgress = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                onFinished()
            }
            return
        }

        // 0.00s: circle plate springs in
        withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
            showPlate = true
        }

        // 0.25s: notebook springs in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showNotebook = true
            }
        }

        // 0.55s: pencil appears and does a small wiggle (±8°, twice)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                showPencil = true
            }
            withAnimation(.easeInOut(duration: 0.15).repeatCount(4, autoreverses: true)) {
                pencilWiggle = 8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.1)) {
                    pencilWiggle = 0
                }
            }
        }

        // 0.85s: check mark draws on over ~0.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(.easeInOut(duration: 0.5)) {
                checkProgress = 1
            }
        }

        // 1.2s: title reveals
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                showName = true
            }
        }

        // 2.4s: onFinished fires
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            onFinished()
        }
    }
}

/// Stroked V-shape check mark, sized to a 32×22 frame. Uses `Shape` so `.trim`
/// animates the stroke as if the pencil is drawing it on.
private struct CheckMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            // Scale a canonical (0,10)→(8,18)→(24,0) V into the given rect (24×18 design).
            let sx = rect.width / 24
            let sy = rect.height / 18
            p.move(to: CGPoint(x: 0 * sx, y: 10 * sy))
            p.addLine(to: CGPoint(x: 8 * sx, y: 18 * sy))
            p.addLine(to: CGPoint(x: 24 * sx, y: 0 * sy))
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
