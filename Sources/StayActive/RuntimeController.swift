import Foundation

struct RuntimeConfiguration: Equatable {
    let isEnabled: Bool
    let keepDisplayAwake: Bool
    let simulateActivity: Bool
    let intervalMinutes: Int
    let hasAccessibilityPermission: Bool
}

@MainActor
protocol RuntimeControlling: AnyObject {
    func apply(
        configuration: RuntimeConfiguration,
        onHeartbeat: @escaping @MainActor () -> Void
    ) -> String?
}

@MainActor
final class RuntimeController: RuntimeControlling {
    private let powerController: PowerAssertionController
    private let activityController: ActivityController

    init() {
        powerController = PowerAssertionController()
        activityController = ActivityController()
    }

    init(
        powerController: PowerAssertionController,
        activityController: ActivityController
    ) {
        self.powerController = powerController
        self.activityController = activityController
    }

    func apply(
        configuration: RuntimeConfiguration,
        onHeartbeat: @escaping @MainActor () -> Void
    ) -> String? {
        let powerError = powerController.update(
            isEnabled: configuration.isEnabled,
            keepDisplayAwake: configuration.keepDisplayAwake
        )

        guard
            configuration.isEnabled,
            configuration.simulateActivity,
            configuration.hasAccessibilityPermission
        else {
            activityController.stop()
            return powerError
        }

        activityController.start(
            intervalMinutes: configuration.intervalMinutes,
            action: onHeartbeat
        )
        return powerError
    }
}
