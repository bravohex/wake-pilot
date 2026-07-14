import Foundation

enum AppConfiguration {
    static let presenceIntervalOptions = [1, 2, 3, 4, 5, 10, 15]
    static let defaultPresenceIntervalMinutes = 3
    static let defaultScheduleStartMinutes = 9 * 60
    static let defaultScheduleEndMinutes = 18 * 60

    static func normalizedPresenceInterval(_ value: Int) -> Int {
        presenceIntervalOptions.contains(value)
            ? value
            : defaultPresenceIntervalMinutes
    }

    static func normalizedScheduleMinute(_ value: Int, defaultValue: Int) -> Int {
        (0..<(24 * 60)).contains(value) ? value : defaultValue
    }
}
