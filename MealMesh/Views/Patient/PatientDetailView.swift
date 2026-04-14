import SwiftUI

struct PatientDetailView: View {
    @StateObject var viewModel: PatientDetailViewModel
    @State private var showDraftReview = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                metricsCards
                clinicalInfo
                generateButton
            }
            .padding()
        }
        .navigationTitle(viewModel.patient.name)
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showDraftReview) {
            if let draft = viewModel.generatedDraft {
                NavigationStack {
                    ReviewDraftView(
                        viewModel: DraftReviewViewModel(
                            draft: draft,
                            patientName: viewModel.patient.name
                        )
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cerrar") {
                                showDraftReview = false
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
            DraftGenerationLoadingView(progress: viewModel.generationProgress)
                .interactiveDismissDisabled()
        }
        .onChange(of: viewModel.generatedDraft) {
            if viewModel.generatedDraft != nil {
                showDraftReview = true
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(.tint.opacity(0.12))
                .frame(width: 72, height: 72)
                .overlay {
                    Text(viewModel.patient.name.prefix(1))
                        .font(.largeTitle.bold())
                        .foregroundStyle(.tint)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.patient.name)
                    .font(.title2.bold())
                Text(viewModel.patient.goals)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Metrics Cards

    private var metricsCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            metricCard(title: "Peso", value: String(format: "%.1f", viewModel.patient.weight), unit: "kg", icon: "scalemass")
            metricCard(title: "Altura", value: String(format: "%.0f", viewModel.patient.height), unit: "cm", icon: "ruler")
            metricCard(title: "IMC", value: String(format: "%.1f", viewModel.patient.bmi), unit: viewModel.patient.bmiCategory, icon: "heart.text.square")
            metricCard(title: "Cocina", value: "\(viewModel.patient.cookingTime)", unit: "min", icon: "timer")
        }
    }

    private func metricCard(title: String, value: String, unit: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
            Text(value)
                .font(.title3.bold())
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Clinical Info

    private var clinicalInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !viewModel.patient.allergies.isEmpty {
                infoSection(
                    title: "Alergias",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .red,
                    items: viewModel.patient.allergies
                )
            }
            if !viewModel.patient.conditions.isEmpty {
                infoSection(
                    title: "Condiciones médicas",
                    icon: "cross.case.fill",
                    iconColor: .purple,
                    items: viewModel.patient.conditions
                )
            }
            if !viewModel.patient.preferences.isEmpty {
                infoSection(
                    title: "Preferencias alimenticias",
                    icon: "fork.knife",
                    iconColor: .green,
                    items: viewModel.patient.preferences
                )
            }
        }
    }

    private func infoSection(title: String, icon: String, iconColor: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundStyle(iconColor)

            FlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(iconColor.opacity(0.1), in: Capsule())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        VStack(spacing: 8) {
            Button {
                Task { await viewModel.generateProposal() }
            } label: {
                Label("Generar Propuesta", systemImage: "wand.and.stars")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isGenerating)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 8)
    }
}

/// Simple flow layout for tag-like elements that wrap across lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        let totalWidth = min(maxWidth, positions.reduce(0) { max($0, $1.x) } + (subviews.last.map { $0.sizeThatFits(.unspecified).width } ?? 0))
        let totalHeight = currentY + lineHeight

        return (positions, CGSize(width: totalWidth, height: totalHeight))
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
