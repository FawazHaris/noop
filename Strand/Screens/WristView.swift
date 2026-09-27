import SwiftUI
import StrandDesign

// MARK: - Wrist screen (personal fork V1)
//
// One phone surface for "how is the thing on my wrist doing": the link-status chain, the device
// card, the live stream, the sync state, and the proven actions (buzz / sync / reconnect), plus
// the alarms + quiet-hours summary. It WRAPS existing surfaces only:
//  - every fact is read from `LiveState` (the single funnel BLEManager/FrameRouter write);
//  - "Bonded" means `encryptedBond`, exactly as `LiveState.connectionStatusLabel` defines it;
//  - the alarm summary resolves through the same pure `AppModel.nextSmartAlarmDate` the arm path
//    uses, so it cannot disagree with what the strap was told;
//  - quiet hours read the same `notif.quietHours*` keys NotificationSettingsStore owns.
//
// NO protocol logs, no probes: those stay behind their existing Test Centre gates.
//
// Cross-platform (StrandDesign + shared app types only). Reached on iOS via More → Wrist
// (`MoreDestination.wrist`) and the "Show wrist status" shortcut; macOS keeps its Devices screen.

/// The wrist status screen.
struct WristView: View {
    @EnvironmentObject private var live: LiveState
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var behavior: BehaviorStore
    @EnvironmentObject private var router: NavRouter

    var body: some View {
        ScreenScaffold(title: "Wrist",
                       subtitle: "Your strap's link, stream and sync, at a glance.",
                       onRefresh: { await model.repo.refresh() }) {
            GuardianStatusBanner()
            statusChainCard
            deviceCard
            streamCard
            syncCard
            actionsCard
            alarmsCard
            quietHoursCard
            honestFooter
        }
    }

    // MARK: Status chain

    /// The five-step link chain, each step naming one fact LiveState actually carries. Steps that
    /// are true fill in accent; unknown/pending stay tertiary. Nothing here is derived twice.
    private var statusChainCard: some View {
        NoopCard(padding: NoopMetrics.cardPadding) {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                Text("Link").strandOverline()
                HStack(spacing: 0) {
                    chainStep("Connected", done: live.connected)
                    chainStep("Bonded", done: live.encryptedBond)
                    chainStep("On wrist", done: live.worn)
                    chainStep("Streaming", done: live.heartRate != nil)
                    chainStep("Synced", done: live.lastSyncedAt != nil)
                }
                Text("Bonded means an encrypted pairing — the channel the strap needs for buzzes, alarms and history. On wrist defaults to true until the strap reports otherwise.")
                    .font(StrandFont.footnote)
                    .foregroundStyle(StrandPalette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func chainStep(_ label: LocalizedStringKey, done: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(done ? StrandPalette.statusPositive : StrandPalette.textTertiary)
                .accessibilityHidden(true)
            Text(label)
                .font(StrandFont.overlineScaled(9))
                .foregroundStyle(done ? StrandPalette.textSecondary : StrandPalette.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(done ? String(localized: "yes") : String(localized: "not yet")))
    }

    // MARK: Device card

    private var deviceCard: some View {
        NoopCard(padding: NoopMetrics.cardPadding) {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                Text("Device").strandOverline()
                HStack(spacing: 12) {
                    Image(systemName: "watch.fill")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(StrandPalette.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(deviceName)
                            .font(StrandFont.headline)
                            .foregroundStyle(StrandPalette.textPrimary)
                        Text(firmwareLine)
                            .font(StrandFont.footnote)
                            .foregroundStyle(StrandPalette.textSecondary)
                    }
                    Spacer(minLength: 0)
                    batteryBadge
                }
            }
        }
    }

    /// The strap's advertised name when the firmware has replied with one; otherwise the honest
    /// generic label rather than a guess.
    private var deviceName: String {
        if let name = live.advertisingName, !name.isEmpty { return name }
        return String(localized: "WHOOP strap")
    }

    private var firmwareLine: String {
        if let fw = live.strapFirmware {
            return String(localized: "Firmware \(fw)")
        }
        return String(localized: "Firmware: not reported yet this session")
    }

    /// The active device's charge through the one cross-source readout (never the strap's number
    /// under a ring heading), plus the strap's voltage when a battery event carried it.
    private var batteryPercent: Int? {
        LiveConsoleReadout.batteryPercent(activeIsWhoop: live.activeIsWhoop,
                                          whoopPct: live.batteryPct,
                                          ringPct: live.ouraBatteryPct)
    }

    @ViewBuilder private var batteryBadge: some View {
        if let pct = batteryPercent {
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: live.charging == true ? "bolt.fill" : "battery.75")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(pct <= 20 ? StrandPalette.statusWarning : StrandPalette.textSecondary)
                        .accessibilityHidden(true)
                    Text("\(pct)%")
                        .font(StrandFont.number(22))
                        .foregroundStyle(pct <= 20 ? StrandPalette.statusWarning : StrandPalette.textPrimary)
                }
                if live.charging == true {
                    Text("Charging")
                        .font(StrandFont.footnote)
                        .foregroundStyle(StrandPalette.statusPositive)
                } else if let mv = live.batteryMv {
                    Text(String(format: "%.2f V", Double(mv) / 1000))
                        .font(StrandFont.footnote)
                        .foregroundStyle(StrandPalette.textTertiary)
                }
            }
        }
    }

    // MARK: Streaming card

    private var streamCard: some View {
        NoopCard(padding: NoopMetrics.cardPadding) {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                Text("Live stream").strandOverline()
                TimelineView(.periodic(from: .now, by: 5)) { tick in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        if let bpm = live.heartRate {
                            Text("\(bpm)")
                                .font(StrandFont.number(36))
                                .foregroundStyle(StrandPalette.liquidHeart)
                            Text("bpm")
                                .font(StrandFont.overline)
                                .foregroundStyle(StrandPalette.textTertiary)
                        } else {
                            Text("--")
                                .font(StrandFont.number(36))
                                .foregroundStyle(StrandPalette.textTertiary)
                            Text("bpm")
                                .font(StrandFont.overline)
                                .foregroundStyle(StrandPalette.textTertiary)
                        }
                        Spacer(minLength: 0)
                        frameAgeLine(now: tick.date)
                    }
                }
            }
        }
    }

    /// Frame freshness off the timestamp LiveState stamps per routed frame (#987). It is not
    /// @Published, so the card re-reads it on the timeline tick above — the same cadence the Test
    /// Centre readout uses.
    @ViewBuilder private func frameAgeLine(now: Date) -> some View {
        if let frame = live.lastFrameAtUnix {
            let age = max(0, Int(now.timeIntervalSince1970) - frame)
            Text("last frame \(age) s ago")
                .font(StrandFont.footnote)
                .foregroundStyle(age > 60 ? StrandPalette.statusWarning : StrandPalette.textTertiary)
        } else {
            Text("no frame yet this session")
                .font(StrandFont.footnote)
                .foregroundStyle(StrandPalette.textTertiary)
        }
    }

    // MARK: Sync card

    private var syncCard: some View {
        NoopCard(padding: NoopMetrics.cardPadding) {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                Text("Sync").strandOverline()
                if live.backfilling {
                    SyncingHistoryNote(chunks: live.syncChunksThisSession)
                } else if let last = live.lastSyncedAt {
                    HStack(spacing: 8) {
                        StatePill("History synced", tone: .positive)
                        Text(relativeAgo(last))
                            .font(StrandFont.footnote)
                            .foregroundStyle(StrandPalette.textSecondary)
                    }
                } else {
                    StatePill("No completed offload yet", tone: .neutral, showsDot: false)
                }
                if let err = live.lastSyncError, !err.isEmpty {
                    Text(err)
                        .font(StrandFont.footnote)
                        .foregroundStyle(StrandPalette.statusWarning)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: Actions

    /// The three proven actions. Buzz routes through the confirmed one-shot sequence (#921); sync
    /// through the gated engine entry; reconnect through the explicit user Connect path.
    private var actionsCard: some View {
        NoopCard(padding: NoopMetrics.cardPadding) {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                Text("Actions").strandOverline()
                NoopButton("Test buzz", systemImage: "waveform.path",
                           kind: .secondary, fullWidth: true) {
                    model.buzzStrapOnce()
                }
                .disabled(!live.connected)
                NoopButton(live.backfilling ? "Syncing…" : "Sync now", systemImage: "arrow.triangle.2.circlepath",
                           kind: .secondary, fullWidth: true) {
                    model.ble.syncNow()
                }
                .disabled(!canSync)
                NoopButton("Reconnect", systemImage: "antenna.radiowaves.left.and.right",
                           kind: .secondary, fullWidth: true) {
                    model.ble.connect()
                }
                .disabled(live.connected)
            }
        }
    }

    /// Matches BLEManager.syncNow's own gate (the HealthView "Sync now" idiom).
    private var canSync: Bool {
        live.connected && live.bonded && live.historyReady && !live.backfilling
    }

    // MARK: Alarms summary

    /// What the strap is actually armed with, resolved through the same pure function the arm path
    /// uses — never a second derivation of the same fact.
    private var nextAlarm: Date? {
        guard behavior.smartAlarmEnabled else { return nil }
        return AppModel.nextSmartAlarmDate(minutes: behavior.smartAlarmMinutes,
                                           weekdays: behavior.smartAlarmWeekdays,
                                           overrides: WindDownNudge.perDayWakeOverrides)
    }

    private var alarmsCard: some View {
        NoopCard(padding: NoopMetrics.cardPadding) {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                Text("Alarms").strandOverline()
                if let next = nextAlarm {
                    HStack(spacing: 8) {
                        Image(systemName: "alarm.fill")
                            .foregroundStyle(StrandPalette.restColor)
                            .accessibilityHidden(true)
                        Text(alarmStamp(next))
                            .font(StrandFont.headline)
                            .foregroundStyle(StrandPalette.textPrimary)
                    }
                    Text("The strap holds ONE wake alarm; NOOP arms it from your alarm settings and re-arms it daily.")
                        .font(StrandFont.footnote)
                        .foregroundStyle(StrandPalette.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No strap alarm armed")
                        .font(StrandFont.headline)
                        .foregroundStyle(StrandPalette.textSecondary)
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

    private func alarmStamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.activeLocale
        formatter.setLocalizedDateFormatFromTemplate("EEEE jj:mm")
        return formatter.string(from: date)
    }

    // MARK: Quiet hours

    /// Reads the SAME keys NotificationSettingsStore owns (`notif.quietHours*`) — no second source
    /// of truth. Non-wake haptic reminders respect this window; the wake alarm never does (a wake
    /// alarm that quiet hours silenced would be an alarm that lied).
    private var quietHoursCard: some View {
        NoopCard(padding: NoopMetrics.cardPadding) {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                Text("Quiet hours").strandOverline()
                HStack(spacing: 8) {
                    StatePill(quietOn ? "On" : "Off",
                              tone: quietOn ? .positive : .neutral, showsDot: false)
                    Text(quietWindowLabel)
                        .font(StrandFont.footnote)
                        .foregroundStyle(StrandPalette.textSecondary)
                }
                Text("Reminder buzzes stay silent inside this window. The strap wake-alarm always fires.")
                    .font(StrandFont.footnote)
                    .foregroundStyle(StrandPalette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var quietOn: Bool {
        UserDefaults.standard.object(forKey: "notif.quietHoursEnabled") as? Bool ?? false
    }

    private var quietWindowLabel: String {
        let start = UserDefaults.standard.object(forKey: "notif.quietStartMinutes") as? Int ?? 22 * 60
        let end = UserDefaults.standard.object(forKey: "notif.quietEndMinutes") as? Int ?? 7 * 60
        return String(format: "%02d:%02d – %02d:%02d", start / 60, start % 60, end / 60, end % 60)
    }

    private var honestFooter: some View {
        Text("Everything here is read-only: NOOP reports what the strap says. Protocol-level diagnostics stay behind the Test Centre gate.")
            .font(StrandFont.footnote)
            .foregroundStyle(StrandPalette.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Shared guardian banner

/// One banner naming the current connection state, shown only when there is something to say (the
/// healthy state stays silent — no chrome for the good case). Shared by the personal Today glance
/// and the Wrist screen so the two cannot diagnose the same link differently.
struct GuardianStatusBanner: View {
    @EnvironmentObject private var live: LiveState
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var router: NavRouter

    private var state: GuardianState {
        ConnectionGuardian.resolve(ConnectionGuardian.Snapshot(live: live))
    }

    var body: some View {
        if state.severity != .healthy {
            NoopCard(padding: 16, tint: tint) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .foregroundStyle(tint)
                            .accessibilityHidden(true)
                        Text(state.title)
                            .font(StrandFont.headline)
                            .foregroundStyle(StrandPalette.textPrimary)
                    }
                    Text(state.message)
                        .font(StrandFont.footnote)
                        .foregroundStyle(StrandPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(state.actions, id: \.self) { action in
                        Button {
                            run(action)
                        } label: {
                            Text(label(for: action))
                        }
                        .buttonStyle(NoopButtonStyle(.secondary, fullWidth: true))
                    }
                }
            }
        }
    }

    private var tint: Color {
        switch state.severity {
        case .healthy, .info:    return StrandPalette.accent
        case .attention:         return StrandPalette.statusWarning
        case .warning:           return StrandPalette.statusCritical
        }
    }

    private var icon: String {
        switch state.severity {
        case .healthy, .info:    return "antenna.radiowaves.left.and.right"
        case .attention:         return "exclamationmark.triangle"
        case .warning:           return "exclamationmark.triangle.fill"
        }
    }

    private func label(for action: GuardianAction) -> String {
        switch action {
        case .reconnect:   return String(localized: "Reconnect strap")
        case .refresh:     return String(localized: "Refresh data")
        case .openDevices: return String(localized: "Open Devices")
        }
    }

    /// Recovery actions map onto existing entry points only.
    private func run(_ action: GuardianAction) {
        switch action {
        case .reconnect:   model.ble.connect()
        case .refresh:     Task { await model.repo.refresh() }
        case .openDevices: router.openDevices()
        }
    }
}
