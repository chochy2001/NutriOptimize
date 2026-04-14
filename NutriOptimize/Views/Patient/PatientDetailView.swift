import SwiftUI
import SwiftData

struct PatientDetailView: View {
    @StateObject var viewModel: PatientDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showDraftEditor = false
    @State private var showFeedbackView = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                profileHeader
                metricsGrid
                clinicalInfo
                patientActionsSection
                feedbackButton
                generateButton
            }
            .padding()
        }
        .background(AppTheme.surfaceWhite.ignoresSafeArea())
        .navigationTitle(viewModel.patient.fullName)
        .navigationBarTitleDisplayMode(.large)
        .onAppear { viewModel.modelContext = modelContext }
        .fullScreenCover(isPresented: $showDraftEditor) {
            if let draft = viewModel.generatedDraft {
                NavigationStack {
                    DraftEditorView(
                        viewModel: DraftEditorViewModel(
                            draft: draft,
                            patientName: viewModel.patient.fullName
                        ),
                        patient: viewModel.patient
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cerrar") {
                                showDraftEditor = false
                                viewModel.resetGeneration()
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.isGenerating },
            set: { _ in }
        )) {
            ProcessingStateView(progress: viewModel.generationProgress)
                .interactiveDismissDisabled()
        }
        .onChange(of: viewModel.generatedDraft) {
            if viewModel.generatedDraft != nil {
                showDraftEditor = true
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.warmOrange, AppTheme.deepOrange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 68, height: 68)
                .overlay {
                    Text(viewModel.patient.fullName.prefix(1))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.patient.fullName)
                    .font(AppTheme.headlineFont)
                Text(viewModel.patient.clinicalGoals)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.caption2)
                    Text(viewModel.patient.activityLevel.rawValue)
                        .font(.system(.caption2, design: .rounded))
                }
                .foregroundStyle(AppTheme.deepOrange)
            }

            Spacer()
        }
        .cardStyle()
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
            metricCard(title: "Peso", value: String(format: "%.1f", viewModel.patient.weight), unit: "kg", icon: "scalemass")
            metricCard(title: "Altura", value: String(format: "%.0f", viewModel.patient.height), unit: "cm", icon: "ruler")
            metricCard(title: "IMC", value: String(format: "%.1f", viewModel.patient.bmi), unit: viewModel.patient.bmiClassification, icon: "heart.text.square")
            metricCard(title: "TDEE", value: "\(Int(viewModel.patient.estimatedTDEE))", unit: "kcal", icon: "flame")
        }
    }

    private func metricCard(title: String, value: String, unit: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(AppTheme.deepOrange)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
            Text(unit)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
    }

    // MARK: - Clinical Info

    private var clinicalInfo: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !viewModel.patient.allergies.isEmpty {
                tagSection(title: "Alergias", icon: "exclamationmark.triangle.fill", color: AppTheme.danger, items: viewModel.patient.allergies)
            }
            if !viewModel.patient.medicalConditions.isEmpty {
                tagSection(title: "Condiciones médicas", icon: "cross.case.fill", color: .purple, items: viewModel.patient.medicalConditions)
            }
            if !viewModel.patient.dietaryPreferences.isEmpty {
                tagSection(title: "Preferencias alimenticias", icon: "fork.knife", color: AppTheme.success, items: viewModel.patient.dietaryPreferences)
            }
        }
    }

    private func tagSection(title: String, icon: String, color: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(AppTheme.subheadFont)
                .foregroundStyle(color)

            FlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(AppTheme.captionFont)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(color.opacity(0.1), in: Capsule())
                        .foregroundStyle(color)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Patient Actions (History, Photos, Lab Results)

    private var patientActionsSection: some View {
        VStack(spacing: 10) {
            NavigationLink {
                PatientHistoryView(patientId: viewModel.patient.id, patientName: viewModel.patient.fullName)
            } label: {
                actionRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Historial de consultas",
                    subtitle: "Gráficas de progreso y línea de tiempo"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ProgressPhotoView(patientId: viewModel.patient.id, patientName: viewModel.patient.fullName)
            } label: {
                actionRow(
                    icon: "camera.viewfinder",
                    title: "Fotos de progreso",
                    subtitle: "Registro fotográfico del avance"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                LabResultsView(patientId: viewModel.patient.id, patientName: viewModel.patient.fullName)
            } label: {
                actionRow(
                    icon: "cross.vial",
                    title: "Estudios de laboratorio",
                    subtitle: "Resultados y tendencias de análisis clínicos"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func actionRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.deepOrange)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.subheadFont)
                Text(subtitle)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .cardStyle()
    }

    // MARK: - Feedback Button

    private var feedbackButton: some View {
        NavigationLink {
            PatientFeedbackView(
                patientId: viewModel.patient.id,
                patientName: viewModel.patient.fullName
            )
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundStyle(AppTheme.deepOrange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Preferencias y feedback")
                        .font(AppTheme.subheadFont)
                    Text("Alimentos preferidos, exclusiones y notas")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        VStack(spacing: 8) {
            Button {
                HapticManager.impact(.medium)
                Task { await viewModel.generateOptimizedPlan() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                    Text("Generar Propuesta Optimizada")
                        .fontWeight(.semibold)
                }
                .font(.system(.body, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.deepOrange)
            .controlSize(.large)
            .disabled(viewModel.isGenerating)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isGenerating)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.danger)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 4)
    }
}

/// Simple flow layout for tag-like elements that wrap across lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, pos) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            lineHeight = max(lineHeight, size.height)
            x += size.width + spacing
        }

        let totalWidth = min(maxWidth, positions.reduce(0) { max($0, $1.x) } + (subviews.last.map { $0.sizeThatFits(.unspecified).width } ?? 0))
        return (positions, CGSize(width: totalWidth, height: y + lineHeight))
    }
}

#Preview {
    NavigationStack {
        PatientDetailView(
            viewModel: PatientDetailViewModel(
                patient: MockPatientService.samplePatients[0]
            )
        )
    }
}
