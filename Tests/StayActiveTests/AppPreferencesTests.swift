import XCTest
@testable import StayActive

final class AppPreferencesTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "StayActiveTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testLoadsRegisteredDefaults() {
        let settings = AppPreferences(defaults: defaults).load()

        XCTAssertEqual(
            settings,
            AppSettings(
                isEnabled: true,
                keepDisplayAwake: false,
                simulateActivity: true,
                intervalMinutes: 3
            )
        )
    }

    func testNormalizesInvalidStoredInterval() {
        defaults.set(99, forKey: "stayActive.intervalMinutes")

        let settings = AppPreferences(defaults: defaults).load()

        XCTAssertEqual(settings.intervalMinutes, 3)
        XCTAssertEqual(defaults.integer(forKey: "stayActive.intervalMinutes"), 3)
    }

    func testSavesNormalizedSettings() {
        let preferences = AppPreferences(defaults: defaults)
        preferences.save(
            AppSettings(
                isEnabled: false,
                keepDisplayAwake: true,
                simulateActivity: false,
                intervalMinutes: -1
            )
        )

        XCTAssertEqual(
            preferences.load(),
            AppSettings(
                isEnabled: false,
                keepDisplayAwake: true,
                simulateActivity: false,
                intervalMinutes: 3
            )
        )
    }
}
