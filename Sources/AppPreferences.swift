import Foundation

struct AppSettings: Equatable {
    var isEnabled: Bool
    var keepDisplayAwake: Bool
    var presenceHeartbeatEnabled: Bool
    var intervalMinutes: Int
    var scheduleEnabled: Bool
    var scheduleStartMinutes: Int
    var scheduleEndMinutes: Int
    var language: AppLanguage = .defaultLanguage
}

final class AppPreferences {
    private enum Key {
        static let isEnabled = "stayActive.isEnabled"
        static let keepDisplayAwake = "stayActive.keepDisplayAwake"
        static let presenceHeartbeatEnabled = "stayActive.presenceHeartbeatEnabled"
        static let legacySimulateActivity = "stayActive.simulateActivity"
        static let intervalMinutes = "stayActive.intervalMinutes"
        static let scheduleEnabled = "wakePilot.scheduleEnabled"
        static let scheduleStartMinutes = "wakePilot.scheduleStartMinutes"
        static let scheduleEndMinutes = "wakePilot.scheduleEndMinutes"
        static let language = "wakePilot.language"
    }

    private static let legacyBundleIdentifier = "com.bravohex.StayActive"
    private static let persistedSettingKeys = [
        Key.isEnabled,
        Key.keepDisplayAwake,
        Key.presenceHeartbeatEnabled,
        Key.legacySimulateActivity,
        Key.intervalMinutes,
        Key.scheduleEnabled,
        Key.scheduleStartMinutes,
        Key.scheduleEndMinutes,
        Key.language
    ]

    private let defaults: UserDefaults
    private let persistentDomainName: String?
    private let legacyDefaults: UserDefaults?
    private let legacyPersistentDomainName: String?

    static func forCurrentApp() -> AppPreferences {
        AppPreferences(
            defaults: .standard,
            persistentDomainName: Bundle.main.bundleIdentifier,
            legacyDefaults: UserDefaults(suiteName: legacyBundleIdentifier),
            legacyPersistentDomainName: legacyBundleIdentifier
        )
    }

    init(
        defaults: UserDefaults = .standard,
        persistentDomainName: String? = Bundle.main.bundleIdentifier,
        legacyDefaults: UserDefaults? = nil,
        legacyPersistentDomainName: String? = nil
    ) {
        self.defaults = defaults
        self.persistentDomainName = persistentDomainName
        self.legacyDefaults = legacyDefaults
        self.legacyPersistentDomainName = legacyPersistentDomainName
        migrateSettingsFromLegacyBundleIfNeeded()
        migrateLegacyHeartbeatSettingIfNeeded()
        defaults.register(defaults: [
            Key.isEnabled: true,
            Key.keepDisplayAwake: false,
            Key.presenceHeartbeatEnabled: true,
            Key.intervalMinutes: AppConfiguration.defaultPresenceIntervalMinutes,
            Key.scheduleEnabled: false,
            Key.scheduleStartMinutes: AppConfiguration.defaultScheduleStartMinutes,
            Key.scheduleEndMinutes: AppConfiguration.defaultScheduleEndMinutes,
            Key.language: AppLanguage.defaultLanguage.rawValue
        ])
    }

    func load() -> AppSettings {
        let storedInterval = defaults.integer(forKey: Key.intervalMinutes)
        let intervalMinutes = AppConfiguration.normalizedPresenceInterval(storedInterval)

        if storedInterval != intervalMinutes {
            defaults.set(intervalMinutes, forKey: Key.intervalMinutes)
        }

        let storedStartMinutes = defaults.integer(forKey: Key.scheduleStartMinutes)
        let scheduleStartMinutes = AppConfiguration.normalizedScheduleMinute(
            storedStartMinutes,
            defaultValue: AppConfiguration.defaultScheduleStartMinutes
        )
        if storedStartMinutes != scheduleStartMinutes {
            defaults.set(scheduleStartMinutes, forKey: Key.scheduleStartMinutes)
        }

        let storedEndMinutes = defaults.integer(forKey: Key.scheduleEndMinutes)
        let scheduleEndMinutes = AppConfiguration.normalizedScheduleMinute(
            storedEndMinutes,
            defaultValue: AppConfiguration.defaultScheduleEndMinutes
        )
        if storedEndMinutes != scheduleEndMinutes {
            defaults.set(scheduleEndMinutes, forKey: Key.scheduleEndMinutes)
        }

        let language = AppLanguage(
            rawValue: defaults.string(forKey: Key.language) ?? ""
        ) ?? .defaultLanguage

        return AppSettings(
            isEnabled: defaults.bool(forKey: Key.isEnabled),
            keepDisplayAwake: defaults.bool(forKey: Key.keepDisplayAwake),
            presenceHeartbeatEnabled: defaults.bool(forKey: Key.presenceHeartbeatEnabled),
            intervalMinutes: intervalMinutes,
            scheduleEnabled: defaults.bool(forKey: Key.scheduleEnabled),
            scheduleStartMinutes: scheduleStartMinutes,
            scheduleEndMinutes: scheduleEndMinutes,
            language: language
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
        defaults.set(settings.scheduleEnabled, forKey: Key.scheduleEnabled)
        defaults.set(
            AppConfiguration.normalizedScheduleMinute(
                settings.scheduleStartMinutes,
                defaultValue: AppConfiguration.defaultScheduleStartMinutes
            ),
            forKey: Key.scheduleStartMinutes
        )
        defaults.set(
            AppConfiguration.normalizedScheduleMinute(
                settings.scheduleEndMinutes,
                defaultValue: AppConfiguration.defaultScheduleEndMinutes
            ),
            forKey: Key.scheduleEndMinutes
        )
        defaults.set(settings.language.rawValue, forKey: Key.language)
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

    private func migrateSettingsFromLegacyBundleIfNeeded() {
        guard
            !hasPersistedSettings,
            let legacyDefaults,
            let legacyPersistentDomainName,
            let legacyDomain = legacyDefaults.persistentDomain(
                forName: legacyPersistentDomainName
            )
        else {
            return
        }

        for key in Self.persistedSettingKeys {
            guard let value = legacyDomain[key] else {
                continue
            }

            defaults.set(value, forKey: key)
        }
    }

    private var hasPersistedSettings: Bool {
        Self.persistedSettingKeys.contains { persistedValue(forKey: $0) != nil }
    }

    private func persistedValue(forKey key: String) -> Any? {
        guard let persistentDomainName else {
            return nil
        }

        return defaults.persistentDomain(forName: persistentDomainName)?[key]
    }
}
