import Foundation

struct RuntimeConfiguration: Equatable {
    let isEnabled: Bool
    let keepDisplayAwake: Bool
    let presenceHeartbeatEnabled: Bool
    let intervalMinutes: Int
    let hasAccessibilityPermission: Bool
    let language: AppLanguage

    init(
        isEnabled: Bool,
        keepDisplayAwake: Bool,
        presenceHeartbeatEnabled: Bool,
        intervalMinutes: Int,
        hasAccessibilityPermission: Bool,
        language: AppLanguage = .defaultLanguage
    ) {
        self.isEnabled = isEnabled
        self.keepDisplayAwake = keepDisplayAwake
        self.presenceHeartbeatEnabled = presenceHeartbeatEnabled
        self.intervalMinutes = intervalMinutes
        self.hasAccessibilityPermission = hasAccessibilityPermission
        self.language = language
    }
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
            keepDisplayAwake: configuration.keepDisplayAwake,
            language: configuration.language
        )

        guard
            configuration.isEnabled,
            configuration.presenceHeartbeatEnabled,
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
