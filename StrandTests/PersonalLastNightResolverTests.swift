import XCTest
import WhoopStore
@testable import Strand

@MainActor
final class PersonalLastNightResolverTests: XCTestCase {
    private func row(_ day: String, sleep: Double? = nil, hrv: Double? = nil) -> DailyMetric {
        DailyMetric(day: day, totalSleepMin: sleep, efficiency: nil, deepMin: nil,
                    remMin: nil, lightMin: nil, disturbances: nil, restingHr: nil,
                    avgHrv: hrv, recovery: nil, strain: nil, exerciseCount: nil)
    }

    func testBankedSleepWithoutVitalsWinsOverPriorVitals() {
        let today = row("2026-09-28", sleep: 450)
        let prior = row("2026-09-27", sleep: 390, hrv: 62)
        let resolved = CoachContextBuilder.lastNightDay(today: today, fallback: prior)
        XCTAssertEqual(resolved?.day, today.day)
        XCTAssertEqual(resolved?.totalSleepMin, 450)
        XCTAssertNil(resolved?.avgHrv)
        let context = CoachContextBuilder.structuredBlock(days: [prior, today], today: today, lastNight: resolved)
        XCTAssertTrue(context.contains("Last night (2026-09-28):"), context)
        XCTAssertTrue(context.contains("sleep 7.5h"), context)
    }

    func testMissingBankedSleepFallsBackToLastVitals() {
        let today = row("2026-09-28")
        let prior = row("2026-09-27", sleep: 390, hrv: 62)
        XCTAssertEqual(CoachContextBuilder.lastNightDay(today: today, fallback: prior)?.day,
                       prior.day)
    }

    func testNoSleepAndNoPriorVitalsStaysEmpty() {
        XCTAssertNil(CoachContextBuilder.lastNightDay(today: nil, fallback: nil))
    }

    func testTrendWindowsExcludeOldAndFutureRowsInsteadOfCountingRows() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 28, hour: 12))!
        let prior = row("2026-09-16", sleep: 360)
        let today = row("2026-09-28", sleep: 480)
        let context = CoachContextBuilder.structuredBlock(
            days: [row("2026-08-01", sleep: 60), prior, today, row("2026-10-01", sleep: 900)],
            today: today, lastNight: today, now: now)
        XCTAssertTrue(context.contains("sleep 8.0h (baseline 6.0, +2.0h)"), context)
    }
}
