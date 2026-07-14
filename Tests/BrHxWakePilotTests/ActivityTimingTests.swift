import XCTest
@testable import BrHxWakePilot

final class ActivityTimingTests: XCTestCase {
    func testWaitsUntilConfiguredCadence() {
        let delay = ActivityTiming.nextCheckDelay(
            intervalSeconds: 60,
            elapsedSinceLastAttempt: 25,
            idleSeconds: nil
        )

        XCTAssertEqual(delay, 35)
    }

    func testWaitsUntilUserHasBeenIdleForFullInterval() {
        let delay = ActivityTiming.nextCheckDelay(
            intervalSeconds: 60,
            elapsedSinceLastAttempt: 90,
            idleSeconds: 15
        )

        XCTAssertEqual(delay, 45)
    }

    func testRetriesConservativelyWhenIdleTimeIsUnavailable() {
        let delay = ActivityTiming.nextCheckDelay(
            intervalSeconds: 300,
            elapsedSinceLastAttempt: 300,
            idleSeconds: nil
        )

        XCTAssertEqual(delay, 60)
    }

    func testEmitsOnlyAfterCadenceAndIdleThresholdsAreMet() {
        let delay = ActivityTiming.nextCheckDelay(
            intervalSeconds: 60,
            elapsedSinceLastAttempt: 60,
            idleSeconds: 60
        )

        XCTAssertNil(delay)
    }
}

final class AppConfigurationTests: XCTestCase {
    func testAcceptsSupportedPresenceInterval() {
        XCTAssertEqual(AppConfiguration.normalizedPresenceInterval(10), 10)
    }

    func testFallsBackForUnsupportedPresenceInterval() {
        XCTAssertEqual(
            AppConfiguration.normalizedPresenceInterval(Int.max),
            AppConfiguration.defaultPresenceIntervalMinutes
        )
    }
}
