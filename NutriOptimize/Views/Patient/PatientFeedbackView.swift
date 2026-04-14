import SwiftUI
import SwiftData

/// Allows the nutritionist to manage per-patient food preferences and exclusions.
/// This feedback is used by the optimization engine to personalize future plans.
struct PatientFeedbackView: View {
    let patientId: UUID
    let patientName: String

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var likedFoods: [String] = []
    @State private var dislikedFoods: [String] = []
    @State private var bannedFoods: [String] = []
    @State private var generalNotes: String = ""

    @State private var newLikedFood: String = ""
    @State private var newDislikedFood: String = ""
    @State private var newBannedFood: String = ""

    @State private var hasLoaded = false

    /// Current feedback record for generating assistant insights.
    private var loadedFeedbackRecord: PatientFeedbackRecord? {
        let targetId = patientId
        let descriptor = FetchDescriptor<PatientFeedbackRecord>(
            predicate: #Predicate<PatientFeedbackRecord> { $0.patientId == targetId }
        )
        return try? modelContext.fetch(descriptor).first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                ContextualAssistantView(
                    insights: InsightGenerator.forFeedback(
                        feedback: loadedFeedbackRecord,
                        patientName: patientName
                    )
                )
                likedSection
                dislikedSection
                bannedSection
                notesSection
                saveButton
            }
            .padding()
        }
        .background(AppTheme.surfaceWhite.ignoresSafeArea())
        .navigationTitle("Preferencias")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !hasLoaded else { return }
            loadFeedback()
            hasLoaded = true
        }
    }

    // MARK: - Liked Foods

    private var likedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Alimentos preferidos", systemImage: "hand.thumbsup.fill")
                .font(AppTheme.subheadFont)
                .foregroundStyle(AppTheme.success)

            Text("El motor priorizará estos alimentos en futuras propuestas.")
                .font(AppTheme.captionFont)
                .foregroundStyle(.secondary)

            foodInputRow(text: $newLikedFood, placeholder: "Agregar alimento preferido...", color: AppTheme.success) {
                addFood(to: &likedFoods, from: &newLikedFood)
            }

            foodTagsGrid(foods: likedFoods, color: AppTheme.success) { food in
                likedFoods.removeAll { $0 == food }
                HapticManager.impact(.light)
            }
        }
        .cardStyle()
    }

    // MARK: - Disliked Foods

    private var dislikedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Alimentos a evitar", systemImage: "hand.thumbsdown.fill")
                .font(AppTheme.subheadFont)
                .foregroundStyle(AppTheme.warning)

            Text("El motor evitará estos alimentos cuando sea posible.")
                .font(AppTheme.captionFont)
                .foregroundStyle(.secondary)

            foodInputRow(text: $newDislikedFood, placeholder: "Agregar alimento a evitar...", color: AppTheme.warning) {
                addFood(to: &dislikedFoods, from: &newDislikedFood)
            }

            foodTagsGrid(foods: dislikedFoods, color: AppTheme.warning) { food in
                dislikedFoods.removeAll { $0 == food }
                HapticManager.impact(.light)
            }
        }
        .cardStyle()
    }

    // MARK: - Banned Foods

    private var bannedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Exclusiones permanentes", systemImage: "xmark.octagon.fill")
                .font(AppTheme.subheadFont)
                .foregroundStyle(AppTheme.danger)

            Text("Estos alimentos NUNCA se incluirán en las propuestas.")
                .font(AppTheme.captionFont)
                .foregroundStyle(.secondary)

            foodInputRow(text: $newBannedFood, placeholder: "Agregar exclusión permanente...", color: AppTheme.danger) {
                addFood(to: &bannedFoods, from: &newBannedFood)
            }

            foodTagsGrid(foods: bannedFoods, color: AppTheme.danger) { food in
                bannedFoods.removeAll { $0 == food }
                HapticManager.impact(.light)
            }
        }
        .cardStyle()
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Notas para el motor de optimización", systemImage: "note.text")
                .font(AppTheme.subheadFont)
                .foregroundStyle(AppTheme.deepOrange)

            Text("Información adicional que el motor debe considerar al generar propuestas.")
                .font(AppTheme.captionFont)
                .foregroundStyle(.secondary)

            TextEditor(text: $generalNotes)
                .font(.system(.body, design: .rounded))
                .frame(minHeight: 100)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .cardStyle()
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            saveFeedback()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("Guardar preferencias")
                    .fontWeight(.semibold)
            }
            .font(.system(.body, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.deepOrange)
        .controlSize(.large)
    }

    // MARK: - Reusable Components

    private func foodInputRow(text: Binding<String>, placeholder: String, color: Color, onAdd: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: text)
                .font(.system(.subheadline, design: .rounded))
                .textFieldStyle(.roundedBorder)
                .onSubmit { onAdd() }

            Button {
                onAdd()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(color)
            }
            .disabled(text.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func foodTagsGrid(foods: [String], color: Color, onRemove: @escaping (String) -> Void) -> some View {
        Group {
            if !foods.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(foods, id: \.self) { food in
                        HStack(spacing: 4) {
                            Text(food)
                                .font(AppTheme.captionFont)

                            Button {
                                onRemove(food)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(color.opacity(0.12), in: Capsule())
                        .foregroundStyle(color)
                    }
                }
            }
        }
    }

    // MARK: - Data Operations

    private func addFood(to list: inout [String], from text: inout String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !list.contains(trimmed) else { return }
        list.append(trimmed)
        text = ""
        HapticManager.impact(.light)
    }

    private func loadFeedback() {
        let targetId = patientId
        let descriptor = FetchDescriptor<PatientFeedbackRecord>(
            predicate: #Predicate<PatientFeedbackRecord> { $0.patientId == targetId }
        )
        if let record = try? modelContext.fetch(descriptor).first {
            likedFoods = record.likedFoods
            dislikedFoods = record.dislikedFoods
            bannedFoods = record.bannedFoods
            generalNotes = record.generalNotes
        }
    }

    private func saveFeedback() {
        let targetId = patientId
        let descriptor = FetchDescriptor<PatientFeedbackRecord>(
            predicate: #Predicate<PatientFeedbackRecord> { $0.patientId == targetId }
        )

        if let record = try? modelContext.fetch(descriptor).first {
            record.likedFoods = likedFoods
            record.dislikedFoods = dislikedFoods
            record.bannedFoods = bannedFoods
            record.generalNotes = generalNotes
            record.updatedAt = .now
        } else {
            let record = PatientFeedbackRecord(
                patientId: patientId,
                likedFoods: likedFoods,
                dislikedFoods: dislikedFoods,
                bannedFoods: bannedFoods,
                generalNotes: generalNotes
            )
            modelContext.insert(record)
        }

        try? modelContext.save()
        HapticManager.notification(.success)
        dismiss()
    }
}
