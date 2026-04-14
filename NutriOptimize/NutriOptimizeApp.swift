import SwiftUI
import SwiftData

@main
struct NutriOptimizeApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: PatientRecord.self,
                PatientFeedbackRecord.self,
                ConsultationRecord.self,
                LabResultRecord.self
            )
            DemoDataSeeder.seedIfNeeded(context: modelContainer.mainContext)
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            OptimizationDashboardView()
        }
        .modelContainer(modelContainer)
    }
}
