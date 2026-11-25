import SwiftUI
import SwiftData

struct OptimizationDashboardView: View {
    private enum DashboardRoute: Hashable {
        case draft(PlanOptimizationDraft)
        case patient(Patient)
    }

    private enum DashboardSheet: Identifiable {
        case addPatient
        case editPatient(Patient)
        case settings
        case help

        var id: String {
            switch self {
            case .addPatient:
                return "addPatient"
            case .editPatient(let patient):
                return "editPatient-\(patient.id.uuidString)"
            case .settings:
                return "settings"
            case .help:
                return "help"
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = OptimizationDashboardViewModel()
    @StateObject private var navigationGuard = TapActionGuard()
    @State private var searchText = ""
    @State private var navigationPath: [DashboardRoute] = []
    @State private var activeSheet: DashboardSheet?
    @State private var patientToDelete: Patient?

    private var filteredPatients: [Patient] {
        if searchText.isEmpty { return viewModel.patients }
        return viewModel.patients.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { patientToDelete != nil },
            set: { if !$0 { patientToDelete = nil } }
        )
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
            .searchable(text: $searchText, prompt: L10n.dashboardSearchPrompt)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        GuardedButton {
                            presentSheet(.settings)
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        GuardedButton {
                            presentSheet(.help)
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    GuardedButton {
                        presentSheet(.addPatient)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.loadDashboard()
            }
            .task {
                viewModel.configure(modelContext: modelContext)
                await viewModel.loadDashboard()
            }
            .onAppear {
                // Refresh when navigating back from a draft editor so pending
                // drafts reflect any saves / approvals / discards made there.
                viewModel.configure(modelContext: modelContext)
                viewModel.refreshPendingDrafts()
            }
            .onChange(of: navigationPath.count) { oldCount, newCount in
                if newCount < oldCount {
                    navigationGuard.reset()
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addPatient:
                    AddEditPatientView { newPatient in
                        viewModel.addPatient(newPatient)
                    }
                case .editPatient(let patient):
                    AddEditPatientView(patient: patient) { updated in
                        viewModel.updatePatient(updated)
                    }
                case .settings:
                    SettingsView()
                case .help:
                    NavigationStack {
                        HelpView()
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button(L10n.actionClose) { activeSheet = nil }
                                }
                            }
                    }
                }
            }
            .alert(L10n.deletePatientTitle, isPresented: deleteAlertBinding, presenting: patientToDelete) { patient in
                Button(L10n.actionDelete, role: .destructive) {
                    HapticManager.impact(.medium)
                    viewModel.deletePatient(patient)
                    patientToDelete = nil
                }
                Button(L10n.consentCancel, role: .cancel) {
                    patientToDelete = nil
                }
            } message: { patient in
                Text(L10n.deletePatientMessage(patient.fullName))
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
            Text(L10n.dashboardLoading)
                .font(AppTheme.subheadFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        ContentUnavailableView(
            L10n.dashboardLoadError,
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
        .navigationDestination(for: DashboardRoute.self) { route in
            switch route {
            case .draft(let draft):
                let matchedPatient = viewModel.patients.first(where: { $0.id == draft.patientId })
                DraftEditorView(
                    viewModel: DraftEditorViewModel(
                        draft: draft,
                        patientName: viewModel.patientName(for: draft)
                    ),
                    patient: matchedPatient
                )
            case .patient(let patient):
                PatientDetailView(viewModel: PatientDetailViewModel(patient: patient))
            }
        }
    }

    private func pushRoute(_ route: DashboardRoute) {
        guard navigationPath.last != route else { return }
        guard activeSheet == nil, patientToDelete == nil else { return }
        guard navigationGuard.shouldAllowTap() else { return }
        HapticManager.selection()
        navigationPath.append(route)
    }

    private func presentSheet(_ sheet: DashboardSheet) {
        guard activeSheet == nil, patientToDelete == nil else { return }
        activeSheet = sheet
    }

    // MARK: - Pending Drafts Section

    private var pendingDraftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundStyle(AppTheme.deepOrange)
                Text(L10n.dashboardPendingReview)
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
                GuardedButton {
                    pushRoute(.draft(draft))
                } label: {
                    pendingDraftRow(draft)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
                    Label(L10n.dashboardMealsCount(draft.meals.count), systemImage: "fork.knife")
                    Text("\u{00B7}")
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
                Text(L10n.dashboardPatients)
                    .font(AppTheme.subheadFont)

                Spacer()

                Text("\(filteredPatients.count)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            ForEach(filteredPatients) { patient in
                GuardedButton {
                    pushRoute(.patient(patient))
                } label: {
                    patientRow(patient)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        presentSheet(.editPatient(patient))
                    } label: {
                        Label(L10n.actionEdit, systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        guard activeSheet == nil, patientToDelete == nil else { return }
                        patientToDelete = patient
                    } label: {
                        Label(L10n.actionDelete, systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        guard activeSheet == nil, patientToDelete == nil else { return }
                        patientToDelete = patient
                    } label: {
                        Label(L10n.actionDelete, systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        presentSheet(.editPatient(patient))
                    } label: {
                        Label(L10n.actionEdit, systemImage: "pencil")
                    }
                    .tint(AppTheme.deepOrange)
                }
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
        .modelContainer(for: PatientRecord.self, inMemory: true)
}
