import XCTest
@testable import BrHxWakePilot

final class AppStateRuntimeTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "BrHxWakePilotTests.\(UUID().uuidString)"
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

        XCTAssertEqual(state.language, .vietnamese)

        state.language = .english

        XCTAssertEqual(preferences.load().language, .english)
        XCTAssertEqual(runtimeController.configurations.last?.language, .english)
        XCTAssertEqual(state.localized(.settings), "Settings…")
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
        XCTAssertEqual(state.statusText, "Ngoài khung giờ")
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
        AppPreferences(
            defaults: defaults,
            persistentDomainName: suiteName
        )
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
