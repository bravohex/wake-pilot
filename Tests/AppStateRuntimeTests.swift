import XCTest
@testable import WakePilot

final class AppStateRuntimeTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "WakePilotTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    @MainActor
    func testAppliesCurrentSettingsToRuntimeController() {
        let runtimeController = RecordingRuntimeController()
        let state = AppState(
            preferences: makePreferences(),
            runtimeController: runtimeController
        )

        XCTAssertEqual(runtimeController.configurations.count, 1)
        XCTAssertEqual(
            runtimeController.configurations.last,
            RuntimeConfiguration(
                isEnabled: true,
                keepDisplayAwake: false,
                presenceHeartbeatEnabled: true,
                intervalMinutes: 3,
                hasAccessibilityPermission: state.hasAccessibilityPermission
            )
        )

        state.keepDisplayAwake = true

        XCTAssertEqual(runtimeController.configurations.count, 2)
        XCTAssertEqual(runtimeController.configurations.last?.keepDisplayAwake, true)
    }

    @MainActor
    func testSurfacesRuntimeErrors() {
        let runtimeController = RecordingRuntimeController(errorMessage: "Power assertion failed")
        let state = AppState(
            preferences: makePreferences(),
            runtimeController: runtimeController
        )

        XCTAssertEqual(state.errorMessage, "Power assertion failed")
    }

    @MainActor
    func testPersistsLanguageAndPassesItToRuntime() {
        let preferences = makePreferences()
        let runtimeController = RecordingRuntimeController()
        let state = AppState(
            preferences: preferences,
            runtimeController: runtimeController
        )

        XCTAssertEqual(state.language, .english)

        state.language = .japanese

        XCTAssertEqual(preferences.load().language, .japanese)
        XCTAssertEqual(runtimeController.configurations.last?.language, .japanese)
        XCTAssertEqual(state.localized(.settings), "設定…")
    }

    @MainActor
    func testStopsRuntimeOutsideAnEnabledSchedule() {
        let preferences = makePreferences()
        preferences.save(
            AppSettings(
                isEnabled: true,
                keepDisplayAwake: true,
                presenceHeartbeatEnabled: true,
                intervalMinutes: 3,
                scheduleEnabled: true,
                scheduleStartMinutes: 9 * 60,
                scheduleEndMinutes: 18 * 60
            )
        )
        let runtimeController = RecordingRuntimeController()
        let state = AppState(
            preferences: preferences,
            runtimeController: runtimeController,
            now: { self.date(hour: 8, minute: 0) },
            schedulesTransitions: false
        )

        XCTAssertFalse(state.isWithinScheduledTime)
        XCTAssertEqual(state.statusText, "Outside scheduled hours")
        XCTAssertEqual(runtimeController.configurations.last?.isEnabled, false)
    }

    private func date(hour: Int, minute: Int) -> Date {
        Calendar.current.date(
            from: DateComponents(
                calendar: Calendar.current,
                timeZone: Calendar.current.timeZone,
                year: 2026,
                month: 7,
                day: 14,
                hour: hour,
                minute: minute
            )
        )!
    }

    private func makePreferences() -> AppPreferences {
        AppPreferences(defaults: defaults)
    }
}

@MainActor
private final class RecordingRuntimeController: RuntimeControlling {
    private(set) var configurations: [RuntimeConfiguration] = []
    private let errorMessage: String?

    init(errorMessage: String? = nil) {
        self.errorMessage = errorMessage
    }

    func apply(
        configuration: RuntimeConfiguration,
        onHeartbeat: @escaping @MainActor @Sendable () -> Void
    ) -> String? {
        configurations.append(configuration)
        return errorMessage
    }
}
