import SwiftUI
import SwiftData

@main
struct NutriOptimizeApp: App {
    var body: some Scene {
        WindowGroup {
            OptimizationDashboardView()
        }
        .modelContainer(for: [PatientRecord.self, PatientFeedbackRecord.self])
    }
}
