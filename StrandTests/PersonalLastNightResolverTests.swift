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
        let resolved = Repository.lastNightDay(today: today, days: [prior, today])
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
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 28, hour: 12))!
        XCTAssertEqual(Repository.lastNightDay(today: today, days: [prior, today], now: now)?.day,
                       prior.day)
    }

    func testNoSleepAndNoPriorVitalsStaysEmpty() {
        XCTAssertNil(Repository.lastNightDay(today: nil, days: []))
    }
}
