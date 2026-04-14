import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var searchText = ""

    private var filteredPatients: [Patient] {
        if searchText.isEmpty { return viewModel.patients }
        return viewModel.patients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Cargando datos...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Error al cargar",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    mainContent
                }
            }
            .navigationTitle("Meal Mesh")
            .searchable(text: $searchText, prompt: "Buscar paciente")
            .refreshable {
                await viewModel.loadDashboard()
            }
            .task {
                await viewModel.loadDashboard()
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        List {
            if !viewModel.pendingDrafts.isEmpty {
                pendingDraftsSection
            }
            patientsSection
        }
        .listStyle(.insetGrouped)
    }

    private var pendingDraftsSection: some View {
        Section {
            ForEach(viewModel.pendingDrafts) { draft in
                NavigationLink(value: draft) {
                    pendingDraftRow(draft)
                }
            }
        } header: {
            Label("Planes pendientes de revisión", systemImage: "clock.badge.exclamationmark")
                .font(.headline)
                .foregroundStyle(.orange)
        }
        .navigationDestination(for: MealPlanDraft.self) { draft in
            ReviewDraftView(
                viewModel: DraftReviewViewModel(
                    draft: draft,
                    patientName: viewModel.patientName(for: draft)
                )
            )
        }
    }

    private var patientsSection: some View {
        Section {
            ForEach(filteredPatients) { patient in
                NavigationLink(value: patient) {
                    patientRow(patient)
                }
            }
        } header: {
            Label("Pacientes (\(filteredPatients.count))", systemImage: "person.2.fill")
                .font(.headline)
        }
        .navigationDestination(for: Patient.self) { patient in
            PatientDetailView(viewModel: PatientDetailViewModel(patient: patient))
        }
    }

    // MARK: - Row Views

    private func pendingDraftRow(_ draft: MealPlanDraft) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.patientName(for: draft))
                    .font(.subheadline.bold())
                Text("\(draft.meals.count) comidas · \(Int(draft.totalCalories)) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(draft.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private func patientRow(_ patient: Patient) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.tint.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(patient.name.prefix(1))
                        .font(.headline.bold())
                        .foregroundStyle(.tint)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(patient.name)
                    .font(.subheadline.bold())
                Text(patient.goals)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DashboardView()
}
