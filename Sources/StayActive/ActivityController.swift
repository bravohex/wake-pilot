import Foundation
import IOKit

@MainActor
final class ActivityController {
    private let idleTimeProvider = IdleTimeProvider()
    private var timer: Timer?
    private var configuredIntervalMinutes: Int?
    private var lastHeartbeatAttempt = Date()

    func start(
        intervalMinutes: Int,
        action: @escaping @MainActor () -> Void
    ) {
        let intervalMinutes = AppConfiguration.normalizedPresenceInterval(intervalMinutes)

        guard timer == nil || configuredIntervalMinutes != intervalMinutes else {
            return
        }

        stop()
        configuredIntervalMinutes = intervalMinutes
        lastHeartbeatAttempt = Date()

        scheduleNextCheck(
            after: TimeInterval(intervalMinutes * 60),
            action: action
        )
    }

    private func scheduleNextCheck(
        after delay: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) {
        guard configuredIntervalMinutes != nil else {
            return
        }

        timer?.invalidate()

        let delay = max(1, delay)
        let timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else {
                    return
                }

                self.timer = nil
                self.checkActivity(action: action)
            }
        }
        timer.tolerance = min(max(1, delay * 0.1), 15)

        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func checkActivity(action: @escaping @MainActor () -> Void) {
        guard let intervalMinutes = configuredIntervalMinutes else {
            return
        }

        let intervalSeconds = TimeInterval(intervalMinutes * 60)
        let now = Date()
        let elapsed = max(0, now.timeIntervalSince(lastHeartbeatAttempt))
        let idleSeconds = elapsed >= intervalSeconds
            ? idleTimeProvider.currentIdleSeconds()
            : nil

        if let delay = ActivityTiming.nextCheckDelay(
            intervalSeconds: intervalSeconds,
            elapsedSinceLastAttempt: elapsed,
            idleSeconds: idleSeconds
        ) {
            scheduleNextCheck(after: delay, action: action)
            return
        }

        lastHeartbeatAttempt = now
        action()
        scheduleNextCheck(after: intervalSeconds, action: action)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        configuredIntervalMinutes = nil
    }

    deinit {
        timer?.invalidate()
    }
}

enum ActivityTiming {
    private static let idleReadRetrySeconds: TimeInterval = 60

    static func nextCheckDelay(
        intervalSeconds: TimeInterval,
        elapsedSinceLastAttempt: TimeInterval,
        idleSeconds: TimeInterval?
    ) -> TimeInterval? {
        let intervalSeconds = max(1, intervalSeconds)
        let elapsed = max(0, elapsedSinceLastAttempt)

        if elapsed < intervalSeconds {
            return intervalSeconds - elapsed
        }

        guard let idleSeconds else {
            return min(intervalSeconds, idleReadRetrySeconds)
        }

        let normalizedIdleSeconds = max(0, idleSeconds)
        if normalizedIdleSeconds < intervalSeconds {
            return intervalSeconds - normalizedIdleSeconds
        }

        return nil
    }
}

private final class IdleTimeProvider {
    func currentIdleSeconds() -> TimeInterval? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOHIDSystem")
        )

        guard service != IO_OBJECT_NULL else {
            return nil
        }

        defer {
            IOObjectRelease(service)
        }

        guard let value = IORegistryEntryCreateCFProperty(
            service,
            "HIDIdleTime" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? NSNumber else {
            return nil
        }

        return value.doubleValue / 1_000_000_000
    }
}
