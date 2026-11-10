# Validation Evidence & Documentation Drift: `NutriOptimize`

- **Task**: `[Spec Kit][T044]` (`#8`)
- **Repository**: `chochy2001/NutriOptimize`
- **Audit date**: `2026-11-10`

## Validation Record Table

| application | working_directory | command | scope | status | reason | next_action | evidence_paths |
|-------------|-------------------|---------|-------|--------|-------------|----------------|----------------|
| `nutrioptimize` | `.` | `python` localization & test-suite audit (`en.lproj` vs `es.lproj` key parity + `project.yml` target check) | `docs` | `pass` | Verified exact EN/ES key parity (`69/69` keys in `Localizable.strings`, `2/2` keys in `InfoPlist.strings`, `0` missing keys in either locale) and enumerated **14** XCTest suites (**156** `test*` methods) wired under `NutriOptimizeTests` in `project.yml`. | `none` | `NutriOptimize/en.lproj/*.strings`, `NutriOptimize/es.lproj/*.strings`, `NutriOptimizeTests/*.swift`, `project.yml` |
| `nutrioptimize` | `.` | `xcodebuild -project NutriOptimize.xcodeproj -scheme NutriOptimize -sdk iphonesimulator test` | `swift` | `blocked` | Requires macOS + Xcode 16+ + iOS 17+ Simulator (`xcodebuild` and `swift` are unavailable on this Windows audit host, and `.github/workflows/` intentionally runs only `gitleaks.yml` on `ubuntu-latest`). | Run `xcodebuild test -project NutriOptimize.xcodeproj -scheme NutriOptimize -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` on a macOS workstation (or add a `macos-latest` CI job if automated iOS testing is desired). | `project.yml`, `NutriOptimize.xcodeproj/project.pbxproj`, `CLAUDE.md:18-31` |
| `nutrioptimize` | `.` | `manual-review` + `git diff --check` | `security` | `pass` | Verified Keychain storage (`KeychainHelper` `kSecClassGenericPassword` in `OpenRouterService.swift:23-69`), explicit `hasDataProcessingConsent` gate (`OpenRouterService.swift:102-115`), PHI pseudonymization (`patient.pseudonym` initials instead of `fullName` in `OpenRouterService.swift:196-209`), cascade deletion (`PatientStore.swift:174-210`), and zero committed API keys. | `none` | `NutriOptimize/Services/OpenRouterService.swift`, `NutriOptimize/Services/PatientStore.swift`, `.github/workflows/gitleaks.yml` |

## Integration Boundary Validation

| boundary | source_evidence | target_evidence | status | notes / next_action |
|----------|-----------------|-----------------|--------|---------------------|
| iOS App (`OpenRouterService`) -> OpenRouter Chat Completions API | `NutriOptimize/Services/OpenRouterService.swift:76-158` (`POST https://openrouter.ai/api/v1/chat/completions`, model `google/gemini-2.5-flash`, `response_format: json_object`, `timeoutInterval = 60`, Keychain Bearer key, `hasDataProcessingConsent` guard, pseudonymized `patient.pseudonym`), `NutriOptimizeTests/OpenRouterServiceTests.swift` (21 unit tests) | External OpenRouter API (`https://openrouter.ai/api/v1/chat/completions`); offline fallback via `MockOptimizationService` (`NutriOptimize/Services/Mock/MockOptimizationService.swift`) | `partial` | Prompt construction, JSON decoding, PHI pseudonymization, and consent gating are unit-tested (`OpenRouterServiceTests.swift`); live network calls require a user-supplied OpenRouter API key in iOS Keychain. |
| SwiftUI Views & ViewModels <-> On-Device SwiftData Container & Documents Storage | `NutriOptimize/NutriOptimizeApp.swift:15-22` (`ModelContainer` for `PatientRecord`, `PatientFeedbackRecord`, `ConsultationRecord`, `LabResultRecord`, `PlanDraftRecord`), `NutriOptimize/Services/PatientStore.swift`, `NutriOptimize/Views/Patient/ProgressPhotoView.swift` (`Documents/ProgressPhotos/<uuid>_<ts>.jpg`) | Local iOS SwiftData SQLite store + app sandbox `Documents/` directory (`PatientStoreCRUDTests.swift`, `PatientStoreCascadeTests.swift`, `PlanDraftRecordRoundTripTests.swift`) | `pass` | Bi-directional struct/record mapping and full cascade cleanup (records + JPEG files) are implemented and covered by dedicated unit tests (pending simulator execution on macOS). |
| Lab Results & Meal Plan Export <-> Local PDF / JSON Files (`PDFKit` & `UIGraphicsPDFRenderer`) | `NutriOptimize/Services/LabDocumentImporter.swift` (`LabDocumentImporterTests.swift`: 18 tests), `NutriOptimize/Services/PDFExportService.swift` (`PDFExportServiceTests.swift`: 8 tests) | User-selected PDF/JSON lab files via iOS file importer and exported US Letter PDF documents (`612x792 pt`) shared via iOS share sheet / WhatsApp | `pass` | Pure on-device document import/export with zero external cloud storage dependency. |

## Documentation Drift Classification

### 1. False pending items (Markdown says missing, code shows present)

| Location | Claim in Markdown | Actual Source Evidence | Disposition |
|----------|-------------------|------------------------|-------------|
| `FEATURES.md:343` | Heading `## Funcionalidades Planificadas` wraps items **15 through 27** (`Historial de Consultas`, `Fotos de Progreso`, `Estudios de Laboratorio`, `Datos Demo`, `Verificación de Conexión API`, `Accesibilidad`, `Comidas Ordenadas`, `Registro de Consulta`, `Asistente Clínico Contextual`, `Importación PDF/JSON`, `Plantillas Rápidas`, `Centro de Ayuda`, `Guía de Contribución`), even though each item below that heading is marked `✅ Implementado` and backed by real source files (with a duplicate `## Funcionalidades Planificadas` heading at line 501 for true Phase 3b/4 items 28–31). | Verified all 13 features (`15`–`27`) exist in `NutriOptimize/Models/`, `Services/`, and `Views/`. Only items `28`–`31` (calendar/appointments, per-patient prompt overrides, remote cloud sync, NOM-051/COFEPRIS validation) are genuinely unimplemented roadmap items. | Clarified implemented vs planned features in `MASTER_SPEC.md`. |

### 2. Ghost code (Code exists in repo, `README.md` / `FEATURES.md` omitted or under-documented it)

| Source Path | Undocumented / Under-documented Capability | Notes |
|-------------|--------------------------------------------|-------|
| `NutriOptimize/Services/OpenRouterService.swift:23-69,98-116,196-209` & `NutriOptimize/Views/Settings/DataProcessingConsentView.swift` | System Keychain storage (`com.nutrioptimize.api`) for the OpenRouter API key, mandatory `DataProcessingConsentView` (`ServiceError.consentRequired`), and PHI pseudonymization (`patient.pseudonym` initials instead of `fullName`). (`FEATURES.md:297` only mentioned a generic secure field without documenting Keychain, consent gating, or pseudonymization.) | Documented in `MASTER_SPEC.md` security & privacy architecture. |
| `NutriOptimize/Services/PatientStore.swift:174-210` & `NutriOptimizeTests/PatientStoreCascadeTests.swift` | Full clinical cascade deletion across `ConsultationRecord`, `LabResultRecord`, `PatientFeedbackRecord`, `PlanDraftRecord`, and `Documents/ProgressPhotos/<uuid>_*.jpg`. | Added to `MASTER_SPEC.md`. |
| `NutriOptimize/Views/{RootCoordinatorView,Splash/SplashView,Onboarding/OnboardingView}.swift`, `Theme/{AppearancePreference,L10n}.swift`, `en.lproj` / `es.lproj` | App launch coordinator, onboarding flow, persisted light/dark/system appearance preference (`AppearancePreference`), and full bilingual EN/ES localization (`69` string keys + `L10n.swift`). (`README.md:153-208` architecture tree omitted `RootCoordinatorView`, `OnboardingView`, `SplashView`, `DataProcessingConsentView`, `AppearancePreference`, `L10n`, and `en.lproj`/`es.lproj`.) | Added to `MASTER_SPEC.md` source map and capabilities. |
| **8** additional XCTest suites in `NutriOptimizeTests/` | `DraftEditorViewModelTests.swift` (9), `LabDocumentImporterTests.swift` (18), `LocalizationTests.swift` (2), `OptimizationDashboardViewModelTests.swift` (9), `PatientStoreCRUDTests.swift` (10), `PatientStoreCascadeTests.swift` (2), `PlanDraftRecordRoundTripTests.swift` (5), and `ServiceErrorTests.swift` (4) are tracked in git and `project.yml` but omitted from `README.md:88-113`. | Reconciled in `MASTER_SPEC.md` (`14` suites, `156` tests). |

### 3. Stale claims (Markdown contradicts current code or manifests)

| Location | Stale Claim | Current Reality in Source |
|----------|-------------|---------------------------|
| `README.md:88,104-113,209-216` | Claims `"El proyecto incluye 84 pruebas unitarias organizadas en 6 suites"` (`PDFExportServiceTests: 5`, `MockOptimizationServiceTests: 13`, `OpenRouterServiceTests: 17`). | `NutriOptimizeTests/` contains **156** unit-test functions across **14** test suites (`PDFExportServiceTests` has `8`, `MockOptimizationServiceTests` has `19`, `OpenRouterServiceTests` has `21`, plus 8 newer suites). |
| `README.md:72,74` | Lists `"Datos demo realistas precargados - 5 pacientes con 6 consultas..."` twice consecutively in the feature bullet list. | Deduplicated in `MASTER_SPEC.md`. |
| `FEATURES.md:246` vs `OpenRouterService.swift:23-69` | `FEATURES.md` describes settings persistence via `UserDefaults` without distinguishing that `openrouter_api_key` is stored in iOS Keychain (`KeychainHelper`) while non-secret preferences (`custom_optimization_prompt`, `data_processing_consent_accepted`, `show_engine_debug`, `AppearancePreference`) live in `UserDefaults`. | Clarified storage split in `MASTER_SPEC.md`. |
| Nested `NutriOptimize/NutriOptimize.xcodeproj/project.xcworkspace/contents.xcworkspacedata` & `AppIcon.appiconset/WhatsApp Image 2026-04-20 at 1.01.26 PM.jpeg` | Residual nested `.xcodeproj` workspace metadata file inside source folder `NutriOptimize/` alongside canonical root `NutriOptimize.xcodeproj`. | Flagged as minor repository hygiene cleanup item in `MASTER_SPEC.md`. |

### 4. Unresolved claims (External / unimplemented scope)

| Claim / Surface | Why Unresolved in Repo Alone | Tracking / Next Action |
|-----------------|------------------------------|------------------------|
| Hackathon impact claim in `PRESENTATION.md:170` (`"Reduce la creación de planes alimenticios de 45 minutos a 5 minutos"`) | Presentation benchmark/estimate with no empirical clinical study dataset in the repository. | Do not present as measured clinical trial evidence; frame as workflow design goal. |
| Apple Developer signing, TestFlight/App Store distribution, and macOS `xcodebuild test` execution | `project.yml` configures local simulator/device development (`MARKETING_VERSION = 1.0.0`, no App Store provisioning or `macos-latest` CI test workflow). | Keep readiness at `Partial` until `xcodebuild test` is executed on macOS and signing/distribution requirements are defined. |
