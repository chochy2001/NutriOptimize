import SwiftUI

/// Configuration view for the optimization engine connection and professional preferences.
/// Stores settings in UserDefaults for quick hackathon-grade persistence.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = OpenRouterService.apiKey
    @State private var customPrompt: String = OpenRouterService.customPrompt
    @State private var showDebugView: Bool = UserDefaults.standard.bool(forKey: "show_engine_debug")
    @State private var showSaveConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                engineSection
                promptSection
                debugSection
                infoSection
            }
            .navigationTitle("Configuraci\u{00F3}n")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveSettings() }
                        .fontWeight(.semibold)
                }
            }
            .overlay {
                if showSaveConfirmation {
                    saveConfirmationOverlay
                }
            }
        }
    }

    // MARK: - Sections

    private var engineSection: some View {
        Section {
            SecureField("API Key de OpenRouter", text: $apiKey)
                .textContentType(.password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        } header: {
            Text("Motor de Optimizaci\u{00F3}n")
        } footer: {
            Text("Obt\u{00E9}n tu clave en openrouter.ai/keys. Se almacena localmente en el dispositivo.")
        }
    }

    private var promptSection: some View {
        Section {
            TextField("Describe tus patrones de prescripci\u{00F3}n habituales...", text: $customPrompt, axis: .vertical)
                .lineLimit(4...10)
        } header: {
            Text("Prompt de Optimizaci\u{00F3}n Personalizado")
        } footer: {
            Text("El motor usar\u{00E1} estas indicaciones junto con el perfil del paciente. Ejemplo: \"Priorizo dietas mediterr\u{00E1}neas, evito suplementos artificiales, prefiero 5 comidas al d\u{00ED}a.\"")
        }
    }

    private var debugSection: some View {
        Section {
            Toggle("Mostrar procesamiento del motor", isPresented: $showDebugView)
        } footer: {
            Text("Permite ver el prompt enviado y la respuesta cruda del motor de optimizaci\u{00F3}n para verificaci\u{00F3}n profesional.")
        }
    }

    private var infoSection: some View {
        Section {
            HStack {
                Text("Modelo")
                Spacer()
                Text("Gemini 2.5 Flash")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Proveedor")
                Spacer()
                Text("OpenRouter")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Estado")
                Spacer()
                if OpenRouterService.isConfigured {
                    Label("Configurado", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)
                        .font(AppTheme.captionFont)
                } else {
                    Label("Sin configurar", systemImage: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.danger)
                        .font(AppTheme.captionFont)
                }
            }
        } header: {
            Text("Informaci\u{00F3}n del Motor")
        }
    }

    // MARK: - Save

    private func saveSettings() {
        OpenRouterService.apiKey = apiKey
        OpenRouterService.customPrompt = customPrompt
        UserDefaults.standard.set(showDebugView, forKey: "show_engine_debug")
        HapticManager.notification(.success)

        withAnimation(.spring(response: 0.3)) {
            showSaveConfirmation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showSaveConfirmation = false }
            dismiss()
        }
    }

    private var saveConfirmationOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.success)
            Text("Guardado")
                .font(AppTheme.subheadFont)
        }
        .padding(32)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 20))
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Toggle Convenience

private extension Toggle where Label == Text {
    init(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>) {
        self.init(titleKey, isOn: isPresented)
    }
}

#Preview {
    SettingsView()
}
