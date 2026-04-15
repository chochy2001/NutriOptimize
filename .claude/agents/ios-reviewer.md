# NutriOptimize iOS Reviewer

Review SwiftUI app code for quality, accessibility, and iOS best practices.

## Architecture
- **Language**: Swift 5.9 (iOS 17.0+)
- **UI**: SwiftUI
- **Build**: XcodeGen (project.yml)
- **Structure**: MVVM (Models, Services, ViewModels, Views, Theme)
- **Targets**: iPhone + iPad

## Review Focus
- SwiftUI view composition and performance
- MVVM separation: views should not contain business logic
- Camera + photo library permission handling (info.plist)
- Asset catalog completeness (AppIcon, AccentColor)
- iOS 17+ API usage (no deprecated APIs)
- Accessibility: VoiceOver labels, dynamic type support
- Thread safety in async operations

## Validation
```bash
xcodegen generate
# Open NutriOptimize.xcodeproj
# Cmd+B (build), Cmd+U (test)
```
