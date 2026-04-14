# NutriOptimize — Guía de Presentación para Hackathon

> Formato optimizado para copiar/pegar en Gamma. Cada sección separada por `---` corresponde a una diapositiva.

---

## Diapositiva 1: Título

**NutriOptimize**

Optimización nutricional inteligente centrada en el profesional

**Equipo:**
- Jorge Salgado Miranda
- Michelle Paola González Martínez
- Arroyo Ramírez Carlos Alberto

Color de marca: `#F27822`

---

## Diapositiva 2: El Problema

**Los nutriólogos pierden tiempo en tareas que no son clínicas**

- Los nutriólogos pasan **60%+ de su tiempo** en tareas administrativas en lugar de atender pacientes
- Crear un plan alimenticio personalizado toma **30-45 minutos** por paciente
- Las herramientas actuales no están diseñadas para el **flujo clínico mexicano**: alimentos locales, presupuestos en pesos, nomenclatura en español
- No existe integración entre el historial del paciente, los cálculos antropométricos y la generación del plan
- El resultado: menos pacientes atendidos, planes genéricos y profesionales agotados

---

## Diapositiva 3: Human-Centered AI — Nuestra Filosofía

**El sistema PROPONE, el profesional DECIDE**

Principios HCAI que guían NutriOptimize:

1. **Human-in-the-loop** — El motor genera borradores, nunca planes finales. Todo pasa por la aprobación del nutriólogo.
2. **Transparencia** — El motor explica el "por qué" de cada sugerencia: razonamiento clínico, distribución de macros, selección de alimentos.
3. **Control total** — El profesional puede editar, agregar, eliminar o sobreescribir cualquier comida o ingrediente.
4. **Sin decisiones automatizadas** — Ningún plan llega al paciente sin revisión humana explícita.
5. **Verificabilidad** — Vista de depuración que muestra exactamente qué datos se enviaron y qué respondió el motor.
6. **Asistente contextual HCAI** — El asistente observa, pregunta y sugiere — pero NUNCA decide. Genera observaciones clínicas y formula preguntas al nutriólogo para guiar su razonamiento, sin emitir diagnósticos ni instrucciones.

**Flujo HCAI:**

```
Datos del Paciente → Motor de Optimización → Borrador
       ↓                                        ↓
  Perfil clínico                         Revisión del Nutriólogo
  Alergias                                      ↓
  Condiciones                          Edición granular
  Presupuesto                                   ↓
  Preferencias                          Plan Aprobado
                                                ↓
                                        PDF al Paciente
                                       (vía WhatsApp)
```

---

## Diapositiva 4: Demo / Screenshots

**Flujo completo de uso**

| Paso | Pantalla | Descripción |
|------|----------|-------------|
| 1 | Dashboard | Panel con pacientes y planes pendientes de revisión |
| 2 | Perfil del Paciente | Datos clínicos, cálculos de IMC/TMB/TDEE, botón de generar plan |
| 3 | Procesamiento | Animación de progreso mientras el motor analiza el perfil |
| 4 | Editor de Plan | Revisión y edición granular de cada comida, macros y porciones |

*Insertar capturas de pantalla:*
- `docs/screenshots/dashboard.png`
- `docs/screenshots/patient_detail.png`
- `docs/screenshots/processing.png`
- `docs/screenshots/draft_editor.png`

---

## Diapositiva 5: Arquitectura Técnica

**Stack nativo iOS con arquitectura MVVM**

| Capa | Tecnología | Propósito |
|------|-----------|-----------|
| **UI** | SwiftUI | Interfaz declarativa con animaciones y hápticos |
| **Estado** | MVVM + @Published | ViewModels reactivos con estado observable |
| **Persistencia** | SwiftData | Almacenamiento local de pacientes en el dispositivo |
| **Motor** | OpenRouter API | Backend del motor de optimización inteligente |
| **PDF** | UIGraphicsPDFRenderer | Generación nativa de documentos profesionales |
| **Testabilidad** | Protocolos + Mocks | Inyección de dependencias para pruebas |

**Cálculos clínicos integrados:**
- IMC (Índice de Masa Corporal) con clasificación
- TMB con ecuación de Mifflin-St Jeor
- TDEE con factores PAL por nivel de actividad
- Distribución y porcentajes de macronutrientes

---

## Diapositiva 6: Funcionalidades Clave

**Todo lo que un nutriólogo necesita en su flujo diario**

**Gestión de Pacientes**
- CRUD completo con datos clínicos: alergias, condiciones, preferencias, presupuesto
- Búsqueda y filtrado instantáneo
- Cálculos antropométricos automáticos

**Motor de Optimización**
- Considera perfil completo: edad, peso, alergias, condiciones, actividad, presupuesto, tiempo de cocina
- Prompt personalizable por el nutriólogo según su estilo de prescripción
- Alimentos y porciones en español mexicano

**Asistente Clínico Contextual**
- Asistente integrado que analiza datos del paciente y formula preguntas al nutriólogo
- Disponible en perfil, historial, laboratorios y retroalimentación
- Importación de estudios de laboratorio desde PDF para análisis inmediato

**Editor de Planes**
- Edición granular: nombre, ingredientes, macros, porciones, tipo de comida
- Agregar/eliminar comidas libremente
- Plantillas rápidas para comidas frecuentes
- Totales recalculados en tiempo real
- Aprobar o descartar el borrador

**Productividad**
- PDF profesional con branding, datos del paciente, resumen nutricional y análisis del motor
- Listo para compartir por WhatsApp
- Centro de ayuda integrado con guías paso a paso y preguntas frecuentes

---

## Diapositiva 7: Diferenciadores

**Por qué NutriOptimize es diferente**

| Diferenciador | Descripción |
|---|---|
| **100% HCAI** | Nunca reemplaza al profesional. El motor asiste, el nutriólogo decide. |
| **Mercado mexicano** | Alimentos locales, presupuesto en MXN, español mexicano, flujo clínico local. |
| **Prompt personalizable** | El nutriólogo define su estilo de prescripción. El motor se adapta a cada profesional. |
| **Transparencia total** | Vista de depuración que muestra exactamente qué procesa el motor: datos enviados y respuesta cruda. |
| **PDF profesional** | Documento listo para el paciente con branding, datos clínicos y análisis del motor. |
| **Sin dependencia** | Funciona con datos de demostración sin API key. El motor es un acelerador, no un requisito. |

---

## Diapositiva 8: Roadmap

**Evolución planificada de NutriOptimize**

| Fase | Funcionalidades | Estado |
|------|----------------|--------|
| **Fase 1 — MVP** | CRUD de pacientes, motor de optimización, editor de borradores, exportación PDF, dashboard, cálculos clínicos | ✅ Completado |
| **Fase 2 — Seguimiento** | Historial de consultas, gráficas de progreso, fotos del paciente, estudios de laboratorio, importación PDF/JSON | ✅ Completado |
| **Fase 3 — Productividad** | Asistente clínico contextual, plantillas rápidas, centro de ayuda | ✅ Parcial |
| **Fase 3b — Pendiente** | Agenda y citas, personalización del motor por paciente | 📋 Siguiente |
| **Fase 4 — Escala** | Backend remoto, soporte multi-nutriólogo, cumplimiento NOM-051 y COFEPRIS | 📋 Futuro |

---

## Diapositiva 9: Impacto

**Resultados tangibles para el profesional de nutrición**

- **Tiempo:** Reduce la creación de planes alimenticios de **45 minutos a 5 minutos** por paciente
- **Consistencia:** Cálculos antropométricos automatizados (IMC, TMB, TDEE) eliminan errores manuales
- **Accesibilidad:** Democratiza herramientas profesionales para nutriólogos independientes que no pueden pagar software empresarial
- **Autonomía:** Respeta completamente la autonomía profesional del nutriólogo — siempre tiene la última palabra
- **Pacientes:** Más pacientes atendidos por día con planes de mayor calidad y personalización
- **Confianza:** El paciente recibe un PDF profesional con el análisis clínico que respalda su plan

---

## Diapositiva 10: Cierre

**"NutriOptimize: Donde la inteligencia artificial amplifica la experticia humana"**

No reemplazamos al nutriólogo. Le damos superpoderes.

**Equipo:**
- Jorge Salgado Miranda
- Michelle Paola González Martínez
- Arroyo Ramírez Carlos Alberto

**Repositorio:** github.com/chochy2001/NutriOptimize

*Insertar QR al repositorio*

---

## Notas para el Presentador

- **Duración estimada:** 8-10 minutos de presentación + 5 minutos de Q&A
- **Demo en vivo:** Si es posible, mostrar el flujo completo en el simulador: seleccionar paciente, generar plan, editar comida, exportar PDF
- **Punto clave a enfatizar:** El enfoque HCAI no es un accesorio, es la filosofía central del diseño. Cada decisión arquitectónica refuerza que el profesional tiene el control.
- **Pregunta anticipada:** "¿Qué pasa si el motor falla o no hay internet?" — La app funciona con datos de demostración y el nutriólogo siempre puede crear planes manualmente editando un borrador vacío.
