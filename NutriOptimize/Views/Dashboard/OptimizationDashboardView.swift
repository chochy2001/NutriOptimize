import SwiftUI

struct OptimizationDashboardView: View {
    @StateObject private var viewModel = OptimizationDashboardViewModel()
    @State private var searchText = ""

    private var filteredPatients: [Patient] {
        if searchText.isEmpty { return viewModel.patients }
        return viewModel.patients.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingState
                } else if let error = viewModel.errorMessage {
                    errorState(error)
                } else {
                    mainContent
                }
            }
            .background(AppTheme.surfaceWhite.ignoresSafeArea())
            .navigationTitle("NutriOptimize")
            .searchable(text: $searchText, prompt: "Buscar paciente")
            .refreshable {
                await viewModel.loadDashboard()
            }
            .task {
                await viewModel.loadDashboard()
            }
        }
        .tint(AppTheme.deepOrange)
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AppTheme.deepOrange)
                .scaleEffect(1.2)
            Text("Cargando panel...")
                .font(AppTheme.subheadFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        ContentUnavailableView(
            "Error al cargar",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                if !viewModel.pendingDrafts.isEmpty {
                    pendingDraftsSection
                }
                patientsSection
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .navigationDestination(for: PlanOptimizationDraft.self) { draft in
            DraftEditorView(
                viewModel: DraftEditorViewModel(
                    draft: draft,
                    patientName: viewModel.patientName(for: draft)
                )
            )
        }
        .navigationDestination(for: Patient.self) { patient in
            PatientDetailView(viewModel: PatientDetailViewModel(patient: patient))
        }
    }

    // MARK: - Pending Drafts Section

    private var pendingDraftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundStyle(AppTheme.deepOrange)
                Text("Pendientes de revisión")
                    .font(AppTheme.subheadFont)

                Spacer()

                Text("\(viewModel.pendingDrafts.count)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.deepOrange, in: Capsule())
            }

            ForEach(viewModel.pendingDrafts) { draft in
                NavigationLink(value: draft) {
                    pendingDraftRow(draft)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded { HapticManager.selection() })
            }
        }
    }

    private func pendingDraftRow(_ draft: PlanOptimizationDraft) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.lightOrange)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundStyle(AppTheme.deepOrange)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.patientName(for: draft))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                HStack(spacing: 8) {
                    Label("\(draft.meals.count) comidas", systemImage: "fork.knife")
                    Text("·")
                    Text("\(Int(draft.totalCalories)) kcal")
                }
                .font(AppTheme.captionFont)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
                Text(draft.createdAt, style: .relative)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
        }
        .cardStyle()
    }

    // MARK: - Patients Section

    private var patientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(AppTheme.deepOrange)
                Text("Pacientes")
                    .font(AppTheme.subheadFont)

                Spacer()

                Text("\(filteredPatients.count)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            ForEach(filteredPatients) { patient in
                NavigationLink(value: patient) {
                    patientRow(patient)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded { HapticManager.selection() })
            }
        }
    }

    private func patientRow(_ patient: Patient) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.warmOrange, AppTheme.deepOrange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay {
                    Text(patient.fullName.prefix(1))
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(patient.fullName)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Text(patient.clinicalGoals)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .cardStyle()
    }
}

#Preview {
    OptimizationDashboardView()
}
