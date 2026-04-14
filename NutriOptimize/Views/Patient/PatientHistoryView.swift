import SwiftUI
import SwiftData
import Charts

/// Displays the consultation timeline and progress charts for a patient.
/// Provides visual insight into weight trends, body composition, and macro prescriptions.
struct PatientHistoryView: View {
    let patientId: UUID
    let patientName: String

    @Environment(\.modelContext) private var modelContext
    @State private var consultations: [ConsultationRecord] = []
    @State private var selectedChart: ChartType = .weight
    @State private var expandedNoteId: UUID?
    @State private var hasLoaded = false

    enum ChartType: String, CaseIterable {
        case weight = "Peso"
        case bodyComp = "Composición"
        case calories = "Calorías"
        case macros = "Macronutrientes"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                if consultations.isEmpty {
                    emptyState
                } else {
                    chartSelector
                    chartSection
                    timelineSection
                }
            }
            .padding()
        }
        .background(AppTheme.surfaceWhite.ignoresSafeArea())
        .navigationTitle("Historial")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !hasLoaded else { return }
            loadConsultations()
            hasLoaded = true
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.deepOrange.opacity(0.4))
            Text("Sin consultas registradas")
                .font(AppTheme.subheadFont)
            Text("Las consultas aparecerán aquí conforme se registren.")
                .font(AppTheme.captionFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Chart Selector

    private var chartSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    let isBodyComp = type == .bodyComp
                    let hasBodyData = consultations.contains { $0.waistCircumference != nil }
                    if isBodyComp && !hasBodyData { EmptyView() } else {
                        Button {
                            HapticManager.selection()
                            withAnimation(.spring(response: 0.3)) { selectedChart = type }
                        } label: {
                            Text(type.rawValue)
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    selectedChart == type
                                        ? AppTheme.deepOrange
                                        : Color.gray.opacity(0.1),
                                    in: Capsule()
                                )
                                .foregroundStyle(selectedChart == type ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Chart Section

    @ViewBuilder
    private var chartSection: some View {
        switch selectedChart {
        case .weight:
            weightChart
        case .bodyComp:
            bodyCompositionChart
        case .calories:
            calorieChart
        case .macros:
            macroChart
        }
    }

    // MARK: - Weight Progress Chart

    private var weightChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Progreso de peso", systemImage: "scalemass")
                .font(AppTheme.subheadFont)
                .foregroundStyle(AppTheme.deepOrange)

            if let first = consultations.first, let last = consultations.last {
                let diff = last.weight - first.weight
                HStack(spacing: 8) {
                    Text(String(format: "%.1f kg → %.1f kg", first.weight, last.weight))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%@%.1f kg", diff > 0 ? "+" : "", diff))
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(diff <= 0 ? AppTheme.success : AppTheme.danger)
                }
            }

            Chart(consultations, id: \.id) { record in
                LineMark(
                    x: .value("Fecha", record.date),
                    y: .value("Peso", record.weight)
                )
                .foregroundStyle(AppTheme.deepOrange)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Fecha", record.date),
                    y: .value("Peso", record.weight)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.deepOrange.opacity(0.3), AppTheme.deepOrange.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Fecha", record.date),
                    y: .value("Peso", record.weight)
                )
                .foregroundStyle(AppTheme.deepOrange)
                .symbolSize(40)
                .annotation(position: .top, spacing: 4) {
                    Text(String(format: "%.1f", record.weight))
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 14)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    AxisValueLabel()
                }
            }
            .frame(height: 220)
        }
        .cardStyle()
    }

    // MARK: - Body Composition Chart

    private var bodyCompositionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Circunferencias corporales", systemImage: "figure.arms.open")
                .font(AppTheme.subheadFont)
                .foregroundStyle(AppTheme.deepOrange)

            let dataPoints = consultations.compactMap { record -> BodyCompEntry? in
                guard let waist = record.waistCircumference else { return nil }
                return BodyCompEntry(
                    date: record.date, waist: waist,
                    hip: record.hipCircumference ?? 0,
                    arm: record.armCircumference ?? 0)
            }

            Chart(dataPoints, id: \.date) { entry in
                LineMark(x: .value("Fecha", entry.date), y: .value("cm", entry.waist), series: .value("Medida", "Cintura"))
                    .foregroundStyle(AppTheme.calorieColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol(.circle)

                LineMark(x: .value("Fecha", entry.date), y: .value("cm", entry.hip), series: .value("Medida", "Cadera"))
                    .foregroundStyle(AppTheme.proteinColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol(.square)

                LineMark(x: .value("Fecha", entry.date), y: .value("cm", entry.arm), series: .value("Medida", "Brazo"))
                    .foregroundStyle(AppTheme.carbColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol(.triangle)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartForegroundStyleScale([
                "Cintura": AppTheme.calorieColor,
                "Cadera": AppTheme.proteinColor,
                "Brazo": AppTheme.carbColor,
            ])
            .chartLegend(position: .bottom, alignment: .center)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 14)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
                }
            }
            .frame(height: 220)
        }
        .cardStyle()
    }

    // MARK: - Calorie Prescription Chart

    private var calorieChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Calorías prescritas por consulta", systemImage: "flame")
                .font(AppTheme.subheadFont)
                .foregroundStyle(AppTheme.calorieColor)

            Chart(consultations, id: \.id) { record in
                BarMark(
                    x: .value("Fecha", record.date, unit: .day),
                    y: .value("kcal", record.totalCaloriesPrescribed)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.calorieColor, AppTheme.warmOrange],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
                .annotation(position: .top, spacing: 4) {
                    Text("\(Int(record.totalCaloriesPrescribed))")
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 14)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
                }
            }
            .frame(height: 220)
        }
        .cardStyle()
    }

    // MARK: - Macro Distribution Chart

    private var macroChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Distribución de macronutrientes", systemImage: "chart.bar.xaxis")
                .font(AppTheme.subheadFont)
                .foregroundStyle(AppTheme.deepOrange)

            Chart(consultations, id: \.id) { record in
                LineMark(
                    x: .value("Fecha", record.date),
                    y: .value("g", record.totalProtein),
                    series: .value("Macro", "Proteína")
                )
                .foregroundStyle(AppTheme.proteinColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .symbol(.circle)

                LineMark(
                    x: .value("Fecha", record.date),
                    y: .value("g", record.totalCarbs),
                    series: .value("Macro", "Carbohidratos")
                )
                .foregroundStyle(AppTheme.carbColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .symbol(.square)

                LineMark(
                    x: .value("Fecha", record.date),
                    y: .value("g", record.totalFat),
                    series: .value("Macro", "Grasas")
                )
                .foregroundStyle(AppTheme.fatColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .symbol(.triangle)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartForegroundStyleScale([
                "Proteína": AppTheme.proteinColor,
                "Carbohidratos": AppTheme.carbColor,
                "Grasas": AppTheme.fatColor,
            ])
            .chartLegend(position: .bottom, alignment: .center)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 14)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
                }
            }
            .frame(height: 220)
        }
        .cardStyle()
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Línea de tiempo", systemImage: "clock.arrow.circlepath")
                .font(AppTheme.subheadFont)
                .foregroundStyle(AppTheme.deepOrange)

            ForEach(Array(consultations.reversed().enumerated()), id: \.element.id) { index, record in
                timelineEntry(record, isLast: index == consultations.count - 1)
            }
        }
    }

    private func timelineEntry(_ record: ConsultationRecord, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(AppTheme.deepOrange)
                    .frame(width: 12, height: 12)
                if !isLast {
                    Rectangle()
                        .fill(AppTheme.deepOrange.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)

            // Content card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(record.date, format: .dateTime.day().month(.wide).year())
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.deepOrange)
                    Spacer()
                    Text(String(format: "%.1f kg", record.weight))
                        .font(.system(.caption, design: .rounded, weight: .bold))
                }

                Text(record.planSummary)
                    .font(.system(.subheadline, design: .rounded))
                    .lineLimit(2)

                // Macro badges
                HStack(spacing: 10) {
                    macroBadge(value: record.totalCaloriesPrescribed, unit: "kcal", color: AppTheme.calorieColor)
                    macroBadge(value: record.totalProtein, unit: "g P", color: AppTheme.proteinColor)
                    macroBadge(value: record.totalCarbs, unit: "g C", color: AppTheme.carbColor)
                    macroBadge(value: record.totalFat, unit: "g G", color: AppTheme.fatColor)
                }

                // Expandable clinical notes
                if !record.clinicalNotes.isEmpty {
                    Button {
                        HapticManager.impact(.light)
                        withAnimation(.spring(response: 0.3)) {
                            expandedNoteId = expandedNoteId == record.id ? nil : record.id
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: expandedNoteId == record.id ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                            Text("Notas clínicas")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                        }
                        .foregroundStyle(AppTheme.deepOrange)
                    }
                    .buttonStyle(.plain)

                    if expandedNoteId == record.id {
                        Text(record.clinicalNotes)
                            .font(AppTheme.captionFont)
                            .foregroundStyle(.secondary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Progress photo thumbnail
                if let photoPath = record.progressPhotoPath {
                    progressPhotoThumbnail(path: photoPath)
                }
            }
            .cardStyle()
        }
    }

    private func macroBadge(value: Double, unit: String, color: Color) -> some View {
        Text("\(Int(value)) \(unit)")
            .font(.system(.caption2, design: .rounded, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1), in: Capsule())
    }

    @ViewBuilder
    private func progressPhotoThumbnail(path: String) -> some View {
        if let image = UIImage(contentsOfFile: path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Data Loading

    private func loadConsultations() {
        let targetId = patientId
        var descriptor = FetchDescriptor<ConsultationRecord>(
            predicate: #Predicate<ConsultationRecord> { $0.patientId == targetId },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        descriptor.fetchLimit = 100
        consultations = (try? modelContext.fetch(descriptor)) ?? []
    }
}

// MARK: - Supporting Types

private struct BodyCompEntry {
    let date: Date
    let waist: Double
    let hip: Double
    let arm: Double
}
