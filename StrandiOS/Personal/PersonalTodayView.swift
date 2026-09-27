#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Personal Today (personal fork V1)
//
// The fork's glanceable Today dashboard. It COMPOSES existing surfaces rather than replacing them:
// every number is read from the same stores the classic Today reads (`Repository` for scored days,
// `LiveState` for the live link), the alarm countdown resolves through the SAME pure function
// (`AppModel.nextSmartAlarmDate`) `applySmartAlarm` arms the strap from, and every action routes to
// an existing entry point (BLEManager.syncNow / buzzStrapOnce, NavRouter.openCoach / openAlarms).
//
// Layout follows the upstream conventions: ScreenScaffold chrome, NoopCard surfaces, StrandFont /
// StrandPalette / NoopMetrics tokens only. The live-link pieces live in small LEAF subviews that
// each observe `LiveState` on their own, so the ~1 Hz heart-rate tick never re-evaluates the whole
// dashboard (the same split TodayView documents at its `live` note).
//
// The screen is selected by `RootTabView` when `noop.personalTodayEnabled` is on (the fork default),
// ahead of the liquid / classic layouts. The header's layout menu writes that same key, so a wearer
// can always fall back without digging through Settings.

/// The personal glance dashboard: YOU NOW (live), TODAY, LAST NIGHT, NEXT, quick actions.
struct PersonalTodayView: View {
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var behavior: BehaviorStore
    @EnvironmentObject private var router: NavRouter

    /// Layout selectors, writing the same keys RootTabView reads. Defaults mirror the fork's
    /// Today default (personal first).
    @AppStorage("noop.personalTodayEnabled") private var personalToday = true
    @AppStorage("noop.liquidTodayEnabled") private var liquidToday = true

    /// Today's row, by the device's logical day — the same resolver the classic Today uses.
    private var displayDay: DailyMetric? { repo.today }
    /// The freshest strictly-prior row with overnight vitals, for the honest "still yesterday's
    /// numbers" carry-over when today hasn't scored yet.
    private var vitalsDay: DailyMetric? { Repository.lastVitalsDay(days: repo.days) }

    var body: some View {
        ScreenScaffold(title: nil, onRefresh: { await repo.refresh() }) {
            header
            GuardianStatusBanner()
            LiveNowCard()
            todaySection
            lastNightSection
            NextAlarmCard(behavior: behavior, model: model, router: router)
            quickActions
            honestFooter
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today").font(StrandFont.rounded(28)).foregroundStyle(StrandPalette.textPrimary)
                Text(Date(), style: .date)
                    .font(StrandFont.subhead)
                    .foregroundStyle(StrandPalette.textSecondary)
            }
            Spacer(minLength: 0)
            layoutMenu
        }
    }

    /// Fall back to the upstream layouts without a Settings trip. Writes the same keys the tab
    /// shell reads, so the swap is instant and survives relaunch.
    private var layoutMenu: some View {
        Menu {
            Button {
                personalToday = true
            } label: {
                Label("Personal glance", systemImage: personalToday ? "checkmark" : "")
            }
            Button {
                personalToday = false
                liquidToday = true
            } label: {
                Label("Liquid layout", systemImage: !personalToday && liquidToday ? "checkmark" : "")
            }
            Button {
                personalToday = false
                liquidToday = false
            } label: {
                Label("Classic layout", systemImage: !personalToday && !liquidToday ? "checkmark" : "")
            }
        } label: {
            Image(systemName: "rectangle.2.group")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(StrandPalette.textSecondary)
                .frame(width: NoopMetrics.compactControlSize, height: NoopMetrics.compactControlSize)
                .background(Circle().fill(StrandPalette.surfaceInset))
        }
        .accessibilityLabel(Text("Today layout"))
    }

    // MARK: TODAY

    /// Today's four glance numbers. A value that hasn't been scored yet falls back to the last
    /// vitals day and says so — never a bare blank pretending nothing exists.
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: NoopMetrics.gap) {
            SectionHeader("Today", overline: "Your day so far",
                          trailing: carryCaption)
            NoopCard(padding: NoopMetrics.cardPadding) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: NoopMetrics.gap),
                                    GridItem(.flexible(), spacing: NoopMetrics.gap)],
                          spacing: NoopMetrics.gap) {
                    glanceTile(label: "Recovery", value: recoveryText,
                               tint: StrandPalette.chargeColor)
                    glanceTile(label: "Strain", value: strainText,
                               tint: StrandPalette.effortColor)
                    glanceTile(label: "HRV", value: hrvText,
                               tint: StrandPalette.restColor)
                    glanceTile(label: "Resting HR", value: rhrText,
                               tint: StrandPalette.restBright)
                }
            }
        }
    }

    /// "yesterday" when the tiles are reading the prior day's numbers (today's row not scored yet).
    private var carryCaption: String? {
        guard displayDay == nil, vitalsDay != nil else { return nil }
        return String(localized: "yesterday")
    }

    private var recoveryText: String {
        value(displayDay?.recovery, fallback: vitalsDay?.recovery) { "\(Int($0.rounded()))" } ?? "—"
    }
    private var strainText: String {
        value(displayDay?.strain, fallback: vitalsDay?.strain) { String(format: "%.1f", $0) } ?? "—"
    }
    private var hrvText: String {
        value(displayDay?.avgHrv, fallback: vitalsDay?.avgHrv) { "\(Int($0.rounded())) ms" } ?? "—"
    }
    private var rhrText: String {
        value(displayDay?.restingHr.map(Double.init),
              fallback: vitalsDay?.restingHr.map(Double.init)) { "\(Int($0.rounded())) bpm" } ?? "—"
    }

    /// Today-first with an honest fallback to the last vitals day.
    private func value<T>(_ today: T?, fallback: T?, format: (T) -> String) -> String? {
        if let today { return format(today) }
        if let fallback { return format(fallback) }
        return nil
    }

    private func glanceTile(label: LocalizedStringKey, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).strandOverline()
            Text(value)
                .font(StrandFont.number(24))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: NoopMetrics.cardRadius * 0.7, style: .continuous)
                        .fill(StrandPalette.surfaceInset))
    }

    // MARK: LAST NIGHT

    private var lastNightSection: some View {
        VStack(alignment: .leading, spacing: NoopMetrics.gap) {
            SectionHeader("Last night", overline: "Sleep",
                          trailing: sleepConfidenceCaption)
            NoopCard(padding: NoopMetrics.cardPadding) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: NoopMetrics.gap),
                                    GridItem(.flexible(), spacing: NoopMetrics.gap)],
                          spacing: NoopMetrics.gap) {
                    glanceTile(label: "Duration", value: sleepDurationText,
                               tint: StrandPalette.restColor)
                    glanceTile(label: "Efficiency", value: efficiencyText,
                               tint: StrandPalette.restColor)
                    glanceTile(label: "RHR", value: nightRhrText,
                               tint: StrandPalette.restBright)
                    glanceTile(label: "Respiration", value: respirationText,
                               tint: StrandPalette.restBright)
                }
            }
        }
    }

    /// The night the LAST NIGHT tiles describe: today's row when it has a banked night, else the
    /// last vitals day. One resolver, so the tiles and the caption cannot disagree.
    private var lastNightRow: DailyMetric? {
        if let d = displayDay, d.totalSleepMin != nil { return d }
        return vitalsDay
    }

    private var sleepDurationText: String {
        guard let minutes = lastNightRow?.totalSleepMin else { return "—" }
        let h = Int(minutes) / 60, m = Int(minutes) % 60
        return String(localized: "\(h)h \(m)m")
    }

    /// Efficiency is not reliably a 0–1 fraction (some import paths store a percentage), so the
    /// value is normalised with the same >1.5 split the Coach context builder and SleepView use.
    private var efficiencyText: String {
        guard var e = lastNightRow?.efficiency, e > 0 else { return "—" }
        if e > 1.5 { e /= 100 }
        guard e > 0, e <= 1 else { return "—" }
        return "\(Int((e * 100).rounded()))%"
    }

    private var nightRhrText: String {
        lastNightRow?.restingHr.map { "\($0) bpm" } ?? "—"
    }

    private var respirationText: String {
        lastNightRow?.respRateBpm.map { String(format: "%.1f /min", $0) } ?? "—"
    }

    /// The honest confidence note: `sleepHrOnly` marks a night staged from heart rate alone
    /// (no motion), which is exactly the case where the staging deserves a caveat.
    private var sleepConfidenceCaption: String? {
        guard let hrOnly = lastNightRow?.sleepHrOnly, hrOnly else { return nil }
        return String(localized: "staged from HR only")
    }

    // MARK: Quick actions

    /// Four taps, each routed to an existing entry point. "Ask Coach" is guarded by the shell on
    /// the master switch (RootTabView drops the request when Coach is off — the honest no-op).
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: NoopMetrics.gap) {
            SectionHeader("Quick actions", overline: "One tap away")
            VStack(spacing: NoopMetrics.gap) {
                HStack(spacing: NoopMetrics.gap) {
                    quickButton("Ask Coach", icon: "sparkles", tint: StrandPalette.accent) {
                        router.openCoach()
                    }
                    QuickSyncButton()
                }
                HStack(spacing: NoopMetrics.gap) {
                    quickButton("Buzz strap", icon: "waveform.path", tint: StrandPalette.metricRose) {
                        model.buzzStrapOnce()
                    }
                    quickButton("Alarms", icon: "alarm.fill", tint: StrandPalette.restColor) {
                        router.openAlarms()
                    }
                }
            }
        }
    }

    private func quickButton(_ title: LocalizedStringKey, icon: String, tint: Color,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(StrandFont.headline)
                    .foregroundStyle(StrandPalette.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 46, alignment: .leading)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: NoopMetrics.cardRadius * 0.7, style: .continuous)
                            .fill(StrandPalette.surfaceInset))
            .overlay(RoundedRectangle(cornerRadius: NoopMetrics.cardRadius * 0.7, style: .continuous)
                        .strokeBorder(tint.opacity(0.25), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var honestFooter: some View {
        Text("Numbers come from your synced strap history. Live readings need a connected strap; the layout menu switches back to NOOP's built-in layouts.")
            .font(StrandFont.footnote)
            .foregroundStyle(StrandPalette.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Live "YOU NOW" card (leaf: observes LiveState)

/// The live half of the dashboard: big heart rate, connection pill, battery, and the honest
/// "as of" staleness line. A leaf so the ~1 Hz live tick re-renders only this card.
private struct LiveNowCard: View {
    @EnvironmentObject private var live: LiveState

    private var state: GuardianState {
        ConnectionGuardian.resolve(ConnectionGuardian.Snapshot(live: live))
    }

    /// The active device's charge, resolved through the one cross-source readout so a ring's
    /// battery can never appear under a strap heading (the #2075 lesson).
    private var batteryPercent: Int? {
        LiveConsoleReadout.batteryPercent(activeIsWhoop: live.activeIsWhoop,
                                          whoopPct: live.batteryPct,
                                          ringPct: live.ouraBatteryPct)
    }

    var body: some View {
        NoopCard(padding: NoopMetrics.cardPadding) {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                Text("You now").strandOverline()
                TimelineView(.periodic(from: .now, by: 15)) { tick in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        if let bpm = live.heartRate {
                            Text("\(bpm)")
                                .font(StrandFont.number(64))
                                .foregroundStyle(StrandPalette.liquidHeart)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        } else {
                            Text("--")
                                .font(StrandFont.number(64))
                                .foregroundStyle(StrandPalette.textTertiary)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("bpm")
                                .font(StrandFont.overline)
                                .foregroundStyle(StrandPalette.textTertiary)
                            Text(state.shortLabel)
                                .font(StrandFont.footnote)
                                .foregroundStyle(StrandPalette.textSecondary)
                            stalenessLine(now: tick.date)
                        }
                        Spacer(minLength: 0)
                        batteryBadge
                    }
                }
                if live.backfilling {
                    SyncingHistoryNote(chunks: live.syncChunksThisSession)
                }
            }
        }
    }

    /// Honest stream age, off the frame timestamp LiveState already stamps per routed frame.
    @ViewBuilder private func stalenessLine(now: Date) -> some View {
        if let frame = live.lastFrameAtUnix {
            let age = max(0, Int(now.timeIntervalSince1970) - frame)
            Text("as of \(age) s ago")
                .font(StrandFont.footnote)
                .foregroundStyle(StrandPalette.textTertiary)
        } else {
            Text("no frame yet this session")
                .font(StrandFont.footnote)
                .foregroundStyle(StrandPalette.textTertiary)
        }
    }

    @ViewBuilder private var batteryBadge: some View {
        if let pct = batteryPercent {
            HStack(spacing: 6) {
                Image(systemName: live.charging == true ? "bolt.fill" : "battery.75")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(pct <= 20 ? StrandPalette.statusWarning : StrandPalette.textSecondary)
                    .accessibilityHidden(true)
                Text("\(pct)%")
                    .font(StrandFont.headline)
                    .foregroundStyle(pct <= 20 ? StrandPalette.statusWarning : StrandPalette.textPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(StrandPalette.surfaceInset))
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Next alarm card (plain values passed in, self-ticking countdown)

/// The NEXT block: when the strap alarm will next buzz, resolved through the same pure
/// `nextSmartAlarmDate` the arm path uses, so the countdown cannot drift from the strap.
private struct NextAlarmCard: View {
    let behavior: BehaviorStore
    let model: AppModel
    let router: NavRouter

    /// Whether switching the alarm on actually arms anything (the #864 5/MG gate, mirrored from
    /// SmartAlarmView so the fork's countdown makes no promise the strap can't keep).
    private var strapAlarmWillArm: Bool {
        !(model.whoop5Detected && !PuffinExperiment.isEnabled)
    }

    private var nextAlarm: Date? {
        guard behavior.smartAlarmEnabled, strapAlarmWillArm else { return nil }
        return AppModel.nextSmartAlarmDate(minutes: behavior.smartAlarmMinutes,
                                           weekdays: behavior.smartAlarmWeekdays,
                                           overrides: WindDownNudge.perDayWakeOverrides)
    }

    var body: some View {
        NoopCard(padding: NoopMetrics.cardPadding, tint: nextAlarm != nil ? StrandPalette.restColor : nil) {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                Text("Next").strandOverline()
                if let next = nextAlarm {
                    TimelineView(.periodic(from: .now, by: 60)) { tick in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Self.countdown(to: next, from: tick.date))
                                .font(StrandFont.number(22))
                                .foregroundStyle(StrandPalette.accent)
                            Text(Self.stamp(next))
                                .font(StrandFont.footnote)
                                .foregroundStyle(StrandPalette.textSecondary)
                        }
                    }
                    Text("Strap wake-alarm. It buzzes from the strap's own firmware, even if your phone is asleep.")
                        .font(StrandFont.footnote)
                        .foregroundStyle(StrandPalette.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No strap alarm armed")
                        .font(StrandFont.headline)
                        .foregroundStyle(StrandPalette.textSecondary)
                    Text("The strap holds one wake alarm. Set it under Alarms.")
                        .font(StrandFont.footnote)
                        .foregroundStyle(StrandPalette.textTertiary)
                }
                Button {
                    router.openAlarms()
                } label: {
                    Text("Open alarms")
                }
                .buttonStyle(NoopButtonStyle(.secondary, fullWidth: true))
            }
        }
    }

    /// "Alarm in 18 hours, 6 minutes" — `DateComponentsFormatter` so the unit words localise.
    static func countdown(to date: Date, from now: Date) -> String {
        let seconds = date.timeIntervalSince(now)
        if seconds < 60 { return String(localized: "Alarm in less than a minute") }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.zeroFormattingBehavior = .dropAll
        formatter.maximumUnitCount = 3
        guard let span = formatter.string(from: seconds), !span.isEmpty else {
            return String(localized: "Alarm soon")
        }
        return String(localized: "Alarm in \(span)")
    }

    /// The absolute companion ("Mon 21 Sep 10:28"), from the reader's locale + clock format —
    /// the same template SmartAlarmView pairs with its countdown.
    static func stamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.activeLocale
        formatter.setLocalizedDateFormatFromTemplate("EEE d MMM jj:mm")
        return formatter.string(from: date)
    }
}

// MARK: - Sync quick button (leaf: observes LiveState for the gate + progress)

/// The Sync action, gated exactly like HealthView's "Sync now" (connected + bonded +
/// historyReady + not already syncing), showing the honest in-progress state while it runs.
private struct QuickSyncButton: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var live: LiveState

    private var canSync: Bool {
        live.connected && live.bonded && live.historyReady && !live.backfilling
    }

    var body: some View {
        Button {
            model.ble.syncNow()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(StrandPalette.accent)
                Text(live.backfilling ? "Syncing…" : "Sync strap")
                    .font(StrandFont.headline)
                    .foregroundStyle(canSync || live.backfilling ? StrandPalette.textPrimary : StrandPalette.textTertiary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 46, alignment: .leading)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: NoopMetrics.cardRadius * 0.7, style: .continuous)
                            .fill(StrandPalette.surfaceInset))
            .overlay(RoundedRectangle(cornerRadius: NoopMetrics.cardRadius * 0.7, style: .continuous)
                        .strokeBorder(StrandPalette.accent.opacity(0.25), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canSync)
        .accessibilityLabel(Text("Sync strap now"))
        .accessibilityHint(Text(canSync
            ? "Pulls your strap's stored history immediately."
            : "Connect and pair your strap first."))
    }
}
#endif
