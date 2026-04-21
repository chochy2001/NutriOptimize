import SwiftUI

struct OnboardingView: View {
    let onFinished: () -> Void

    @State private var currentPage: Int = 0

    private let pages: [OnboardingPageContent] = [
        OnboardingPageContent(
            icon: "leaf.circle.fill",
            title: "Bienvenido a NutriOptimize",
            body: "Tu asistente para optimizar planes nutricionales. Diseñada para que dediques más tiempo a tus pacientes y menos a la administración."
        ),
        OnboardingPageContent(
            icon: "person.2.fill",
            title: "Gestiona tus pacientes",
            body: "Registra pacientes, consulta su historial, resultados de laboratorio y fotos de progreso desde un solo lugar."
        ),
        OnboardingPageContent(
            icon: "wand.and.stars",
            title: "Optimiza planes con IA",
            body: "NutriOptimize genera borradores de planes nutricionales que tú revisas, ajustas y apruebas. Mantén el control, ahorra tiempo."
        ),
        OnboardingPageContent(
            icon: "chart.line.uptrend.xyaxis",
            title: "Da seguimiento a resultados",
            body: "Revisa la evolución de cada paciente con consultas, análisis de laboratorio y fotos de progreso. Toma mejores decisiones basadas en datos."
        )
    ]

    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: currentPage)

                bottomControls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }

            if currentPage < pages.count - 1 {
                skipButton
                    .padding(.top, 8)
                    .padding(.trailing, 20)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [AppTheme.lightOrange.opacity(0.3), .white],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        Button {
            HapticManager.selection()
            onFinished()
        } label: {
            Text("Omitir")
                .font(AppTheme.subheadFont)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .accessibilityLabel("Omitir tutorial")
        .accessibilityHint("Cierra la introducción y entra a la aplicación")
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            pageIndicator

            primaryButton

            backButton
                .opacity(currentPage > 0 ? 1 : 0)
                .disabled(currentPage == 0)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? AppTheme.primaryOrange : Color.gray.opacity(0.3))
                    .frame(width: index == currentPage ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: currentPage)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Página \(currentPage + 1) de \(pages.count)")
    }

    private var primaryButton: some View {
        Button {
            HapticManager.selection()
            if currentPage < pages.count - 1 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    currentPage += 1
                }
            } else {
                onFinished()
            }
        } label: {
            Text(isLastPage ? "Comenzar" : "Siguiente")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule().fill(AppTheme.primaryOrange)
                )
        }
        .accessibilityLabel(isLastPage ? "Comenzar a usar NutriOptimize" : "Siguiente página")
    }

    private var backButton: some View {
        Button {
            HapticManager.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                currentPage = max(0, currentPage - 1)
            }
        } label: {
            Text("Atrás")
                .font(AppTheme.subheadFont)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        }
        .accessibilityLabel("Página anterior")
    }

    private var isLastPage: Bool {
        currentPage == pages.count - 1
    }
}

// MARK: - Page Content Model

private struct OnboardingPageContent {
    let icon: String
    let title: String
    let body: String
}

// MARK: - Page View

private struct OnboardingPageView: View {
    let page: OnboardingPageContent

    var body: some View {
        VStack(spacing: AppTheme.sectionSpacing) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.primaryOrange.opacity(0.12))
                    .frame(width: 180, height: 180)

                Image(systemName: page.icon)
                    .font(.system(size: 100, weight: .regular))
                    .foregroundStyle(AppTheme.primaryOrange)
                    .accessibilityHidden(true)
            }
            .padding(.bottom, 8)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 28)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title). \(page.body)")
    }
}

#Preview {
    OnboardingView(onFinished: {})
}
