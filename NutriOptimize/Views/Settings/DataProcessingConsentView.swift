import SwiftUI

/// One-time data-processing disclosure shown before any patient clinical data
/// is sent to the external optimization engine (OpenRouter / Gemini).
///
/// The professional must explicitly accept before the engine is invoked. The
/// decision is persisted via `OpenRouterService.hasDataProcessingConsent`.
struct DataProcessingConsentView: View {
    let onAccept: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(AppTheme.deepOrange)
                        Text(L10n.consentTitle)
                            .font(AppTheme.headlineFont)
                    }

                    Text(L10n.consentBody)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
            }
            .background(AppTheme.surfaceWhite.ignoresSafeArea())
            .navigationTitle(L10n.consentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button {
                        HapticManager.notification(.success)
                        onAccept()
                    } label: {
                        Text(L10n.consentAccept)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.deepOrange)

                    Button(role: .cancel) {
                        onCancel()
                    } label: {
                        Text(L10n.consentCancel)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
}

#Preview {
    DataProcessingConsentView(onAccept: {}, onCancel: {})
}
