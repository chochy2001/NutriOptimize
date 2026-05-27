import SwiftUI

struct OnboardingView: View {
    let onFinished: () -> Void

    @State private var currentPage: Int = 0

    private var pages: [OnboardingPageContent] {
        [
            OnboardingPageContent(
                icon: "leaf.circle.fill",
                title: L10n.onboardingWelcomeTitle,
                body: L10n.onboardingWelcomeBody
            ),
            OnboardingPageContent(
                icon: "person.2.fill",
                title: L10n.onboardingPatientsTitle,
                body: L10n.onboardingPatientsBody
            ),
            OnboardingPageContent(
                icon: "wand.and.stars",
                title: L10n.onboardingOptimizeTitle,
                body: L10n.onboardingOptimizeBody
            ),
            OnboardingPageContent(
                icon: "chart.line.uptrend.xyaxis",
                title: L10n.onboardingTrackTitle,
                body: L10n.onboardingTrackBody
            )
        ]
    }

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
            colors: [AppTheme.lightOrange.opacity(0.3), AppTheme.surface],
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
            Text(L10n.actionSkip)
                .font(AppTheme.subheadFont)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .accessibilityLabel(L10n.onboardingSkipAccessibility)
        .accessibilityHint(L10n.onboardingSkipHint)
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
        .accessibilityLabel(L10n.onboardingPageAccessibility(current: currentPage + 1, total: pages.count))
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
            Text(isLastPage ? L10n.actionStart : L10n.actionNext)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule().fill(AppTheme.primaryOrange)
                )
        }
        .accessibilityLabel(isLastPage ? L10n.onboardingStartAccessibility : L10n.onboardingNextAccessibility)
    }

    private var backButton: some View {
        Button {
            HapticManager.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                currentPage = max(0, currentPage - 1)
            }
        } label: {
            Text(L10n.actionBack)
                .font(AppTheme.subheadFont)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        }
        .accessibilityLabel(L10n.onboardingBackAccessibility)
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
