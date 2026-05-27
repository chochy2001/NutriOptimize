import SwiftUI

/// Configuration view for the optimization engine connection and professional preferences.
/// Stores settings in UserDefaults for quick hackathon-grade persistence.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = OpenRouterService.apiKey
    @State private var customPrompt: String = OpenRouterService.customPrompt
    @State private var showDebugView: Bool = UserDefaults.standard.bool(forKey: "show_engine_debug")
    @State private var showSaveConfirmation = false
    @State private var connectionStatus: ConnectionTestStatus = .idle
    @State private var isTestingConnection = false

    // Bound to the same AppStorage key the app root reads from, so flipping
    // this picker re-renders the entire window with the new color scheme.
    @AppStorage(AppearancePreference.storageKey) private var schemePreference: String = AppearancePreference.system.rawValue

    enum ConnectionTestStatus: Equatable {
        case idle
        case testing
        case success
        case failure(String)
    }

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                engineSection
                promptSection
                debugSection
                infoSection
            }
            .navigationTitle(L10n.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.actionClose) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.actionSave) { saveSettings() }
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

    private var appearanceSection: some View {
        Section {
            Picker(selection: $schemePreference) {
                ForEach(AppearancePreference.allCases) { option in
                    Label(option.localizedLabel, systemImage: option.iconName)
                        .tag(option.rawValue)
                }
            } label: {
                Text(L10n.appearanceColorMode)
            }
            .pickerStyle(.inline)
        } header: {
            Text(L10n.appearanceSectionTitle)
        } footer: {
            Text(L10n.appearanceFooter)
        }
    }

    private var engineSection: some View {
        Section {
            SecureField(L10n.settingsEngineApiKey, text: $apiKey)
                .textContentType(.password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Button {
                Task { await testConnection() }
            } label: {
                HStack(spacing: 8) {
                    if connectionStatus == .testing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: connectionStatusIcon)
                            .foregroundStyle(connectionStatusColor)
                    }
                    Text(L10n.settingsEngineTestConnection)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                    Spacer()
                    if case .success = connectionStatus {
                        Text(L10n.settingsEngineConnected)
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.success)
                    } else if case .failure(let msg) = connectionStatus {
                        Text(msg)
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.danger)
                            .lineLimit(1)
                    }
                }
            }
            .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty || connectionStatus == .testing)
        } header: {
            Text(L10n.settingsEngineSection)
        } footer: {
            Text(L10n.settingsEngineFooter)
        }
    }

    private var connectionStatusIcon: String {
        switch connectionStatus {
        case .idle: return "antenna.radiowaves.left.and.right"
        case .testing: return "antenna.radiowaves.left.and.right"
        case .success: return "checkmark.circle.fill"
        case .failure: return "xmark.circle.fill"
        }
    }

    private var connectionStatusColor: Color {
        switch connectionStatus {
        case .idle: return .secondary
        case .testing: return .secondary
        case .success: return AppTheme.success
        case .failure: return AppTheme.danger
        }
    }

    private func testConnection() async {
        connectionStatus = .testing

        guard let url = URL(string: "https://openrouter.ai/api/v1/models") else {
            connectionStatus = .failure(L10n.settingsInvalidURL)
            HapticManager.notification(.error)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespaces))", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                connectionStatus = .success
                HapticManager.notification(.success)
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                connectionStatus = .failure(L10n.settingsHTTPError(statusCode))
                HapticManager.notification(.error)
            }
        } catch {
            connectionStatus = .failure(L10n.settingsNoConnection)
            HapticManager.notification(.error)
        }
    }

    private var promptSection: some View {
        Section {
            TextField(L10n.settingsPromptPlaceholder, text: $customPrompt, axis: .vertical)
                .lineLimit(4...10)
        } header: {
            Text(L10n.settingsPromptSection)
        } footer: {
            Text(L10n.settingsPromptFooter)
        }
    }

    private var debugSection: some View {
        Section {
            Toggle(L10n.settingsDebugToggle, isOn: $showDebugView)
        } footer: {
            Text(L10n.settingsDebugFooter)
        }
    }

    private var infoSection: some View {
        Section {
            HStack {
                Text(L10n.settingsInfoModel)
                Spacer()
                Text("Gemini 2.5 Flash")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text(L10n.settingsInfoProvider)
                Spacer()
                Text("OpenRouter")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text(L10n.settingsInfoStatus)
                Spacer()
                if OpenRouterService.isConfigured {
                    Label(L10n.settingsInfoConfigured, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)
                        .font(AppTheme.captionFont)
                } else {
                    Label(L10n.settingsInfoNotConfigured, systemImage: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.danger)
                        .font(AppTheme.captionFont)
                }
            }
        } header: {
            Text(L10n.settingsInfoSection)
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
            Text(L10n.savedConfirmation)
                .font(AppTheme.subheadFont)
        }
        .padding(32)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 20))
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    SettingsView()
}
