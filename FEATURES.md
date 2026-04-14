# NutriOptimize — Documentación de Funcionalidades

Referencia técnica completa de todas las funcionalidades implementadas, en progreso y planificadas.

---

## Funcionalidades Implementadas

### 1. CRUD Completo de Pacientes

**Estado:** ✅ Implementado

**Descripción:** Gestión completa del ciclo de vida de registros de pacientes con persistencia local. El nutriólogo puede crear, consultar, editar y eliminar pacientes con datos clínicos completos.

**Datos clínicos capturados:**
- Nombre completo
- Edad y sexo biológico
- Peso (kg) y altura (cm)
- Porcentaje de grasa corporal (opcional)
- Alergias alimentarias
- Condiciones médicas
- Preferencias dietéticas
- Objetivo clínico
- Tiempo disponible para cocinar (minutos)
- Nivel de actividad física (Sedentario, Actividad ligera, Moderada, Muy activo, Atleta)
- Presupuesto alimentario mensual en MXN (opcional)

**Detalles técnicos:**
- Persistencia con SwiftData a través de `PatientRecord` (@Model)
- Conversión bidireccional entre `PatientRecord` (persistencia) y `Patient` (valor ligero para vistas)
- Operaciones CRUD centralizadas en `PatientStore` (@MainActor)
- Seed automático con datos de demostración en el primer lanzamiento
- Eliminación por swipe y menú contextual

**Archivos:**
- `Models/Patient.swift` — Struct del dominio con cálculos antropométricos
- `Services/PatientStore.swift` — PatientRecord (@Model) + PatientStore (CRUD)
- `Views/Patient/AddEditPatientView.swift` — Formulario de creación/edición
- `ViewModels/OptimizationDashboardViewModel.swift` — Operaciones CRUD desde el dashboard

---

### 2. Motor de Optimización Inteligente

**Estado:** ✅ Implementado

**Descripción:** Motor que analiza el perfil clínico completo del paciente y genera un plan alimenticio diario personalizado con desglose de macronutrientes y razonamiento clínico.

**Datos considerados por el motor:**
- Perfil antropométrico completo (peso, altura, IMC, grasa corporal)
- TMB calculada con Mifflin-St Jeor y TDEE con factor PAL
- Alergias (ingredientes excluidos)
- Condiciones médicas
- Preferencias dietéticas
- Objetivo clínico
- Tiempo disponible de cocina
- Presupuesto alimentario (prioriza ingredientes costo-efectivos)
- Prompt personalizado del nutriólogo

**Detalles técnicos:**
- Implementación de producción: `OpenRouterService` que consume la API de OpenRouter
- Modelo: Gemini 2.5 Flash con `response_format: json_object`
- Temperatura: 0.4 (determinista pero con variación)
- Timeout: 60 segundos
- Protocolo `OptimizationEngineProtocol` para desacoplamiento
- Fallback automático a `MockOptimizationService` cuando no hay API key configurada
- Respuesta parseada a `PlanOptimizationDraft` con estado `pendingReview`

**Archivos:**
- `Services/OpenRouterService.swift` — Implementación de producción
- `Services/Protocols/OptimizationServiceProtocol.swift` — Contrato del servicio
- `Services/Mock/MockOptimizationService.swift` — Implementación mock para desarrollo
- `ViewModels/PatientDetailViewModel.swift` — Orquestación de la generación

---

### 3. Personalización del Prompt de Optimización

**Estado:** ✅ Implementado

**Descripción:** El nutriólogo puede personalizar el comportamiento del motor escribiendo indicaciones que reflejan su estilo de prescripción. Estas indicaciones se incluyen como "notas del nutriólogo" en cada solicitud al motor.

**Ejemplo de uso:** "Priorizo dietas mediterráneas, evito suplementos artificiales, prefiero 5 comidas al día."

**Detalles técnicos:**
- Almacenado en `UserDefaults` con clave `custom_optimization_prompt`
- Se inyecta en la sección `NUTRITIONIST PRESCRIBING NOTES` del prompt
- Campo de texto multilínea (4-10 líneas) en la vista de configuración

**Archivos:**
- `Services/OpenRouterService.swift` — Lectura y aplicación del prompt personalizado
- `Views/Settings/SettingsView.swift` — Interfaz de edición del prompt

---

### 4. Editor de Borradores con Edición Granular

**Estado:** ✅ Implementado

**Descripción:** Interfaz completa de edición de planes alimenticios generados por el motor. El nutriólogo tiene control total sobre cada comida antes de aprobar el plan.

**Capacidades de edición:**
- Modificar nombre de la comida
- Editar lista de ingredientes
- Ajustar macronutrientes individuales (proteína, carbohidratos, grasa)
- Cambiar descripción de porciones
- Cambiar tipo de comida (Desayuno, Comida, Cena, Snack)
- Eliminar comidas existentes
- Agregar nuevas comidas
- Ver totales agregados actualizados en tiempo real

**Ciclo de vida del borrador:**
- `pendingReview` → `approved` (aprobado por el nutriólogo)
- `pendingReview` → `discarded` (descartado)

**Detalles técnicos:**
- `DraftEditorViewModel` gestiona mutaciones sobre `PlanOptimizationDraft`
- `EditMealSheet` presenta formulario de edición individual por comida
- Totales de macros recalculados automáticamente en el modelo
- Adherencia calórica comparada contra TDEE del paciente

**Archivos:**
- `ViewModels/DraftEditorViewModel.swift` — Lógica de edición, aprobación y descarte
- `Views/Draft/DraftEditorView.swift` — Vista principal del editor
- `Views/Components/EditMealSheet.swift` — Sheet de edición de comida individual
- `Views/Components/MealRowView.swift` — Fila de comida con macros
- `Views/Components/MacrosBadgeView.swift` — Badge visual de macronutrientes

---

### 5. Exportación a PDF Profesional

**Estado:** ✅ Implementado

**Descripción:** Genera un documento PDF con formato profesional que incluye branding de NutriOptimize, datos del paciente, resumen nutricional diario, detalle de cada comida con macros e ingredientes, y el análisis del motor. Listo para compartir por WhatsApp u otros medios.

**Contenido del PDF:**
- Header con logo textual "NutriOptimize" y fecha
- Datos del paciente (nombre, edad, sexo, peso, altura, IMC, actividad, objetivo clínico, alergias, condiciones)
- Resumen diario (calorías, proteína, carbohidratos, grasa, % TDEE)
- Detalle de cada comida ordenada por tipo (Desayuno, Snack, Comida, Cena)
- Macros por comida (P/C/G en gramos y kcal)
- Ingredientes y porciones
- Análisis del motor de optimización (rationale clínico)
- Footer con disclaimer profesional
- Paginación automática

**Detalles técnicos:**
- `UIGraphicsPDFRenderer` para composición nativa de PDF
- Formato US Letter (612 x 792 pt)
- Colores de marca: naranja (#E66B24), texto oscuro, texto secundario
- Tipografía del sistema en múltiples pesos
- Salto de página automático cuando el contenido excede el espacio disponible
- Texto con word-wrap para ingredientes y rationale largos

**Archivos:**
- `Services/PDFExportService.swift` — Generador completo de PDF
- `ViewModels/DraftEditorViewModel.swift` — Método `exportPDF(patient:)`

---

### 6. Panel de Control (Dashboard)

**Estado:** ✅ Implementado

**Descripción:** Vista principal de la aplicación que muestra un resumen del estado actual: pacientes registrados y borradores de planes pendientes de revisión.

**Funcionalidades del dashboard:**
- Lista de pacientes con avatar, nombre y objetivo clínico
- Sección de borradores pendientes con conteo, nombre del paciente, número de comidas y calorías totales
- Navegación a detalle de paciente (tap)
- Navegación a editor de borrador (tap en pendiente)
- Agregar nuevo paciente (botón +)
- Editar paciente (swipe izquierdo o menú contextual)
- Eliminar paciente (swipe derecho o menú contextual)
- Pull-to-refresh para recargar datos
- Acceso a configuración (icono de engranaje)

**Archivos:**
- `Views/Dashboard/OptimizationDashboardView.swift` — Vista del dashboard
- `ViewModels/OptimizationDashboardViewModel.swift` — Estado y lógica del dashboard

---

### 7. Cálculos Clínicos Antropométricos

**Estado:** ✅ Implementado

**Descripción:** Cálculos automatizados basados en los datos del paciente para fundamentar la generación de planes.

**Cálculos implementados:**
- **IMC (Índice de Masa Corporal):** `peso / (altura_m)²` con clasificación (Bajo peso, Normal, Sobrepeso, Obesidad)
- **TMB (Tasa Metabólica Basal):** Ecuación de Mifflin-St Jeor
  - Hombres: `(10 × peso) + (6.25 × altura) - (5 × edad) + 5`
  - Mujeres: `(10 × peso) + (6.25 × altura) - (5 × edad) - 161`
- **TDEE (Gasto Energético Diario Total):** `TMB × Factor PAL`
  - Sedentario: 1.2
  - Actividad ligera: 1.375
  - Actividad moderada: 1.55
  - Muy activo: 1.725
  - Atleta: 1.9
- **Calorías de macronutrientes:** Proteína × 4, Carbohidratos × 4, Grasa × 9
- **Porcentajes de macros:** Distribución porcentual respecto al total calórico
- **Adherencia calórica:** Porcentaje de calorías del plan vs TDEE del paciente
- **Presupuesto semanal:** Derivado del mensual (÷ 4)

**Archivos:**
- `Models/Patient.swift` — IMC, TMB, TDEE, clasificación
- `Models/Meal.swift` — Macros (calorías totales, porcentajes)
- `Models/PlanOptimizationDraft.swift` — Agregados y adherencia calórica

---

### 8. Búsqueda y Filtrado de Pacientes

**Estado:** ✅ Implementado

**Descripción:** Barra de búsqueda nativa de SwiftUI integrada en el dashboard para filtrar pacientes por nombre.

**Detalles técnicos:**
- Modificador `.searchable` con prompt "Buscar paciente"
- Filtrado por `localizedCaseInsensitiveContains` en `fullName`
- Actualización instantánea de la lista

**Archivos:**
- `Views/Dashboard/OptimizationDashboardView.swift` — Implementación de la búsqueda

---

### 9. Vista de Depuración del Motor

**Estado:** ✅ Implementado

**Descripción:** Vista de solo lectura que muestra el prompt exacto enviado al motor de optimización y la respuesta cruda recibida. Permite al nutriólogo verificar los datos de entrada y el razonamiento del sistema.

**Funcionalidades:**
- Visualización del prompt completo con formato monoespaciado
- Visualización de la respuesta JSON cruda del motor
- Botón de copiar al portapapeles para cada sección
- Selección de texto habilitada
- Toggle para activar/desactivar desde configuración

**Detalles técnicos:**
- `EngineDebugStore` (singleton ObservableObject) almacena el último intercambio
- Se actualiza automáticamente después de cada generación exitosa
- Preferencia almacenada en UserDefaults (`show_engine_debug`)

**Archivos:**
- `Views/Draft/EngineDebugView.swift` — Vista de depuración
- `Services/OpenRouterService.swift` — Almacenamiento en `EngineDebugStore`

---

### 10. Retroalimentación Háptica

**Estado:** ✅ Implementado

**Descripción:** Sistema centralizado de retroalimentación táctil que proporciona feedback físico en interacciones clave.

**Tipos de feedback:**
- `impact` — Tap en elementos interactivos (ligero, medio, pesado)
- `notification` — Confirmación de guardado exitoso, errores
- `selection` — Selección de pacientes y borradores en listas

**Archivos:**
- `Theme/HapticManager.swift` — Utilidad centralizada
- Usado en: `OptimizationDashboardView`, `SettingsView`, `EngineDebugView`

---

### 11. Sistema de Diseño Centralizado

**Estado:** ✅ Implementado

**Descripción:** Tokens de diseño centralizados que garantizan consistencia visual en toda la aplicación.

**Tokens definidos:**
- Colores de marca: naranja profundo (#E66B24), naranja cálido, naranja claro, blanco superficie
- Colores semánticos: éxito, advertencia, peligro, información
- Colores de macronutrientes: calorías (naranja), proteína (rojo), carbohidratos (azul), grasa (amarillo)
- Tipografía: headline (rounded bold), subhead (rounded semibold), caption (rounded)
- Layout: corner radius (14pt), card padding (16pt), section spacing (20pt)
- Modificador reutilizable: `.cardStyle()` con sombra sutil

**Archivos:**
- `Theme/AppTheme.swift` — Definición de tokens y modificadores

---

### 12. Configuración del Motor

**Estado:** ✅ Implementado

**Descripción:** Pantalla de configuración donde el nutriólogo gestiona la conexión al motor de optimización y personaliza su comportamiento.

**Secciones:**
- API Key (campo seguro para la clave de OpenRouter)
- Prompt de optimización personalizado
- Toggle de vista de depuración del motor
- Información del motor (modelo, proveedor, estado de conexión)
- Confirmación visual animada al guardar

**Archivos:**
- `Views/Settings/SettingsView.swift` — Vista de configuración completa

---

### 13. Vista de Estado de Procesamiento

**Estado:** ✅ Implementado

**Descripción:** Interfaz animada que muestra el progreso de la generación del plan mientras el motor procesa la solicitud.

**Detalles técnicos:**
- Barra de progreso con simulación de pasos (15%, 35%, 55%, 75%, 90%, 100%)
- Progreso simulado ejecutado en paralelo con la llamada real al motor
- Transición fluida al editor de borrador al completar

**Archivos:**
- `Views/Draft/ProcessingStateView.swift` — Vista de procesamiento
- `ViewModels/PatientDetailViewModel.swift` — Lógica de progreso

---

### 14. Consideración de Presupuesto Alimentario

**Estado:** ✅ Implementado

**Descripción:** El paciente puede tener un presupuesto mensual alimentario en MXN. Cuando está definido, el motor recibe instrucciones de priorizar ingredientes costo-efectivos.

**Detalles técnicos:**
- Campo opcional `monthlyFoodBudget` en `Patient`
- Cálculo automático de presupuesto semanal (÷ 4)
- Inyectado como `BUDGET CONSTRAINT` en el prompt del motor
- Expresado en MXN (pesos mexicanos)

**Archivos:**
- `Models/Patient.swift` — Campo y cálculo de presupuesto semanal
- `Services/OpenRouterService.swift` — Inclusión en el prompt

---

## Funcionalidades Planificadas

### 15. Historial de Consultas y Progreso con Gráficas
**Estado:** 📋 Planificado (Fase 2)

Registro longitudinal de cada consulta del paciente con visualización de tendencias de peso, IMC y adherencia calórica a lo largo del tiempo.

---

### 16. Fotos de Progreso del Paciente
**Estado:** 📋 Planificado (Fase 2)

Captura fotográfica desde la cámara del dispositivo para documentar visualmente el progreso del paciente entre consultas.

---

### 17. Integración de Estudios de Laboratorio
**Estado:** 📋 Planificado (Fase 2)

Registro de resultados de laboratorio (perfil lipídico, glucosa, hemoglobina, etc.) para que el motor los considere en la generación de planes.

---

### 18. Agenda y Citas
**Estado:** 📋 Planificado (Fase 3)

Calendario integrado para gestionar citas con pacientes, recordatorios y seguimiento de asistencia.

---

### 19. Asistente Contextual por Sección
**Estado:** 📋 Planificado (Fase 3)

Motor de asistencia integrado en cada sección de la app que responde preguntas contextuales del nutriólogo sobre el paciente actual, los datos clínicos o el plan en edición.

---

### 20. Personalización del Motor por Paciente
**Estado:** 📋 Planificado (Fase 3)

Configuración de prompts y parámetros del motor a nivel de paciente individual, permitiendo ajustes más finos que el prompt global.

---

### 21. Sincronización con Backend Remoto
**Estado:** 📋 Planificado (Fase 4)

Backend en la nube para sincronizar datos entre dispositivos, respaldos automáticos y soporte multi-nutriólogo en una misma clínica.

---

### 22. Cumplimiento NOM-051 y COFEPRIS
**Estado:** 📋 Planificado (Fase 4)

Validación de planes alimenticios contra la normativa mexicana de etiquetado (NOM-051) y lineamientos de COFEPRIS para recomendaciones nutricionales profesionales.
