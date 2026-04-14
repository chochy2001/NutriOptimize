import SwiftUI
import SwiftData

/// Displays laboratory test results for a patient, grouped by date.
/// Shows trend indicators by comparing sequential values of the same test.
struct LabResultsView: View {
    let patientId: UUID
    let patientName: String

    @Environment(\.modelContext) private var modelContext
    @State private var results: [LabResultRecord] = []
    @State private var showAddSheet = false
    @State private var showImportSheet = false
    @State private var hasLoaded = false

    /// Groups results by test date for section-based display.
    private var groupedByDate: [(date: Date, records: [LabResultRecord])] {
        let grouped = Dictionary(grouping: results) { record in
            Calendar.current.startOfDay(for: record.testDate)
        }
        return grouped
            .map { (date: $0.key, records: $0.value.sorted { $0.testName < $1.testName }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                if !results.isEmpty {
                    ContextualAssistantView(
                        insights: InsightGenerator.forLabResults(results: results)
                    )
                }
                if results.isEmpty {
                    emptyState
                } else {
                    summaryBanner
                    ForEach(groupedByDate, id: \.date) { group in
                        dateSection(group.date, records: group.records)
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.surfaceWhite.ignoresSafeArea())
        .navigationTitle("Laboratorio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showImportSheet = true
                    } label: {
                        Image(systemName: "doc.badge.plus")
                            .foregroundStyle(AppTheme.deepOrange)
                    }
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppTheme.deepOrange)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddLabResultSheet(patientId: patientId) {
                loadResults()
            }
        }
        .sheet(isPresented: $showImportSheet) {
            LabImportView(patientId: patientId) {
                loadResults()
            }
        }
        .onAppear {
            guard !hasLoaded else { return }
            loadResults()
            hasLoaded = true
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.deepOrange.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "cross.vial")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.deepOrange.opacity(0.5))
            }

            Text("Sin estudios registrados")
                .font(AppTheme.subheadFont)

            Text("Registra resultados de laboratorio como glucosa, perfil lipídico, pruebas hepáticas y más. Podrás ver tendencias y valores fuera de rango.")
                .font(AppTheme.captionFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Agregar resultado")
                        .fontWeight(.semibold)
                }
                .font(.system(.subheadline, design: .rounded))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.deepOrange)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Summary Banner

    private var summaryBanner: some View {
        let outOfRangeCount = results.filter(\.isOutOfRange).count
        let latestDate = groupedByDate.first?.date

        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(results.count) resultados")
                    .font(AppTheme.subheadFont)
                if let date = latestDate {
                    Text("Último estudio: \(date, format: .dateTime.day().month(.wide).year())")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if outOfRangeCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text("\(outOfRangeCount) fuera de rango")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(AppTheme.danger)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.danger.opacity(0.1), in: Capsule())
            }
        }
        .cardStyle()
    }

    // MARK: - Date Section

    private func dateSection(_ date: Date, records: [LabResultRecord]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.deepOrange)
                Text(date, format: .dateTime.day().month(.wide).year())
                    .font(AppTheme.subheadFont)
                Spacer()
                let outCount = records.filter(\.isOutOfRange).count
                if outCount > 0 {
                    Text("\(outCount) alterado\(outCount == 1 ? "" : "s")")
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.danger)
                }
            }

            ForEach(records, id: \.id) { record in
                labResultRow(record)
            }
        }
        .cardStyle()
    }

    private func labResultRow(_ record: LabResultRecord) -> some View {
        HStack(spacing: 10) {
            // Status indicator
            Circle()
                .fill(record.isOutOfRange ? AppTheme.danger : AppTheme.success)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.testName)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                Text("Ref: \(record.referenceRange) \(record.unit)")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Trend arrow
            if let trend = trendForTest(record) {
                Image(systemName: trend.icon)
                    .font(.caption2)
                    .foregroundStyle(trend.color)
            }

            // Value
            Text(formattedValue(record.value))
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(record.isOutOfRange ? AppTheme.danger : .primary)

            Text(record.unit)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Trend Calculation

    /// Compares the current test value against the previous result of the same test
    /// to determine directional trend for clinical insight.
    private func trendForTest(_ record: LabResultRecord) -> TrendInfo? {
        let sameTestResults = results
            .filter { $0.testName == record.testName }
            .sorted { $0.testDate < $1.testDate }

        guard sameTestResults.count >= 2,
              let currentIndex = sameTestResults.firstIndex(where: { $0.id == record.id }),
              currentIndex > 0 else {
            return nil
        }

        let previous = sameTestResults[currentIndex - 1]
        let diff = record.value - previous.value
        let threshold = previous.value * 0.01 // 1% threshold for "stable"

        if abs(diff) < threshold {
            return TrendInfo(icon: "minus", color: .secondary)
        } else if diff > 0 {
            return TrendInfo(icon: "arrow.up", color: AppTheme.danger)
        } else {
            return TrendInfo(icon: "arrow.down", color: AppTheme.success)
        }
    }

    private func formattedValue(_ value: Double) -> String {
        if value == value.rounded() && value >= 10 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    // MARK: - Data Loading

    private func loadResults() {
        let targetId = patientId
        let descriptor = FetchDescriptor<LabResultRecord>(
            predicate: #Predicate<LabResultRecord> { $0.patientId == targetId },
            sortBy: [SortDescriptor(\.testDate, order: .reverse)]
        )
        results = (try? modelContext.fetch(descriptor)) ?? []
    }
}

// MARK: - Trend Info

private struct TrendInfo {
    let icon: String
    let color: Color
}

// MARK: - Add Lab Result Sheet

/// Form for manually entering a new laboratory test result.
struct AddLabResultSheet: View {
    let patientId: UUID
    var onSave: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTemplate: String = ""
    @State private var testName: String = ""
    @State private var value: String = ""
    @State private var unit: String = "mg/dL"
    @State private var referenceRange: String = ""
    @State private var isOutOfRange = false
    @State private var testDate = Date.now
    @State private var notes: String = ""

    /// Common lab test templates with pre-filled units and reference ranges.
    private let templates: [(name: String, unit: String, range: String)] = [
        ("Glucosa en ayunas", "mg/dL", "70-100"),
        ("HbA1c", "%", "< 7.0"),
        ("Colesterol total", "mg/dL", "< 200"),
        ("Triglicéridos", "mg/dL", "< 150"),
        ("HDL", "mg/dL", "> 50"),
        ("LDL", "mg/dL", "< 100"),
        ("TSH", "mU/L", "0.4-4.0"),
        ("T3 libre", "pg/mL", "2.0-4.4"),
        ("T4 libre", "ng/dL", "0.8-1.8"),
        ("Hemoglobina", "g/dL", "12.0-16.0"),
        ("Albúmina", "g/dL", "3.5-5.5"),
        ("Creatinina", "mg/dL", "0.7-1.3"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                templateSection
                detailsSection
                dateSection
                saveSection
            }
            .navigationTitle("Nuevo resultado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private var templateSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(templates, id: \.name) { template in
                        Button {
                            HapticManager.selection()
                            testName = template.name
                            unit = template.unit
                            referenceRange = template.range
                            selectedTemplate = template.name
                        } label: {
                            Text(template.name)
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    selectedTemplate == template.name
                                        ? AppTheme.deepOrange
                                        : Color.gray.opacity(0.1),
                                    in: Capsule()
                                )
                                .foregroundStyle(selectedTemplate == template.name ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Pruebas comunes")
        }
    }

    private var detailsSection: some View {
        Section {
            TextField("Nombre de la prueba", text: $testName)
            TextField("Valor", text: $value)
                .keyboardType(.decimalPad)
            TextField("Unidad", text: $unit)
            TextField("Rango de referencia", text: $referenceRange)
            Toggle("Fuera de rango", isOn: $isOutOfRange)
            TextField("Notas (opcional)", text: $notes)
        } header: {
            Text("Detalles del resultado")
        }
    }

    private var dateSection: some View {
        Section {
            DatePicker("Fecha del estudio", selection: $testDate, displayedComponents: .date)
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                saveResult()
            } label: {
                HStack {
                    Spacer()
                    Text("Guardar resultado")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(testName.isEmpty || value.isEmpty)
        }
    }

    private func saveResult() {
        guard let numericValue = Double(value) else { return }

        let record = LabResultRecord(
            patientId: patientId,
            testDate: testDate,
            testName: testName,
            value: numericValue,
            unit: unit,
            referenceRange: referenceRange,
            isOutOfRange: isOutOfRange,
            notes: notes
        )
        modelContext.insert(record)
        try? modelContext.save()
        HapticManager.notification(.success)
        onSave()
        dismiss()
    }
}
