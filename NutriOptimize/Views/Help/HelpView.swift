import SwiftUI

/// In-app help center with step-by-step guides for every feature.
/// Designed for professionals who may not be technology-savvy.
struct HelpView: View {
    @State private var searchText = ""
    @State private var expandedSection: String?

    private var filteredSections: [HelpSection] {
        if searchText.isEmpty { return helpSections }
        return helpSections.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
            || $0.steps.joined().localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                welcomeHeader
                ForEach(filteredSections) { section in
                    helpCard(section)
                }
                faqSection
                supportFooter
            }
            .padding()
        }
        .background(AppTheme.surfaceWhite.ignoresSafeArea())
        .navigationTitle("Ayuda")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Buscar en ayuda...")
    }

    // MARK: - Welcome

    private var welcomeHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.deepOrange)

            Text("¿Cómo puedo ayudarte?")
                .font(AppTheme.headlineFont)

            Text("Encuentra guías paso a paso para cada función de NutriOptimize. Toca cualquier sección para expandirla.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Help Cards

    private func helpCard(_ section: HelpSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    HapticManager.selection()
                    expandedSection = expandedSection == section.id ? nil : section.id
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: section.icon)
                        .font(.title3)
                        .foregroundStyle(AppTheme.deepOrange)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.title)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(section.subtitle)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: expandedSection == section.id ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
            }
            .buttonStyle(.plain)

            if expandedSection == section.id {
                Divider().padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(section.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(AppTheme.deepOrange, in: Circle())

                            Text(step)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.primary)
                        }
                    }

                    if let tip = section.tip {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(AppTheme.warning)
                            Text(tip)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.warning.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.white, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    // MARK: - FAQ Section

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preguntas Frecuentes")
                .font(AppTheme.subheadFont)
                .padding(.top, 8)

            ForEach(faqs) { faq in
                VStack(alignment: .leading, spacing: 6) {
                    Text(faq.question)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    Text(faq.answer)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.02), radius: 3, x: 0, y: 1)
            }
        }
    }

    // MARK: - Footer

    private var supportFooter: some View {
        VStack(spacing: 8) {
            Text("¿Necesitas más ayuda?")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
            Text("Contacta a soporte técnico en soporte@nutrioptimize.com")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.lightOrange, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}

// MARK: - Help Data

private struct HelpSection: Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let steps: [String]
    let tip: String?
}

private struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

private let helpSections: [HelpSection] = [
    HelpSection(
        id: "patients",
        icon: "person.crop.circle.badge.plus",
        title: "Gestión de Pacientes",
        subtitle: "Cómo agregar, editar y eliminar pacientes",
        steps: [
            "En el panel principal, toca el botón '+' en la esquina superior derecha.",
            "Completa los datos del paciente: nombre, edad, peso, altura y objetivo clínico.",
            "Las alergias y condiciones médicas se separan con comas (ej: Gluten, Mariscos).",
            "Toca 'Guardar' para registrar al paciente.",
            "Para editar, entra al perfil del paciente y toca el ícono de lápiz arriba a la derecha.",
            "Para eliminar, desliza el nombre del paciente hacia la izquierda en el panel principal."
        ],
        tip: "Puedes usar las 'Plantillas rápidas' al crear un paciente nuevo para pre-llenar datos comunes como pérdida de peso o control de diabetes."
    ),
    HelpSection(
        id: "generate",
        icon: "wand.and.stars",
        title: "Generar un Plan Alimenticio",
        subtitle: "Cómo crear propuestas optimizadas para tus pacientes",
        steps: [
            "Abre el perfil de un paciente desde el panel principal.",
            "Verifica que los datos del paciente estén completos (peso, alergias, condiciones).",
            "Toca el botón naranja 'Generar Propuesta Optimizada' al final de la pantalla.",
            "Espera mientras el motor analiza el perfil y calcula la distribución de macros.",
            "El sistema te mostrará un borrador con las comidas sugeridas y el razonamiento clínico.",
            "Revisa, edita lo que necesites y aprueba cuando estés satisfecho."
        ],
        tip: "El motor considera las alergias, condiciones médicas, presupuesto y preferencias del paciente al generar la propuesta."
    ),
    HelpSection(
        id: "edit-plan",
        icon: "pencil.and.list.clipboard",
        title: "Editar un Plan (Borrador)",
        subtitle: "Cómo modificar las comidas sugeridas antes de aprobar",
        steps: [
            "En el editor de plan, verás las comidas organizadas por tipo (Desayuno, Comida, Cena, Snack).",
            "Toca el ícono de lápiz naranja en cualquier comida para editar sus ingredientes, macros o porciones.",
            "Toca el ícono de basura rojo para eliminar una comida.",
            "Usa el botón 'Agregar' para añadir una comida nueva (puedes usar plantillas predefinidas).",
            "Los íconos de pulgar arriba/abajo permiten marcar comidas como 'me gusta' o 'no me gusta' para futuras propuestas.",
            "Cuando estés satisfecho, toca 'Aprobar y Enviar' para finalizar el plan."
        ],
        tip: "El rationale al inicio del editor explica POR QUÉ el motor eligió esas comidas. Léelo para entender la lógica clínica."
    ),
    HelpSection(
        id: "pdf",
        icon: "doc.richtext",
        title: "Exportar y Compartir PDF",
        subtitle: "Cómo enviar el plan al paciente por WhatsApp o email",
        steps: [
            "Dentro del editor de plan, toca el ícono de compartir (cuadrado con flecha) en la barra superior.",
            "Se generará un PDF profesional con el logotipo de NutriOptimize.",
            "En la hoja de compartir, selecciona WhatsApp, Mail, AirDrop o guarda en Archivos.",
            "El PDF incluye: datos del paciente, resumen de macros, lista de comidas y el razonamiento clínico."
        ],
        tip: "El PDF se genera con formato US Letter. Incluye un disclaimer profesional al pie de página."
    ),
    HelpSection(
        id: "history",
        icon: "chart.line.uptrend.xyaxis",
        title: "Historial y Gráficas de Progreso",
        subtitle: "Cómo ver la evolución del paciente a lo largo del tiempo",
        steps: [
            "Entra al perfil de un paciente y toca 'Historial' en las herramientas clínicas.",
            "Verás gráficas de evolución de peso, composición corporal y macros prescritos.",
            "Desplázate hacia abajo para ver la línea de tiempo con cada consulta.",
            "Toca las notas clínicas para expandir los detalles de cada visita.",
            "Las gráficas se actualizan automáticamente cada vez que apruebas un nuevo plan."
        ],
        tip: nil
    ),
    HelpSection(
        id: "labs",
        icon: "cross.vial",
        title: "Estudios de Laboratorio",
        subtitle: "Cómo registrar e interpretar resultados de análisis clínicos",
        steps: [
            "Entra al perfil del paciente y toca 'Laboratorios' en las herramientas clínicas.",
            "Toca '+' para agregar un resultado nuevo.",
            "Selecciona el tipo de estudio (Glucosa, Colesterol, TSH, etc.) de las plantillas disponibles.",
            "Ingresa el valor y el rango de referencia.",
            "Los resultados fuera de rango se marcan automáticamente en rojo.",
            "Las flechas de tendencia (↑↓) comparan con el resultado anterior del mismo estudio."
        ],
        tip: "También puedes importar resultados desde un archivo PDF o JSON usando el botón 'Importar'."
    ),
    HelpSection(
        id: "photos",
        icon: "camera.viewfinder",
        title: "Fotos de Progreso",
        subtitle: "Cómo documentar visualmente el avance del paciente",
        steps: [
            "Entra al perfil del paciente y toca 'Fotos' en las herramientas clínicas.",
            "Toca 'Tomar foto' para usar la cámara o 'Galería' para elegir una foto existente.",
            "Las fotos se guardan localmente en el dispositivo.",
            "Toca cualquier foto para verla en pantalla completa.",
            "Las fotos se ordenan por fecha para facilitar la comparación visual."
        ],
        tip: nil
    ),
    HelpSection(
        id: "feedback",
        icon: "slider.horizontal.3",
        title: "Preferencias y Feedback del Paciente",
        subtitle: "Cómo personalizar las sugerencias del motor para cada paciente",
        steps: [
            "Entra al perfil del paciente y toca 'Feedback' en las herramientas clínicas.",
            "En 'Alimentos preferidos', agrega comidas que al paciente le gustan y funcionan bien.",
            "En 'Alimentos a evitar', agrega comidas que el paciente no tolera o no disfruta.",
            "En 'Exclusiones permanentes', agrega alimentos que NUNCA deben sugerirse para este paciente.",
            "Usa el campo de notas para indicar patrones de prescripción específicos.",
            "El motor usará esta información en cada nueva propuesta que genere."
        ],
        tip: "También puedes marcar comidas como 'me gusta' o 'no me gusta' directamente desde el editor de plan."
    ),
    HelpSection(
        id: "settings",
        icon: "gearshape",
        title: "Configuración del Motor",
        subtitle: "Cómo conectar y personalizar el motor de optimización",
        steps: [
            "Toca el ícono de engranaje en la esquina superior izquierda del panel principal.",
            "Ingresa tu API Key de OpenRouter (obtén una en openrouter.ai/keys).",
            "Toca 'Verificar conexión' para confirmar que la clave funciona.",
            "En 'Prompt personalizado', describe tu estilo de prescripción habitual.",
            "Activa 'Mostrar procesamiento' si deseas ver exactamente qué envía y recibe el motor.",
            "Sin API Key, la app funciona con datos de demostración para explorar la interfaz."
        ],
        tip: "El prompt personalizado le dice al motor cómo prescribes normalmente. Por ejemplo: 'Prefiero dietas mediterráneas con 5 comidas al día'."
    )
]

private let faqs: [FAQ] = [
    FAQ(
        question: "¿Puedo usar la app sin conexión a internet?",
        answer: "Sí. Los datos de pacientes, historial, fotos y laboratorios se guardan localmente. Solo necesitas internet para generar propuestas con el motor de optimización. Sin conexión, la app funciona con datos de demostración."
    ),
    FAQ(
        question: "¿El motor reemplaza mi criterio profesional?",
        answer: "No. NutriOptimize sigue la filosofía Human-Centered AI: el motor PROPONE planes basados en datos clínicos, pero TÚ decides. Siempre puedes editar, agregar o eliminar cualquier sugerencia antes de aprobar."
    ),
    FAQ(
        question: "¿Mis datos están seguros?",
        answer: "Los datos se almacenan localmente en tu dispositivo usando SwiftData (la tecnología de Apple). No se envían a servidores externos excepto cuando generas una propuesta, donde solo se envían datos clínicos necesarios al motor."
    ),
    FAQ(
        question: "¿Cómo personalizo las sugerencias para un paciente específico?",
        answer: "Usa la sección 'Feedback' del paciente para indicar preferencias, exclusiones y alimentos prohibidos. También puedes marcar comidas como 'me gusta' o 'no me gusta' directamente en el editor de plan."
    ),
    FAQ(
        question: "¿Qué fórmulas clínicas usa el motor?",
        answer: "El motor calcula el TMB con la ecuación de Mifflin-St Jeor, el TDEE según el nivel de actividad (PAL), y el IMC estándar. Estos valores se muestran en el perfil del paciente."
    ),
    FAQ(
        question: "¿Puedo enviar el plan por WhatsApp?",
        answer: "Sí. Al aprobar un plan, toca el ícono de compartir para generar un PDF profesional. Desde la hoja de compartir, selecciona WhatsApp, Mail o cualquier otra app."
    )
]

#Preview {
    NavigationStack {
        HelpView()
    }
}
