import XCTest
@testable import WakePilot

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

    func testNormalizesInvalidScheduleMinute() {
        XCTAssertEqual(
            AppConfiguration.normalizedScheduleMinute(-1, defaultValue: 540),
            540
        )
    }

    func testFormatsMarketingVersionWithBuildNumber() {
        XCTAssertEqual(
            AppConfiguration.formattedVersion(
                marketingVersion: "0.1.0",
                buildNumber: "1"
            ),
            "0.1.0 (1)"
        )
    }
}

final class ActivityScheduleTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testDisabledScheduleIsAlwaysActive() {
        let schedule = ActivitySchedule(
            isEnabled: false,
            startMinutes: 9 * 60,
            endMinutes: 18 * 60
        )

        XCTAssertTrue(schedule.isActive(at: date(hour: 3, minute: 30), calendar: calendar))
        XCTAssertNil(schedule.nextTransition(after: date(hour: 3, minute: 30), calendar: calendar))
    }

    func testDaytimeRangeIncludesStartAndExcludesEnd() {
        let schedule = ActivitySchedule(
            isEnabled: true,
            startMinutes: 9 * 60,
            endMinutes: 18 * 60
        )

        XCTAssertFalse(schedule.isActive(at: date(hour: 8, minute: 59), calendar: calendar))
        XCTAssertTrue(schedule.isActive(at: date(hour: 9, minute: 0), calendar: calendar))
        XCTAssertTrue(schedule.isActive(at: date(hour: 17, minute: 59), calendar: calendar))
        XCTAssertFalse(schedule.isActive(at: date(hour: 18, minute: 0), calendar: calendar))
    }

    func testOvernightRangeIsActiveAcrossMidnight() {
        let schedule = ActivitySchedule(
            isEnabled: true,
            startMinutes: 22 * 60,
            endMinutes: 6 * 60
        )

        XCTAssertFalse(schedule.isActive(at: date(hour: 21, minute: 59), calendar: calendar))
        XCTAssertTrue(schedule.isActive(at: date(hour: 22, minute: 0), calendar: calendar))
        XCTAssertTrue(schedule.isActive(at: date(hour: 1, minute: 0), calendar: calendar))
        XCTAssertFalse(schedule.isActive(at: date(hour: 6, minute: 0), calendar: calendar))
    }

    func testSameStartAndEndMeansAllDay() {
        let schedule = ActivitySchedule(
            isEnabled: true,
            startMinutes: 9 * 60,
            endMinutes: 9 * 60
        )

        XCTAssertTrue(schedule.isActive(at: date(hour: 2, minute: 0), calendar: calendar))
        XCTAssertNil(schedule.nextTransition(after: date(hour: 2, minute: 0), calendar: calendar))
    }

    func testFindsNextTransition() {
        let schedule = ActivitySchedule(
            isEnabled: true,
            startMinutes: 9 * 60,
            endMinutes: 18 * 60
        )

        XCTAssertEqual(
            schedule.nextTransition(after: date(hour: 12, minute: 30), calendar: calendar),
            date(hour: 18, minute: 0)
        )
        XCTAssertEqual(
            schedule.nextTransition(after: date(hour: 19, minute: 0), calendar: calendar),
            date(day: 2, hour: 9, minute: 0)
        )
    }

    private func date(day: Int = 1, hour: Int, minute: Int) -> Date {
        calendar.date(
            from: DateComponents(
                calendar: calendar,
                timeZone: calendar.timeZone,
                year: 2026,
                month: 7,
                day: day,
                hour: hour,
                minute: minute
            )
        )!
    }
}
