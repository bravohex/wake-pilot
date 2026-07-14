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
                intervalMinutes: 3
            )
        )
    }

    func testNormalizesInvalidStoredInterval() {
        defaults.set(99, forKey: "stayActive.intervalMinutes")

        let settings = makePreferences().load()

        XCTAssertEqual(settings.intervalMinutes, 3)
        XCTAssertEqual(defaults.integer(forKey: "stayActive.intervalMinutes"), 3)
    }

    func testSavesNormalizedSettings() {
        let preferences = makePreferences()
        preferences.save(
            AppSettings(
                isEnabled: false,
                keepDisplayAwake: true,
                presenceHeartbeatEnabled: false,
                intervalMinutes: -1
            )
        )

        XCTAssertEqual(
            preferences.load(),
            AppSettings(
                isEnabled: false,
                keepDisplayAwake: true,
                presenceHeartbeatEnabled: false,
                intervalMinutes: 3
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
                intervalMinutes: 10
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
