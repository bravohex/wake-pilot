import XCTest
@testable import BrHxWakePilot

final class AppPreferencesTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var legacySuiteName: String!
    private var legacyDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "BrHxWakePilotTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        defaults.removeVolatileDomain(forName: UserDefaults.registrationDomain)

        legacySuiteName = "StayActiveTests.\(UUID().uuidString)"
        legacyDefaults = UserDefaults(suiteName: legacySuiteName)
        legacyDefaults.removePersistentDomain(forName: legacySuiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults.removeVolatileDomain(forName: UserDefaults.registrationDomain)
        legacyDefaults.removePersistentDomain(forName: legacySuiteName)
        legacyDefaults = nil
        legacySuiteName = nil
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testLoadsRegisteredDefaults() {
        let settings = makePreferences().load()

        XCTAssertEqual(
            settings,
            AppSettings(
                isEnabled: true,
                keepDisplayAwake: false,
                presenceHeartbeatEnabled: true,
                intervalMinutes: 3,
                scheduleEnabled: false,
                scheduleStartMinutes: 540,
                scheduleEndMinutes: 1_080,
                language: .english
            )
        )
    }

    func testNormalizesInvalidStoredInterval() {
        defaults.set(99, forKey: "stayActive.intervalMinutes")

        let settings = makePreferences().load()

        XCTAssertEqual(settings.intervalMinutes, 3)
        XCTAssertEqual(defaults.integer(forKey: "stayActive.intervalMinutes"), 3)
    }

    func testNormalizesInvalidStoredScheduleTimes() {
        defaults.set(-1, forKey: "wakePilot.scheduleStartMinutes")
        defaults.set(1_440, forKey: "wakePilot.scheduleEndMinutes")

        let settings = makePreferences().load()

        XCTAssertEqual(settings.scheduleStartMinutes, 540)
        XCTAssertEqual(settings.scheduleEndMinutes, 1_080)
    }

    func testDefaultsToEnglishForAnInvalidStoredLanguage() {
        defaults.set("unsupported", forKey: "wakePilot.language")

        XCTAssertEqual(makePreferences().load().language, .english)
    }

    func testSavesNormalizedSettings() {
        let preferences = makePreferences()
        preferences.save(
            AppSettings(
                isEnabled: false,
                keepDisplayAwake: true,
                presenceHeartbeatEnabled: false,
                intervalMinutes: -1,
                scheduleEnabled: true,
                scheduleStartMinutes: -1,
                scheduleEndMinutes: 1_440,
                language: .japanese
            )
        )

        XCTAssertEqual(
            preferences.load(),
            AppSettings(
                isEnabled: false,
                keepDisplayAwake: true,
                presenceHeartbeatEnabled: false,
                intervalMinutes: 3,
                scheduleEnabled: true,
                scheduleStartMinutes: 540,
                scheduleEndMinutes: 1_080,
                language: .japanese
            )
        )
    }

    func testMigratesLegacyHeartbeatSetting() {
        defaults.set(false, forKey: "stayActive.simulateActivity")

        let settings = makePreferences().load()

        XCTAssertFalse(settings.presenceHeartbeatEnabled)
        XCTAssertNil(defaults.object(forKey: "stayActive.simulateActivity"))
        XCTAssertEqual(
            defaults.object(forKey: "stayActive.presenceHeartbeatEnabled") as? Bool,
            false
        )
    }

    func testMigratesSettingsFromPreviousBundle() {
        legacyDefaults.set(false, forKey: "stayActive.isEnabled")
        legacyDefaults.set(true, forKey: "stayActive.keepDisplayAwake")
        legacyDefaults.set(false, forKey: "stayActive.simulateActivity")
        legacyDefaults.set(10, forKey: "stayActive.intervalMinutes")

        let settings = makePreferences().load()

        XCTAssertEqual(
            settings,
            AppSettings(
                isEnabled: false,
                keepDisplayAwake: true,
                presenceHeartbeatEnabled: false,
                intervalMinutes: 10,
                scheduleEnabled: false,
                scheduleStartMinutes: 540,
                scheduleEndMinutes: 1_080,
                language: .english
            )
        )
    }

    private func makePreferences() -> AppPreferences {
        AppPreferences(
            defaults: defaults,
            persistentDomainName: suiteName,
            legacyDefaults: legacyDefaults,
            legacyPersistentDomainName: legacySuiteName
        )
    }
}
