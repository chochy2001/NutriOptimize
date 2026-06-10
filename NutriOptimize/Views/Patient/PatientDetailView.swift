import SwiftUI
import SwiftData

struct PatientDetailView: View {
    @StateObject var viewModel: PatientDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showDraftEditor = false
    @State private var showEditPatient = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                profileHeader
                metricsGrid
                ContextualAssistantView(
                    insights: InsightGenerator.forPatientProfile(patient: viewModel.patient)
                )
                .padding(.horizontal)
                Divider().padding(.horizontal)
                clinicalInfo
                Divider().padding(.horizontal)
                patientActionsSection
                generateButton
            }
            .padding(.bottom, 20)
        }
        .background(AppTheme.surfaceWhite.ignoresSafeArea())
        .navigationTitle(viewModel.patient.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticManager.selection()
                    showEditPatient = true
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                        .foregroundStyle(AppTheme.deepOrange)
                }
            }
        }
        .onAppear { viewModel.modelContext = modelContext }
        .sheet(isPresented: $showEditPatient) {
            AddEditPatientView(patient: viewModel.patient) { updatedPatient in
                viewModel.patient = updatedPatient
            }
        }
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
        .sheet(isPresented: $viewModel.needsDataProcessingConsent) {
            DataProcessingConsentView(
                onAccept: {
                    Task { await viewModel.confirmConsentAndGenerate() }
                },
                onCancel: {
                    viewModel.needsDataProcessingConsent = false
                }
            )
        }
        .onChange(of: viewModel.generatedDraft) {
            if viewModel.generatedDraft != nil {
                showDraftEditor = true
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 14) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.warmOrange, AppTheme.deepOrange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 76, height: 76)
                .overlay {
                    Text(viewModel.patient.fullName.prefix(1))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }
                .shadow(color: AppTheme.deepOrange.opacity(0.3), radius: 8, y: 4)

            VStack(spacing: 4) {
                Text(viewModel.patient.fullName)
                    .font(AppTheme.headlineFont)

                Text(viewModel.patient.clinicalGoals)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                infoPill(icon: "figure.walk", text: viewModel.patient.activityLevel.rawValue)
                if let age = Optional(viewModel.patient.age), age > 0 {
                    infoPill(icon: "calendar", text: "\(age) años")
                }
                infoPill(icon: "person.fill", text: viewModel.patient.sex.rawValue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal)
    }

    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.system(.caption2, design: .rounded, weight: .medium))
        }
        .foregroundStyle(AppTheme.deepOrange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppTheme.lightOrange, in: Capsule())
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            metricCard(title: "Peso", value: String(format: "%.1f", viewModel.patient.weight), unit: "kg", icon: "scalemass")
            metricCard(title: "Altura", value: String(format: "%.0f", viewModel.patient.height), unit: "cm", icon: "ruler")
            metricCard(title: "IMC", value: String(format: "%.1f", viewModel.patient.bmi), unit: viewModel.patient.bmiClassification, icon: "heart.text.square")
            metricCard(title: "TDEE", value: "\(Int(viewModel.patient.estimatedTDEE))", unit: "kcal", icon: "flame")
        }
        .padding(.horizontal)
    }

    private func metricCard(title: String, value: String, unit: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppTheme.deepOrange)
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
            Text(unit)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    // MARK: - Clinical Info (editable via edit button)

    private var clinicalInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Información clínica")
                    .font(AppTheme.subheadFont)
                Spacer()
                Button {
                    HapticManager.selection()
                    showEditPatient = true
                } label: {
                    Label("Editar", systemImage: "pencil")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(AppTheme.deepOrange)
                }
            }
            .padding(.horizontal)

            if !viewModel.patient.allergies.isEmpty {
                tagRow(title: "Alergias", icon: "exclamationmark.triangle.fill", color: AppTheme.danger, items: viewModel.patient.allergies)
            }
            if !viewModel.patient.medicalConditions.isEmpty {
                tagRow(title: "Condiciones", icon: "cross.case.fill", color: .purple, items: viewModel.patient.medicalConditions)
            }
            if !viewModel.patient.dietaryPreferences.isEmpty {
                tagRow(title: "Preferencias", icon: "fork.knife", color: AppTheme.success, items: viewModel.patient.dietaryPreferences)
            }
            if viewModel.patient.allergies.isEmpty && viewModel.patient.medicalConditions.isEmpty && viewModel.patient.dietaryPreferences.isEmpty {
                HStack {
                    Spacer()
                    Text("Sin información clínica registrada")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
    }

    private func tagRow(title: String, icon: String, color: Color, items: [String]) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(color)

                FlowLayout(spacing: 6) {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                            .font(.system(.caption2, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(color.opacity(0.1), in: Capsule())
                            .foregroundStyle(color)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Patient Actions (History, Photos, Labs, Feedback)

    private var patientActionsSection: some View {
        VStack(spacing: 8) {
            Text("Herramientas clínicas")
                .font(AppTheme.subheadFont)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                actionCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Historial",
                    subtitle: "Consultas y gráficas",
                    destination: AnyView(PatientHistoryView(patientId: viewModel.patient.id, patientName: viewModel.patient.fullName, patientGoals: viewModel.patient.clinicalGoals))
                )
                actionCard(
                    icon: "camera.viewfinder",
                    title: "Fotos",
                    subtitle: "Progreso visual",
                    destination: AnyView(ProgressPhotoView(patientId: viewModel.patient.id, patientName: viewModel.patient.fullName))
                )
                actionCard(
                    icon: "cross.vial",
                    title: "Laboratorios",
                    subtitle: "Estudios clínicos",
                    destination: AnyView(LabResultsView(patientId: viewModel.patient.id, patientName: viewModel.patient.fullName))
                )
                actionCard(
                    icon: "slider.horizontal.3",
                    title: "Feedback",
                    subtitle: "Preferencias y exclusiones",
                    destination: AnyView(PatientFeedbackView(patientId: viewModel.patient.id, patientName: viewModel.patient.fullName))
                )
            }
            .padding(.horizontal)
        }
    }

    private func actionCard(icon: String, title: String, subtitle: String, destination: AnyView) -> some View {
        NavigationLink {
            destination
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(AppTheme.deepOrange)
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Text(subtitle)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
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
            .padding(.horizontal)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 4)
    }
}

/// Flow layout for tag-like elements that wrap across lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (i, pos) in result.positions.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxW = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, lh: CGFloat = 0

        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > maxW, x > 0 { x = 0; y += lh + spacing; lh = 0 }
            positions.append(CGPoint(x: x, y: y))
            lh = max(lh, s.height)
            x += s.width + spacing
        }

        let w = min(maxW, positions.reduce(0) { max($0, $1.x) } + (subviews.last.map { $0.sizeThatFits(.unspecified).width } ?? 0))
        return (positions, CGSize(width: w, height: y + lh))
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
