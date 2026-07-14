import Foundation

struct ActivitySchedule: Equatable {
    let isEnabled: Bool
    let startMinutes: Int
    let endMinutes: Int

    init(
        isEnabled: Bool,
        startMinutes: Int,
        endMinutes: Int
    ) {
        self.isEnabled = isEnabled
        self.startMinutes = AppConfiguration.normalizedScheduleMinute(
            startMinutes,
            defaultValue: AppConfiguration.defaultScheduleStartMinutes
        )
        self.endMinutes = AppConfiguration.normalizedScheduleMinute(
            endMinutes,
            defaultValue: AppConfiguration.defaultScheduleEndMinutes
        )
    }

    func isActive(at date: Date, calendar: Calendar = .current) -> Bool {
        guard isEnabled else {
            return true
        }

        let components = calendar.dateComponents([.hour, .minute], from: date)
        let minuteOfDay = (components.hour ?? 0) * 60 + (components.minute ?? 0)

        // A same-time range represents a full day. Users can disable the
        // schedule entirely when they want Wake Pilot to run continuously.
        guard startMinutes != endMinutes else {
            return true
        }

        if startMinutes < endMinutes {
            return minuteOfDay >= startMinutes && minuteOfDay < endMinutes
        }

        // Ranges such as 22:00–06:00 continue into the next day.
        return minuteOfDay >= startMinutes || minuteOfDay < endMinutes
    }

    func nextTransition(after date: Date, calendar: Calendar = .current) -> Date? {
        guard isEnabled, startMinutes != endMinutes else {
            return nil
        }

        let startOfToday = calendar.startOfDay(for: date)
        let transitionMinutes = [startMinutes, endMinutes]

        return (0...2)
            .flatMap { dayOffset -> [Date] in
                guard let day = calendar.date(
                    byAdding: .day,
                    value: dayOffset,
                    to: startOfToday
                ) else {
                    return []
                }

                return transitionMinutes.compactMap {
                    calendar.date(byAdding: .minute, value: $0, to: day)
                }
            }
            .filter { $0 > date }
            .min()
    }
}
