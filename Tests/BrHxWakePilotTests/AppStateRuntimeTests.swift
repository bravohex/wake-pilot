import XCTest
@testable import BrHxWakePilot

@MainActor
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

    func testSurfacesRuntimeErrors() {
        let runtimeController = RecordingRuntimeController(errorMessage: "Power assertion failed")
        let state = AppState(
            preferences: makePreferences(),
            runtimeController: runtimeController
        )

        XCTAssertEqual(state.errorMessage, "Power assertion failed")
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
        onHeartbeat: @escaping @MainActor () -> Void
    ) -> String? {
        configurations.append(configuration)
        return errorMessage
    }
}
