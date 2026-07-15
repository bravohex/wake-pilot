import XCTest
@testable import WakePilot

final class AppPreferencesTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "WakePilotTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        defaults.removeVolatileDomain(forName: UserDefaults.registrationDomain)

    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults.removeVolatileDomain(forName: UserDefaults.registrationDomain)
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
        defaults.set(99, forKey: "wakePilot.intervalMinutes")

        let settings = makePreferences().load()

        XCTAssertEqual(settings.intervalMinutes, 3)
        XCTAssertEqual(defaults.integer(forKey: "wakePilot.intervalMinutes"), 3)
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

    func testLoadsStoredHeartbeatSetting() {
        defaults.set(false, forKey: "wakePilot.presenceHeartbeatEnabled")

        let settings = makePreferences().load()

        XCTAssertFalse(settings.presenceHeartbeatEnabled)
        XCTAssertEqual(
            defaults.object(forKey: "wakePilot.presenceHeartbeatEnabled") as? Bool,
            false
        )
    }

    private func makePreferences() -> AppPreferences {
        AppPreferences(defaults: defaults)
    }
}
