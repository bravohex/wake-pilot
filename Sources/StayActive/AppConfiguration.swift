import Foundation

enum AppConfiguration {
    static let presenceIntervalOptions = [1, 2, 3, 4, 5, 10, 15]
    static let defaultPresenceIntervalMinutes = 3

    static func normalizedPresenceInterval(_ value: Int) -> Int {
        presenceIntervalOptions.contains(value)
            ? value
            : defaultPresenceIntervalMinutes
    }
}
