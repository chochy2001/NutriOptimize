import SwiftUI
import SwiftData

@main
struct NutriOptimizeApp: App {
    let modelContainer: ModelContainer

    // Persisted user preference for the appearance picker. Values: "system",
    // "light", "dark". Default is "system" so the app follows the OS until
    // the user opts into a specific mode from Settings.
    @AppStorage(AppearancePreference.storageKey) private var schemePreference: String = AppearancePreference.system.rawValue

    init() {
        do {
            modelContainer = try ModelContainer(
                for: PatientRecord.self,
                PatientFeedbackRecord.self,
                ConsultationRecord.self,
                LabResultRecord.self,
                PlanDraftRecord.self
            )
            DemoDataSeeder.seedIfNeeded(context: modelContainer.mainContext)
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootCoordinatorView()
                .preferredColorScheme(AppearancePreference(rawValue: schemePreference)?.colorScheme)
        }
        .modelContainer(modelContainer)
    }
}
