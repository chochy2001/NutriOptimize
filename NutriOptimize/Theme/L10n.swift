import Foundation

/// Typed accessors for NutriOptimize user-facing copy (EN + ES via Localizable.strings).
enum L10n {
    // MARK: - Appearance

    static var appearanceSystem: String { tr("appearance.system") }
    static var appearanceLight: String { tr("appearance.light") }
    static var appearanceDark: String { tr("appearance.dark") }
    static var appearanceSectionTitle: String { tr("appearance.section.title") }
    static var appearanceColorMode: String { tr("appearance.color_mode") }
    static var appearanceFooter: String { tr("appearance.footer") }

    // MARK: - Common actions

    static var actionClose: String { tr("action.close") }
    static var actionSave: String { tr("action.save") }
    static var actionSkip: String { tr("action.skip") }
    static var actionNext: String { tr("action.next") }
    static var actionBack: String { tr("action.back") }
    static var actionStart: String { tr("action.start") }
    static var actionEdit: String { tr("action.edit") }
    static var actionDelete: String { tr("action.delete") }
    static var savedConfirmation: String { tr("action.saved") }

    // MARK: - Splash

    static var splashTagline: String { tr("splash.tagline") }

    // MARK: - Onboarding

    static var onboardingSkipHint: String { tr("onboarding.skip.hint") }
    static var onboardingSkipAccessibility: String { tr("onboarding.skip.accessibility") }
    static func onboardingPageAccessibility(current: Int, total: Int) -> String {
        String(format: tr("onboarding.page.accessibility"), current, total)
    }
    static var onboardingStartAccessibility: String { tr("onboarding.start.accessibility") }
    static var onboardingNextAccessibility: String { tr("onboarding.next.accessibility") }
    static var onboardingBackAccessibility: String { tr("onboarding.back.accessibility") }

    static var onboardingWelcomeTitle: String { tr("onboarding.welcome.title") }
    static var onboardingWelcomeBody: String { tr("onboarding.welcome.body") }
    static var onboardingPatientsTitle: String { tr("onboarding.patients.title") }
    static var onboardingPatientsBody: String { tr("onboarding.patients.body") }
    static var onboardingOptimizeTitle: String { tr("onboarding.optimize.title") }
    static var onboardingOptimizeBody: String { tr("onboarding.optimize.body") }
    static var onboardingTrackTitle: String { tr("onboarding.track.title") }
    static var onboardingTrackBody: String { tr("onboarding.track.body") }

    // MARK: - Dashboard

    static var dashboardSearchPrompt: String { tr("dashboard.search_prompt") }
    static var dashboardLoading: String { tr("dashboard.loading") }
    static var dashboardLoadError: String { tr("dashboard.load_error") }
    static var dashboardPendingReview: String { tr("dashboard.pending_review") }
    static var dashboardPatients: String { tr("dashboard.patients") }
    static func dashboardMealsCount(_ count: Int) -> String {
        String(format: tr("dashboard.meals_count"), count)
    }
    static var deletePatientTitle: String { tr("dashboard.delete_patient.title") }
    static func deletePatientMessage(_ name: String) -> String {
        String(format: tr("dashboard.delete_patient.message"), name)
    }

    // MARK: - Settings

    static var settingsTitle: String { tr("settings.title") }
    static var settingsEngineSection: String { tr("settings.engine.section") }
    static var settingsEngineApiKey: String { tr("settings.engine.api_key") }
    static var settingsEngineTestConnection: String { tr("settings.engine.test_connection") }
    static var settingsEngineConnected: String { tr("settings.engine.connected") }
    static var settingsEngineFooter: String { tr("settings.engine.footer") }
    static var settingsPromptSection: String { tr("settings.prompt.section") }
    static var settingsPromptPlaceholder: String { tr("settings.prompt.placeholder") }
    static var settingsPromptFooter: String { tr("settings.prompt.footer") }
    static var settingsDebugToggle: String { tr("settings.debug.toggle") }
    static var settingsDebugFooter: String { tr("settings.debug.footer") }
    static var settingsInfoSection: String { tr("settings.info.section") }
    static var settingsInfoModel: String { tr("settings.info.model") }
    static var settingsInfoProvider: String { tr("settings.info.provider") }
    static var settingsInfoStatus: String { tr("settings.info.status") }
    static var settingsInfoConfigured: String { tr("settings.info.configured") }
    static var settingsInfoNotConfigured: String { tr("settings.info.not_configured") }
    static var settingsInvalidURL: String { tr("settings.error.invalid_url") }
    static func settingsHTTPError(_ code: Int) -> String {
        String(format: tr("settings.error.http"), code)
    }
    static var settingsNoConnection: String { tr("settings.error.no_connection") }

    // MARK: - Privacy / consent

    static var settingsPrivacySection: String { tr("settings.privacy.section") }
    static var settingsPrivacyConsentGranted: String { tr("settings.privacy.consent_granted") }
    static var settingsPrivacyConsentPending: String { tr("settings.privacy.consent_pending") }
    static var settingsPrivacyRevoke: String { tr("settings.privacy.revoke") }
    static var settingsPrivacyFooter: String { tr("settings.privacy.footer") }

    static var consentTitle: String { tr("consent.title") }
    static var consentBody: String { tr("consent.body") }
    static var consentAccept: String { tr("consent.accept") }
    static var consentCancel: String { tr("consent.cancel") }

    // MARK: - Demo draft

    static var demoBannerTitle: String { tr("demo.banner.title") }
    static var demoBannerBody: String { tr("demo.banner.body") }

    private static func tr(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .main, comment: "")
    }
}
