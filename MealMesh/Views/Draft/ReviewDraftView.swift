import SwiftUI

struct ReviewDraftView: View {
    @StateObject var viewModel: DraftReviewViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showDiscardAlert = false
    @State private var showApproveAlert = false
    @State private var editingMeal: Meal?
    @State private var showAddMealSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                rationaleSection
                dailySummarySection
                mealsSection
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Revisión de Plan")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingMeal) { meal in
            EditMealSheet(existingMeal: meal) { updated in
                viewModel.updateMeal(updated)
            }
        }
        .sheet(isPresented: $showAddMealSheet) {
            EditMealSheet { newMeal in
                viewModel.addMeal(newMeal)
            }
        }
        .alert("Descartar borrador", isPresented: $showDiscardAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Descartar", role: .destructive) {
                Task {
                    await viewModel.discardDraft()
                    dismiss()
                }
            }
        } message: {
            Text("¿Deseas descartar este borrador? Esta acción no se puede deshacer.")
        }
        .alert("Aprobar y enviar", isPresented: $showApproveAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Aprobar") {
                Task { await viewModel.approveDraft() }
            }
        } message: {
            Text("El plan será enviado al paciente. ¿Confirmas que has revisado todas las comidas?")
        }
        .overlay {
            if viewModel.wasApproved {
                approvedOverlay
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Plan para")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(viewModel.patientName)
                    .font(.title3.bold())
            }

            Spacer()

            statusBadge
        }
    }

    private var statusBadge: some View {
        Text(viewModel.draft.status == .approved ? "Aprobado" : "Borrador")
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                viewModel.draft.status == .approved ? Color.green.opacity(0.15) : Color.orange.opacity(0.15),
                in: Capsule()
            )
            .foregroundStyle(viewModel.draft.status == .approved ? .green : .orange)
    }

    // MARK: - Rationale

    private var rationaleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Análisis del motor de recomendaciones", systemImage: "brain.head.profile")
                .font(.subheadline.bold())
                .foregroundStyle(.tint)

            Text(viewModel.draft.engineRationale)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.tint.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Daily Summary

    private var dailySummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resumen diario")
                .font(.subheadline.bold())

            HStack(spacing: 0) {
                summaryItem(
                    label: "Calorías",
                    value: "\(Int(viewModel.draft.totalCalories))",
                    unit: "kcal",
                    color: .orange
                )
                Divider().frame(height: 40)
                summaryItem(
                    label: "Proteína",
                    value: "\(Int(viewModel.draft.totalProtein))",
                    unit: "g",
                    color: .red
                )
                Divider().frame(height: 40)
                summaryItem(
                    label: "Carbohidratos",
                    value: "\(Int(viewModel.draft.totalCarbs))",
                    unit: "g",
                    color: .blue
                )
                Divider().frame(height: 40)
                summaryItem(
                    label: "Grasa",
                    value: "\(Int(viewModel.draft.totalFat))",
                    unit: "g",
                    color: .yellow
                )
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func summaryItem(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Meals

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Comidas (\(viewModel.draft.meals.count))")
                    .font(.subheadline.bold())

                Spacer()

                Button {
                    showAddMealSheet = true
                } label: {
                    Label("Agregar", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
            }

            ForEach(viewModel.draft.meals) { meal in
                MealRowView(
                    meal: meal,
                    onEdit: { editingMeal = meal },
                    onDelete: { viewModel.deleteMeal(meal) }
                )
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                showApproveAlert = true
            } label: {
                Label("Aprobar y Enviar", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(viewModel.draft.meals.isEmpty || viewModel.isProcessing)

            HStack(spacing: 12) {
                Button(role: .destructive) {
                    showDiscardAlert = true
                } label: {
                    Label("Descartar", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)

                Button {
                    // Regeneration would call the engine again — for the first iteration
                    // this navigates back so the user can trigger a new generation cycle.
                    dismiss()
                } label: {
                    Label("Regenerar", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Approved Overlay

    private var approvedOverlay: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Plan aprobado")
                .font(.title2.bold())

            Text("El plan alimenticio ha sido enviado exitosamente.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Volver al inicio") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThickMaterial)
        .transition(.opacity)
    }
}

// Hashable conformance needed for NavigationStack destination support
extension MealPlanDraft: Hashable {
    static func == (lhs: MealPlanDraft, rhs: MealPlanDraft) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#Preview {
    NavigationStack {
        ReviewDraftView(
            viewModel: DraftReviewViewModel(
                draft: MealPlanDraft(
                    id: UUID(),
                    patientId: UUID(),
                    status: .pendingReview,
                    engineRationale: "Se seleccionaron alimentos ricos en proteína para favorecer la ganancia muscular, priorizando preparaciones rápidas.",
                    meals: [
                        Meal(type: .breakfast, name: "Avena con frutos", ingredients: ["Avena", "Fresas"], macros: Macros(protein: 12, carbohydrates: 45, fat: 8)),
                        Meal(type: .lunch, name: "Pollo con quinoa", ingredients: ["Pollo", "Quinoa"], macros: Macros(protein: 38, carbohydrates: 42, fat: 14))
                    ],
                    createdAt: .now
                ),
                patientName: "María García López"
            )
        )
    }
}
