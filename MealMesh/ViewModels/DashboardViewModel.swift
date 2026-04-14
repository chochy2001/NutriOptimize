import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var patients: [Patient] = []
    @Published var pendingDrafts: [MealPlanDraft] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let patientService: PatientServiceProtocol
    private let mealPlanService: MealPlanServiceProtocol

    init(
        patientService: PatientServiceProtocol = MockPatientService(),
        mealPlanService: MealPlanServiceProtocol = MockMealPlanService()
    ) {
        self.patientService = patientService
        self.mealPlanService = mealPlanService
    }

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        do {
            async let patientsTask = patientService.fetchPatients()
            async let draftsTask = mealPlanService.fetchPendingDrafts()

            patients = try await patientsTask
            pendingDrafts = try await draftsTask
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Resolves the patient name for a given draft, used in the pending drafts list.
    func patientName(for draft: MealPlanDraft) -> String {
        patients.first(where: { $0.id == draft.patientId })?.name ?? "Paciente desconocido"
    }
}
