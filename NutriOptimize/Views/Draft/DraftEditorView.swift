import SwiftUI

struct DraftEditorView: View {
    @StateObject var viewModel: DraftEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showDiscardAlert = false
    @State private var showApproveAlert = false
    @State private var editingMeal: Meal?
    @State private var showAddMealSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                headerSection
                rationaleSection
                dailySummarySection
                mealsSection
                actionButtons
            }
            .padding()
        }
        .background(AppTheme.surfaceWhite.ignoresSafeArea())
        .navigationTitle("Editor de Plan")
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
                Task {
                    await viewModel.approveDraft()
                    if viewModel.wasApproved {
                        HapticManager.notification(.success)
                    }
                }
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
                    .font(AppTheme.captionFont)
                    .foregroundStyle(.secondary)
                Text(viewModel.patientName)
                    .font(AppTheme.headlineFont)
            }

            Spacer()

            statusBadge
        }
    }

    private var statusBadge: some View {
        Text(viewModel.draft.status == .approved ? "Aprobado" : "Borrador")
            .font(.system(.caption, design: .rounded, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                viewModel.draft.status == .approved
                    ? AppTheme.success.opacity(0.15)
                    : AppTheme.warmOrange.opacity(0.2),
                in: Capsule()
            )
            .foregroundStyle(viewModel.draft.status == .approved ? AppTheme.success : AppTheme.deepOrange)
    }

    // MARK: - Calculated Rationale

    private var rationaleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Análisis del motor de optimización", systemImage: "brain.head.profile")
                .font(AppTheme.subheadFont)
                .foregroundStyle(AppTheme.deepOrange)

            Text(viewModel.draft.calculatedRationale)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.lightOrange, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        }
    }

    // MARK: - Daily Summary

    private var dailySummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resumen diario")
                .font(AppTheme.subheadFont)

            HStack(spacing: 0) {
                summaryPill(label: "Calorías", value: "\(Int(viewModel.draft.totalCalories))", unit: "kcal", color: AppTheme.calorieColor)
                summaryDivider
                summaryPill(label: "Proteína", value: "\(Int(viewModel.draft.totalProtein))", unit: "g", color: AppTheme.proteinColor)
                summaryDivider
                summaryPill(label: "Carbohidratos", value: "\(Int(viewModel.draft.totalCarbs))", unit: "g", color: AppTheme.carbColor)
                summaryDivider
                summaryPill(label: "Grasa", value: "\(Int(viewModel.draft.totalFat))", unit: "g", color: AppTheme.fatColor)
            }
            .cardStyle()
        }
    }

    private var summaryDivider: some View {
        Divider().frame(height: 36)
    }

    private func summaryPill(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(color)
            Text(unit)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Meals

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Comidas (\(viewModel.draft.meals.count))")
                    .font(AppTheme.subheadFont)

                Spacer()

                Button {
                    showAddMealSheet = true
                } label: {
                    Label("Agregar", systemImage: "plus.circle.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.deepOrange)
                }
            }

            ForEach(viewModel.draft.meals) { meal in
                MealRowView(
                    meal: meal,
                    onEdit: { editingMeal = meal },
                    onDelete: {
                        HapticManager.impact(.light)
                        viewModel.deleteMeal(meal)
                    }
                )
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
            }
            .animation(.spring(response: 0.3), value: viewModel.draft.meals.count)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.danger)
                    .multilineTextAlignment(.center)
            }

            Button {
                showApproveAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Aprobar y Enviar")
                        .fontWeight(.semibold)
                }
                .font(.system(.body, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.success)
            .disabled(viewModel.draft.meals.isEmpty || viewModel.isProcessing)

            HStack(spacing: 12) {
                Button(role: .destructive) {
                    showDiscardAlert = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Descartar")
                    }
                    .font(.system(.subheadline, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.danger)

                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Regenerar")
                    }
                    .font(.system(.subheadline, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.deepOrange)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Approved Overlay

    private var approvedOverlay: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(AppTheme.success)

            Text("Plan aprobado")
                .font(AppTheme.headlineFont)

            Text("El plan alimenticio ha sido enviado exitosamente al paciente.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Volver al inicio") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.deepOrange)
            .padding(.top, 8)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThickMaterial)
        .transition(.opacity)
    }
}

extension PlanOptimizationDraft: Hashable {
    static func == (lhs: PlanOptimizationDraft, rhs: PlanOptimizationDraft) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#Preview {
    NavigationStack {
        DraftEditorView(
            viewModel: DraftEditorViewModel(
                draft: PlanOptimizationDraft(
                    id: UUID(),
                    patientId: UUID(),
                    status: .pendingReview,
                    calculatedRationale: "TDEE estimado: 1,680 kcal. Se excluyeron alimentos con gluten y mariscos. Distribución ajustada por hipotiroidismo.",
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
