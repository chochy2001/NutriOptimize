import Foundation

@MainActor
final class OptimizationDashboardViewModel: ObservableObject {
    @Published var patients: [Patient] = []
    @Published var pendingDrafts: [PlanOptimizationDraft] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let patientService: PatientServiceProtocol
    private let optimizationService: OptimizationServiceProtocol

    init(
        patientService: PatientServiceProtocol = MockPatientService(),
        optimizationService: OptimizationServiceProtocol = MockOptimizationService()
    ) {
        self.patientService = patientService
        self.optimizationService = optimizationService
    }

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        do {
            async let patientsTask = patientService.fetchPatients()
            async let draftsTask = optimizationService.fetchPendingDrafts()

            patients = try await patientsTask
            pendingDrafts = try await draftsTask
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func patientName(for draft: PlanOptimizationDraft) -> String {
        patients.first(where: { $0.id == draft.patientId })?.fullName ?? "Paciente"
    }
}
