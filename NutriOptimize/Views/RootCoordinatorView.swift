import SwiftUI

struct RootCoordinatorView: View {
    private enum Phase {
        case splash
        case onboarding
        case main
    }

    private static let hasSeenOnboardingKey = "hasSeenOnboarding"

    @State private var phase: Phase = .splash

    var body: some View {
        ZStack {
            switch phase {
            case .splash:
                SplashView(onFinished: advanceFromSplash)
                    .transition(.opacity)
            case .onboarding:
                OnboardingView(onFinished: finishOnboarding)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .main:
                OptimizationDashboardView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: phase)
    }

    private func advanceFromSplash() {
        let hasSeen = UserDefaults.standard.bool(forKey: Self.hasSeenOnboardingKey)
        phase = hasSeen ? .main : .onboarding
    }

    private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.hasSeenOnboardingKey)
        phase = .main
    }
}

#Preview {
    RootCoordinatorView()
}
