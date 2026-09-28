import Foundation
import WhoopStore

// MARK: - Coach structured context (personal fork V1)
//
// A compact STRUCTURED block (TODAY / LAST NIGHT / 7-DAY TRENDS with deviations) appended to the
// coach context. It rides the exact same consent-gated, summary-only text channel as
// `AICoachEngine.buildContext()` — no new data leaves the device, no raw readings, no new consent.
//
// Pure and side-effect-free on purpose: `days` in, text out, `now` injectable, so the formatting
// and the deviation math are testable without a store, a strap, or a clock (the same seam
// `AICoachEngine.dayLine` gives the day-line summary).
//
// Cross-platform (Foundation + WhoopStore only), so the macOS coach gets the same block.

/// Builds the structured coach context block from cached daily metrics.
enum CoachContextBuilder {

    /// Shared with Personal Today: today's banked sleep wins even without vitals. Resolve the
    /// canonical prior-vitals fallback only when today's row has no sleep.
    static func lastNightDay(today: DailyMetric?, fallback: @autoclosure () -> DailyMetric?) -> DailyMetric? {
        if let today, today.totalSleepMin != nil { return today }
        return fallback()
    }

    /// The structured block, or an empty string when there is nothing to summarise (the day-line
    /// summary in `buildContext()` already covers the no-data case; this never duplicates it).
    static func structuredBlock(days: [DailyMetric],
                                today: DailyMetric?,
                                lastNight: DailyMetric?,
                                now: Date = Date()) -> String {
        guard !days.isEmpty else { return "" }
        var lines: [String] = ["STRUCTURED SUMMARY (personal fork):"]

        // TODAY — the current day's own row, honest about what isn't scored yet.
        lines.append("Today (\(today?.day ?? dayKey(now))):")
        lines.append("  charge " + (today?.recovery.map { "\(Int($0.rounded()))/100" } ?? "— not scored yet")
                    + ", effort " + (today?.strain.map { String(format: "%.1f/100", $0) } ?? "—"))
        if let hrOnly = today?.sleepHrOnly, hrOnly {
            lines.append("  (today's sleep staging came from heart rate alone — no motion signal)")
        }

        // LAST NIGHT — the freshest night with vitals (today's banked night when it has one).
        if let night = lastNight {
            lines.append("Last night (\(night.day)):")
            var parts: [String] = []
            if let mins = night.totalSleepMin { parts.append(String(format: "sleep %.1fh", mins / 60)) }
            parts.append("efficiency " + efficiencyPercent(night.efficiency))
            if let hrv = night.avgHrv { parts.append("HRV \(Int(hrv.rounded())) ms") }
            if let rhr = night.restingHr { parts.append("RHR \(rhr) bpm") }
            if let resp = night.respRateBpm { parts.append(String(format: "respiration %.1f/min", resp)) }
            lines.append("  " + parts.joined(separator: ", "))
        }

        // 7-DAY TRENDS — this week vs the week before, stated as deviations from the user's own
        // baseline. Never a bare number without its reference.
        // Calendar windows, not row counts: sparse history must not call a months-old row
        // "last week", and future-dated imports must not leak into today's comparison.
        let calendar = Calendar.current
        let end = dayKey(now)
        let recentStart = dayKey(calendar.date(byAdding: .day, value: -6, to: now) ?? now)
        let priorStart = dayKey(calendar.date(byAdding: .day, value: -13, to: now) ?? now)
        let recent = days.filter { $0.day >= recentStart && $0.day <= end }
        let prior = days.filter { $0.day >= priorStart && $0.day < recentStart }
        lines.append("7-day trends (vs the prior 7 days):")
        lines.append("  " + trend(recent: recent, prior: prior, label: "charge",
                                   value: { $0.recovery }, format: { "\(Int($0.rounded()))" }, unit: "/100"))
        lines.append("  " + trend(recent: recent, prior: prior, label: "effort",
                                   value: { $0.strain }, format: { String(format: "%.1f", $0) }, unit: "/100"))
        lines.append("  " + trend(recent: recent, prior: prior, label: "sleep",
                                   value: { $0.totalSleepMin.map { $0 / 60 } }, format: { String(format: "%.1f", $0) }, unit: "h"))
        lines.append("  " + trend(recent: recent, prior: prior, label: "HRV",
                                   value: { $0.avgHrv }, format: { "\(Int($0.rounded()))" }, unit: " ms"))
        lines.append("  " + trend(recent: recent, prior: prior, label: "RHR",
                                   value: { $0.restingHr.map(Double.init) }, format: { "\(Int($0.rounded()))" }, unit: " bpm"))

        return lines.joined(separator: "\n")
    }

    // MARK: Helpers

    /// One trend line: "<label> <recent-mean> <unit> (baseline <prior-mean>, <signed diff>)", or
    /// an honest "<label>: not enough data yet" when either window lacks the metric.
    private static func trend(recent: [DailyMetric], prior: [DailyMetric],
                              label: String, value: (DailyMetric) -> Double?,
                              format: (Double) -> String, unit: String) -> String {
        guard let recentMean = mean(recent.map(value)),
              let priorMean = mean(prior.map(value)) else {
            return "\(label): not enough data yet"
        }
        let diff = recentMean - priorMean
        let sign = diff >= 0 ? "+" : "-"
        return "\(label) \(format(recentMean))\(unit) (baseline \(format(priorMean)), \(sign)\(format(abs(diff)))\(unit))"
    }

    /// Mean of the non-nil values, nil when there are none.
    private static func mean(_ xs: [Double?]) -> Double? {
        let values = xs.compactMap { $0 }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Efficiency as a percentage, NORMALISING the stored value with the same >1.5 split
    /// `AICoachEngine.efficiencyPercentOrDash` applies (the stored field is a fraction on some
    /// paths and a percentage on others).
    private static func efficiencyPercent(_ raw: Double?) -> String {
        guard var e = raw, e > 0 else { return "—" }
        if e > 1.5 { e /= 100 }
        guard e > 0, e <= 1 else { return "—" }
        return "\(Int((e * 100).rounded()))%"
    }

    private static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
