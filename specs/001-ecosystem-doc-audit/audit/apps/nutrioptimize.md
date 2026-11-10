# Audit Inventory: `NutriOptimize` (`chochy2001/NutriOptimize`)

- **Task**: `[Spec Kit][T025]` (`#7`)
- **Repository**: `chochy2001/NutriOptimize`
- **Default branch**: `main`
- **Audit date**: `2026-11-10`

## Workspace Inventory Table

| path | kind | git_root | nearest_guidance | manifests | documentation_roots | status | notes |
|------|------|----------|------------------|-----------|---------------------|--------|-------|
| `.` | `mobile` | `.` | `AGENTS.md`, `CLAUDE.md` | `project.yml`, `NutriOptimize.xcodeproj/project.pbxproj`, `.github/workflows/gitleaks.yml`, `.pre-commit-config.yaml`, `.gitleaks.toml` | `README.md`, `FEATURES.md`, `PRESENTATION.md`, `CONTRIBUTING.md`, `MASTER_SPEC.md` | `completed` | Native iOS 17+ (`SWIFT_VERSION = "5.9"`, `MARKETING_VERSION = "1.0.0"`, `CURRENT_PROJECT_VERSION = "1"`, bundle prefix `com.nutrioptimize`) SwiftUI + SwiftData clinical nutrition workspace generated via XcodeGen (`project.yml`). |
| `NutriOptimize/` | `mobile` | `.` | `AGENTS.md`, `CLAUDE.md` | `project.yml`, `NutriOptimize.xcodeproj/project.pbxproj` | `README.md`, `FEATURES.md` | `completed` | Main iOS application source root: `NutriOptimizeApp.swift`, `Models/` (8 domain/SwiftData models), `Services/` (`OpenRouterService`, `PatientStore`, `PDFExportService`, `LabDocumentImporter`, `DemoDataSeeder`, protocols & mocks), `ViewModels/` (3 `@MainActor` ViewModels), `Views/` (`RootCoordinatorView`, `Splash`, `Onboarding`, `Dashboard`, `Patient`, `Draft`, `Settings`, `Help`, `Components`), `Theme/` (`AppTheme`, `AppearancePreference`, `HapticManager`, `L10n`), and `en.lproj` / `es.lproj` localization tables (69 `Localizable.strings` keys + 2 `InfoPlist.strings` keys in exact EN/ES parity). Note: contains an empty/residual nested workspace descriptor `NutriOptimize/NutriOptimize.xcodeproj/project.xcworkspace/contents.xcworkspacedata` noted under drift. |
| `NutriOptimizeTests/` | `mobile` | `.` | `AGENTS.md`, `CLAUDE.md` | `project.yml` (`NutriOptimizeTests` `bundle.unit-test` target) | `README.md` | `completed` | **14** XCTest unit-test suites containing **156** `test*` methods covering anthropometric math, meals/macros, plan drafts, SwiftData CRUD & cascade deletion, OpenRouter prompt construction & consent gating, PDF export, lab PDF/JSON import, ViewModels, and EN/ES localization parity. |
| `.github/workflows/` | `infrastructure` | `.` | `CLAUDE.md` | `.github/workflows/gitleaks.yml`, `.gitleaks.toml`, `.pre-commit-config.yaml` | `CLAUDE.md` | `completed` | GitHub-hosted (`ubuntu-latest`) Gitleaks `8.24.0` secret-scanning workflow running on `pull_request`, `push` (`main`/`master`), and `workflow_dispatch`. |
| `docs/screenshots/`, `README.md`, `FEATURES.md`, `PRESENTATION.md`, `CONTRIBUTING.md` | `documentation` | `.` | `AGENTS.md` | `none-found` | `README.md`, `FEATURES.md`, `PRESENTATION.md`, `CONTRIBUTING.md` | `completed` | Product documentation, feature reference, hackathon slide deck, contributor workflow guide, and UI screenshots (`dashboard.png`, `patient_detail.png`, `processing.png`, `draft_editor.png`). |
| `build/`, `DerivedData/`, `xcuserdata/` | `generated` | `.` | `AGENTS.md` | `none-found` | `none-found` | `excluded` | Gitignored Xcode build outputs and user workspace state (`.gitignore`). |

## Application Record Table

| name | root_path | repo_path | stack | source_roots | test_roots | validation_plan | master_spec_path | readiness |
|------|-----------|-----------|-------|--------------|------------|-----------------|------------------|-----------|
| `nutrioptimize` | `.` | `chochy2001/NutriOptimize` | Swift 5.9, SwiftUI, SwiftData, Swift Charts, PDFKit & `UIGraphicsPDFRenderer`, iOS 17.0+, XcodeGen (`project.yml`), OpenRouter API (`google/gemini-2.5-flash`) | `NutriOptimize/` | `NutriOptimizeTests/` (14 suites, 156 unit tests) | `xcodegen generate && xcodebuild -project NutriOptimize.xcodeproj -scheme NutriOptimize -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' test` (macOS/Xcode required) + EN/ES `.strings` parity & Gitleaks secret scan | `MASTER_SPEC.md` | `partial` |
