import Foundation

struct AppSettings: Equatable {
    var isEnabled: Bool
    var keepDisplayAwake: Bool
    var presenceHeartbeatEnabled: Bool
    var intervalMinutes: Int
}

final class AppPreferences {
    private enum Key {
        static let isEnabled = "stayActive.isEnabled"
        static let keepDisplayAwake = "stayActive.keepDisplayAwake"
        static let presenceHeartbeatEnabled = "stayActive.presenceHeartbeatEnabled"
        static let legacySimulateActivity = "stayActive.simulateActivity"
        static let intervalMinutes = "stayActive.intervalMinutes"
    }

    private let defaults: UserDefaults
    private let persistentDomainName: String?

    init(
        defaults: UserDefaults = .standard,
        persistentDomainName: String? = Bundle.main.bundleIdentifier
    ) {
        self.defaults = defaults
        self.persistentDomainName = persistentDomainName
        migrateLegacyHeartbeatSettingIfNeeded()
        defaults.register(defaults: [
            Key.isEnabled: true,
            Key.keepDisplayAwake: false,
            Key.presenceHeartbeatEnabled: true,
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
            presenceHeartbeatEnabled: defaults.bool(forKey: Key.presenceHeartbeatEnabled),
            intervalMinutes: intervalMinutes
        )
    }

    func save(_ settings: AppSettings) {
        defaults.set(settings.isEnabled, forKey: Key.isEnabled)
        defaults.set(settings.keepDisplayAwake, forKey: Key.keepDisplayAwake)
        defaults.set(
            settings.presenceHeartbeatEnabled,
            forKey: Key.presenceHeartbeatEnabled
        )
        defaults.set(
            AppConfiguration.normalizedPresenceInterval(settings.intervalMinutes),
            forKey: Key.intervalMinutes
        )
    }

    private func migrateLegacyHeartbeatSettingIfNeeded() {
        guard persistedValue(forKey: Key.presenceHeartbeatEnabled) == nil else {
            return
        }

        guard let legacyValue = persistedValue(forKey: Key.legacySimulateActivity) as? NSNumber else {
            return
        }

        defaults.set(
            legacyValue.boolValue,
            forKey: Key.presenceHeartbeatEnabled
        )
        defaults.removeObject(forKey: Key.legacySimulateActivity)
    }

    private func persistedValue(forKey key: String) -> Any? {
        guard let persistentDomainName else {
            return nil
        }

        return defaults.persistentDomain(forName: persistentDomainName)?[key]
    }
}
