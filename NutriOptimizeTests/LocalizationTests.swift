import XCTest
@testable import NutriOptimize

final class LocalizationTests: XCTestCase {
    private let requiredKeys = [
        "appearance.system",
        "appearance.light",
        "appearance.dark",
        "appearance.section.title",
        "appearance.color_mode",
        "appearance.footer",
        "action.close",
        "action.save",
        "action.skip",
        "action.next",
        "action.back",
        "action.start",
        "action.edit",
        "action.delete",
        "action.saved",
        "splash.tagline",
        "onboarding.skip.hint",
        "onboarding.skip.accessibility",
        "onboarding.page.accessibility",
        "onboarding.start.accessibility",
        "onboarding.next.accessibility",
        "onboarding.back.accessibility",
        "onboarding.welcome.title",
        "onboarding.welcome.body",
        "onboarding.patients.title",
        "onboarding.patients.body",
        "onboarding.optimize.title",
        "onboarding.optimize.body",
        "onboarding.track.title",
        "onboarding.track.body",
        "dashboard.search_prompt",
        "dashboard.loading",
        "dashboard.load_error",
        "dashboard.pending_review",
        "dashboard.patients",
        "dashboard.meals_count",
        "settings.title",
        "settings.engine.section",
        "settings.engine.api_key",
        "settings.engine.test_connection",
        "settings.engine.connected",
        "settings.engine.footer",
        "settings.prompt.section",
        "settings.prompt.placeholder",
        "settings.prompt.footer",
        "settings.debug.toggle",
        "settings.debug.footer",
        "settings.info.section",
        "settings.info.model",
        "settings.info.provider",
        "settings.info.status",
        "settings.info.configured",
        "settings.info.not_configured",
        "settings.error.invalid_url",
        "settings.error.http",
        "settings.error.no_connection"
    ]

    func testEnglishAndSpanishLocalizationsContainAllKeys() {
        for key in requiredKeys {
            XCTAssertNotEqual(localized(key, locale: "en"), key, "Missing EN translation for \(key)")
            XCTAssertNotEqual(localized(key, locale: "es"), key, "Missing ES translation for \(key)")
        }
    }

    func testAppearancePreferenceLabelsUseLocalization() {
        XCTAssertFalse(AppearancePreference.system.localizedLabel.isEmpty)
        XCTAssertFalse(AppearancePreference.light.localizedLabel.isEmpty)
        XCTAssertFalse(AppearancePreference.dark.localizedLabel.isEmpty)
    }

    private func localized(_ key: String, locale: String) -> String {
        guard
            let path = Bundle.main.path(forResource: locale, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            XCTFail("Missing \(locale).lproj bundle")
            return key
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
