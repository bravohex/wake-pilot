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
        static let isEnabled = "wakePilot.isEnabled"
        static let keepDisplayAwake = "wakePilot.keepDisplayAwake"
        static let presenceHeartbeatEnabled = "wakePilot.presenceHeartbeatEnabled"
        static let intervalMinutes = "wakePilot.intervalMinutes"
        static let scheduleEnabled = "wakePilot.scheduleEnabled"
        static let scheduleStartMinutes = "wakePilot.scheduleStartMinutes"
        static let scheduleEndMinutes = "wakePilot.scheduleEndMinutes"
        static let language = "wakePilot.language"
    }

    private let defaults: UserDefaults

    static func forCurrentApp() -> AppPreferences {
        AppPreferences(
            defaults: .standard
        )
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
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

}
