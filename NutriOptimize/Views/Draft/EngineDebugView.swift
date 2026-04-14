import SwiftUI

/// Read-only view showing the prompt sent to the optimization engine and
/// the raw response received. Allows the nutritionist to verify the
/// engine's input data and reasoning process.
struct EngineDebugView: View {
    @ObservedObject private var debugStore = EngineDebugStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    promptSection
                    responseSection
                }
                .padding()
            }
            .background(AppTheme.surfaceWhite.ignoresSafeArea())
            .navigationTitle("Procesamiento del Motor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    // MARK: - Prompt Section

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Prompt Enviado", systemImage: "arrow.up.doc")
                    .font(AppTheme.subheadFont)
                    .foregroundStyle(AppTheme.deepOrange)

                Spacer()

                copyButton(text: debugStore.lastPrompt)
            }

            if debugStore.lastPrompt.isEmpty {
                emptyState("A\u{00FA}n no se ha enviado ning\u{00FA}n prompt.")
            } else {
                Text(debugStore.lastPrompt)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color(.systemGray6),
                        in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    )
            }
        }
    }

    // MARK: - Response Section

    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Respuesta del Motor", systemImage: "arrow.down.doc")
                    .font(AppTheme.subheadFont)
                    .foregroundStyle(AppTheme.info)

                Spacer()

                copyButton(text: debugStore.lastResponse)
            }

            if debugStore.lastResponse.isEmpty {
                emptyState("A\u{00FA}n no se ha recibido ninguna respuesta.")
            } else {
                Text(debugStore.lastResponse)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color(.systemGray6),
                        in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    )
            }
        }
    }

    // MARK: - Helpers

    private func copyButton(text: String) -> some View {
        Button {
            UIPasteboard.general.string = text
            HapticManager.notification(.success)
        } label: {
            Image(systemName: "doc.on.doc")
                .font(.subheadline)
        }
        .disabled(text.isEmpty)
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(AppTheme.captionFont)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
            )
    }
}

#Preview {
    EngineDebugView()
}
