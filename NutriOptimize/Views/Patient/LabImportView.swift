import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Allows importing laboratory results from PDF or JSON files.
/// Wraps UIDocumentPickerViewController and presents parsed results for review.
struct LabImportView: View {
    let patientId: UUID
    var onImportComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showDocumentPicker = true
    @State private var parsedResults: [LabDocumentImporter.ParsedResult] = []
    @State private var importError: String?
    @State private var hasResults = false

    private let importer = LabDocumentImporter()

    var body: some View {
        NavigationStack {
            Group {
                if let error = importError {
                    errorView(error)
                } else if hasResults {
                    resultsList
                } else {
                    loadingView
                }
            }
            .navigationTitle("Importar resultados")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(
                    supportedTypes: [.pdf, .json],
                    onPick: { url in handleFile(url) },
                    onCancel: { dismiss() }
                )
            }
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    headerBanner
                    resultsSection
                }
                .padding()
            }
            .background(AppTheme.surfaceWhite)

            importButton
        }
    }

    private var headerBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.title2)
                .foregroundStyle(AppTheme.deepOrange)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(parsedResults.count) resultados encontrados")
                    .font(AppTheme.subheadFont)
                Text("Selecciona los que deseas importar")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                HapticManager.selection()
                toggleAll()
            } label: {
                Text(allSelected ? "Ninguno" : "Todos")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.deepOrange.opacity(0.1), in: Capsule())
                    .foregroundStyle(AppTheme.deepOrange)
            }
        }
        .cardStyle()
    }

    private var resultsSection: some View {
        VStack(spacing: 8) {
            ForEach(parsedResults.indices, id: \.self) { index in
                resultRow(index: index)
            }
        }
    }

    private func resultRow(index: Int) -> some View {
        let result = parsedResults[index]

        return Button {
            HapticManager.selection()
            parsedResults[index].isSelected.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: result.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(result.isSelected ? AppTheme.deepOrange : .gray.opacity(0.4))

                VStack(alignment: .leading, spacing: 3) {
                    Text(result.testName)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        if !result.referenceRange.isEmpty {
                            Text("Ref: \(result.referenceRange)")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.tertiary)
                        }
                        Text(result.date, format: .dateTime.day().month(.abbreviated).year())
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                if result.isOutOfRange {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.danger)
                }

                Text(formattedValue(result.value))
                    .font(.system(.subheadline, design: .monospaced, weight: .bold))
                    .foregroundStyle(result.isOutOfRange ? AppTheme.danger : .primary)

                Text(result.unit)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, AppTheme.cardPadding)
            .background(.white, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Import Button

    private var importButton: some View {
        let selectedCount = parsedResults.filter(\.isSelected).count

        return Button {
            saveSelectedResults()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down.fill")
                Text("Importar seleccionados (\(selectedCount))")
                    .fontWeight(.semibold)
            }
            .font(.system(.body, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.deepOrange)
        .disabled(selectedCount == 0)
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.danger.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.danger.opacity(0.6))
            }

            Text("Error al importar")
                .font(AppTheme.subheadFont)

            Text(message)
                .font(AppTheme.captionFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                importError = nil
                showDocumentPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Intentar de nuevo")
                        .fontWeight(.semibold)
                }
                .font(.system(.subheadline, design: .rounded))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.deepOrange)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.surfaceWhite)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Selecciona un archivo...")
                .font(AppTheme.captionFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.surfaceWhite)
    }

    // MARK: - Helpers

    private var allSelected: Bool {
        parsedResults.allSatisfy(\.isSelected)
    }

    private func toggleAll() {
        let newValue = !allSelected
        for index in parsedResults.indices {
            parsedResults[index].isSelected = newValue
        }
    }

    private func formattedValue(_ value: Double) -> String {
        if value == value.rounded() && value >= 10 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    private func handleFile(_ url: URL) {
        do {
            let results = try importer.importFile(at: url)
            if results.isEmpty {
                importError = "No se encontraron resultados de laboratorio en el archivo."
            } else {
                parsedResults = results
                hasResults = true
                HapticManager.notification(.success)
            }
        } catch {
            importError = error.localizedDescription
            HapticManager.notification(.error)
        }
    }

    private func saveSelectedResults() {
        let selected = parsedResults.filter(\.isSelected)
        for result in selected {
            let record = LabResultRecord(
                patientId: patientId,
                testDate: result.date,
                testName: result.testName,
                value: result.value,
                unit: result.unit,
                referenceRange: result.referenceRange,
                isOutOfRange: result.isOutOfRange
            )
            modelContext.insert(record)
        }
        try? modelContext.save()
        HapticManager.notification(.success)
        onImportComplete()
        dismiss()
    }
}

// MARK: - Document Picker (UIKit Bridge)

/// UIViewControllerRepresentable wrapper for UIDocumentPickerViewController.
/// Presents the system file picker for selecting PDF and JSON documents.
struct DocumentPicker: UIViewControllerRepresentable {
    let supportedTypes: [UTType]
    let onPick: (URL) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}
