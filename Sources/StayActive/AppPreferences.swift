import Foundation

struct AppSettings: Equatable {
    var isEnabled: Bool
    var keepDisplayAwake: Bool
    var simulateActivity: Bool
    var intervalMinutes: Int
}

final class AppPreferences {
    private enum Key {
        static let isEnabled = "stayActive.isEnabled"
        static let keepDisplayAwake = "stayActive.keepDisplayAwake"
        static let simulateActivity = "stayActive.simulateActivity"
        static let intervalMinutes = "stayActive.intervalMinutes"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.isEnabled: true,
            Key.keepDisplayAwake: false,
            Key.simulateActivity: true,
            Key.intervalMinutes: AppConfiguration.defaultPresenceIntervalMinutes
        ])
    }

    func load() -> AppSettings {
        let storedInterval = defaults.integer(forKey: Key.intervalMinutes)
        let intervalMinutes = AppConfiguration.normalizedPresenceInterval(storedInterval)

        if storedInterval != intervalMinutes {
            defaults.set(intervalMinutes, forKey: Key.intervalMinutes)
        }

        return AppSettings(
            isEnabled: defaults.bool(forKey: Key.isEnabled),
            keepDisplayAwake: defaults.bool(forKey: Key.keepDisplayAwake),
            simulateActivity: defaults.bool(forKey: Key.simulateActivity),
            intervalMinutes: intervalMinutes
        )
    }

    func save(_ settings: AppSettings) {
        defaults.set(settings.isEnabled, forKey: Key.isEnabled)
        defaults.set(settings.keepDisplayAwake, forKey: Key.keepDisplayAwake)
        defaults.set(settings.simulateActivity, forKey: Key.simulateActivity)
        defaults.set(
            AppConfiguration.normalizedPresenceInterval(settings.intervalMinutes),
            forKey: Key.intervalMinutes
        )
    }
}
