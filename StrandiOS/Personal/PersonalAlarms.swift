#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Personal alarm schedules (personal fork V1)
//
// App-side schedules ON TOP of the strap's single alarm — not a replacement for it.
//
// The hardware fact first: a WHOOP 4.0 strap holds ONE firmware alarm. NOOP arms it through one
// funnel (BehaviorStore's smartAlarm fields → `AppModel.applySmartAlarm()` → `armStrapAlarm`, the
// #535 hardware-confirmed path). This feature deliberately does NOT open a second funnel:
//
//  - WAKE schedules can be COPIED into the strap's single alarm by an explicit user tap
//    ("Arm as strap alarm"), which writes the schedule's time + weekdays into the SAME
//    BehaviorStore fields SmartAlarmView edits and then calls the SAME applySmartAlarm(). One
//    source of truth; nothing to disagree.
//  - REMINDER schedules are app-side only. They fire as strap buzzes through the proven
//    `AppModel.buzz(loops:)` path while the app is alive, quiet-hours-gated, with a local
//    notification fallback for background times. The strap's firmware alarm is the ONLY dependable
//    timed wrist event; the UI says so.
//
// Persistence follows the SmartAlarm idiom (UserDefaults, plain keys, no schema): one JSON array
// under `personal.alarmSchedules`. The key is deliberately NOT in the .noopbak whitelist — these
// schedules are device-local conveniences, and adding a whitelist entry is an Android-parity
// contract change this fork does not make.

/// One app-side schedule.
struct PersonalAlarmSchedule: Codable, Identifiable, Equatable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        /// A wake time — can be copied into the strap's single firmware alarm.
        case wake
        /// An app-side reminder (haptic + notification fallback).
        case reminder

        var label: String {
            switch self {
            case .wake:     return String(localized: "Wake")
            case .reminder: return String(localized: "Reminder")
            }
        }
    }

    var id: UUID = UUID()
    var label: String = ""
    var kind: Kind = .wake
    /// Minutes since local midnight.
    var minuteOfDay: Int = 7 * 60
    /// Calendar weekday numbers (1 = Sun … 7 = Sat); empty = every day. Same convention the smart
    /// alarm's BehaviorStore fields use.
    var weekdays: Set<Int> = []
    /// When set, the schedule fires only on this calendar day (weekdays ignored).
    var oneOffDay: Date? = nil
    var enabled: Bool = true
    /// The haptic pattern a reminder fires (ignored for wake schedules).
    var pattern: PersonalHapticPattern = .reminder

    /// Next strictly-future occurrence, or nil when this schedule will never fire again (a passed
    /// one-off). Repeating schedules resolve through the SAME pure `nextSmartAlarmDate` the smart
    /// alarm arms from, so the two features cannot drift on the calendar math.
    func nextOccurrence(from now: Date = Date(), calendar: Calendar = .current) -> Date? {
        if let day = oneOffDay {
            var comps = calendar.dateComponents([.year, .month, .day], from: day)
            comps.hour = minuteOfDay / 60
            comps.minute = minuteOfDay % 60
            guard let fire = calendar.date(from: comps), fire > now else { return nil }
            return fire
        }
        return AppModel.nextSmartAlarmDate(minutes: minuteOfDay, weekdays: weekdays, from: now,
                                           calendar: calendar)
    }

    /// "Every day" / "Weekdays" / short day list — the same summary the smart alarm's picker shows.
    var weekdaySummary: String { SmartAlarmView.alarmWeekdaySummary(weekdays) }
}

// MARK: - Store

/// Owns the schedule list (UserDefaults-backed, BehaviorStore idiom) and the foreground reminder
/// poller. Shared so the poller outlives the screen.
@MainActor
final class PersonalAlarmStore: ObservableObject {
    static let shared = PersonalAlarmStore()

    private static let storageKey = "personal.alarmSchedules"
    /// De-dup stamp per schedule occurrence, so a poll cadence faster than a minute cannot
    /// double-fire one reminder.
    private static let firedStampPrefix = "personal.alarm.fired."

    @Published private(set) var schedules: [PersonalAlarmSchedule] = [] {
        didSet { persist() }
    }

    private var pollTimer: Timer?
    private weak var model: AppModel?

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([PersonalAlarmSchedule].self, from: data) {
            schedules = decoded
        }
    }

    // MARK: CRUD

    func upsert(_ schedule: PersonalAlarmSchedule) {
        if let idx = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[idx] = schedule
        } else {
            schedules.append(schedule)
        }
        refreshNotificationFallbacks()
    }

    func delete(id: UUID) {
        schedules.removeAll { $0.id == id }
        WristHapticScheduler.cancelNotificationFallback(id: Self.fallbackId(for: id))
        refreshNotificationFallbacks()
    }

    func setEnabled(id: UUID, _ enabled: Bool) {
        guard let idx = schedules.firstIndex(where: { $0.id == id }) else { return }
        schedules[idx].enabled = enabled
        refreshNotificationFallbacks()
    }

    // MARK: Next-up math

    /// The next occurrence across enabled schedules, or nil when nothing is scheduled.
    func nextUpcoming(from now: Date = Date()) -> (schedule: PersonalAlarmSchedule, date: Date)? {
        var best: (PersonalAlarmSchedule, Date)?
        for schedule in schedules where schedule.enabled {
            guard let date = schedule.nextOccurrence(from: now) else { continue }
            if best == nil || date < best!.1 { best = (schedule, date) }
        }
        return best
    }

    // MARK: Strap-side arming (explicit, user-initiated)

    /// Copy a WAKE schedule into the strap's single firmware alarm — through the one existing
    /// funnel: the BehaviorStore fields SmartAlarmView edits, then `applySmartAlarm()` (which arms
    /// the strap and schedules the backup notification). Reversible exactly like SmartAlarmView:
    /// editing or switching the alarm off there changes the same fields. Never called
    /// automatically.
    func armAsStrapAlarm(_ schedule: PersonalAlarmSchedule,
                         behavior: BehaviorStore,
                         model: AppModel) {
        guard schedule.kind == .wake else { return }
        behavior.smartAlarmEnabled = true
        behavior.smartAlarmMinutes = schedule.minuteOfDay
        behavior.smartAlarmWeekdays = schedule.weekdays
        model.applySmartAlarm()
    }

    // MARK: Foreground reminder poller

    /// Attach the model and start the poller. Called when the schedules screen appears; the timer
    /// lives as long as the process does (iOS suspends it with the app — the documented limit).
    /// The block hops to the main actor exactly the way `AppModel.scheduleDailySmartAlarmRearm`'s
    /// timer does.
    func attach(model: AppModel) {
        self.model = model
        guard pollTimer == nil else { return }
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    private func poll() {
        guard let model else { return }
        let now = Date()
        for schedule in schedules where schedule.enabled && schedule.kind == .reminder {
            guard let fire = schedule.nextOccurrence(from: now) else { continue }
            let secondsUntil = fire.timeIntervalSince(now)
            // Fire inside a ±grace window around the occurrence, once per occurrence.
            guard secondsUntil <= 0, now.timeIntervalSince(fire) < 120 else { continue }
            let stampKey = Self.firedStampPrefix + schedule.id.uuidString
            let stamp = "\(Int(fire.timeIntervalSince1970))"
            if UserDefaults.standard.string(forKey: stampKey) == stamp { continue }
            UserDefaults.standard.set(stamp, forKey: stampKey)
            WristHapticScheduler.shared.fireReminder(schedule.pattern, on: model, now: now)
        }
    }

    // MARK: Notification fallbacks

    /// Re-sync the local-notification fallbacks for enabled REMINDER schedules (the phone-side tap
    /// when iOS has the app suspended). Status-only: scheduling silently no-ops when notifications
    /// are not authorized; the UI explains that rather than promising a buzz.
    private func refreshNotificationFallbacks() {
        for schedule in schedules {
            let id = Self.fallbackId(for: schedule.id)
            guard schedule.enabled, schedule.kind == .reminder,
                  let next = schedule.nextOccurrence() else {
                WristHapticScheduler.cancelNotificationFallback(id: id)
                continue
            }
            WristHapticScheduler.scheduleNotificationFallback(
                id: id,
                title: schedule.label.isEmpty ? String(localized: "Reminder") : schedule.label,
                body: String(localized: "Scheduled reminder from NOOP. Open the app to sync and feel it on your wrist."),
                at: next)
        }
    }

    private static func fallbackId(for id: UUID) -> String { "personal-alarm-\(id.uuidString)" }

    private func persist() {
        if let data = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

// MARK: - Screen

/// The app-side schedule manager: what the strap holds, the schedule list + editor, and the
/// explicit app-vs-strap explanation.
struct PersonalAlarmsView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var behavior: BehaviorStore
    @EnvironmentObject private var router: NavRouter
    @ObservedObject private var store = PersonalAlarmStore.shared
    @State private var editorDraft: PersonalAlarmSchedule?

    var body: some View {
        ScreenScaffold(title: "Alarm schedules",
                       subtitle: "App-side schedules alongside your strap's single alarm.") {
            strapCard
            schedulesCard
            footerCard
        }
        .onAppear { store.attach(model: model) }
        .sheet(item: $editorDraft) { draft in
            ScheduleEditorView(draft: draft) { saved in
                store.upsert(saved)
            }
        }
    }

    // MARK: Strap-side card

    /// What the strap is actually armed with — resolved through the same pure function the arm
    /// path uses, so this card cannot disagree with what the strap was told.
    private var strapNext: Date? {
        guard behavior.smartAlarmEnabled else { return nil }
        return AppModel.nextSmartAlarmDate(minutes: behavior.smartAlarmMinutes,
                                           weekdays: behavior.smartAlarmWeekdays,
                                           overrides: WindDownNudge.perDayWakeOverrides)
    }

    private var strapCard: some View {
        NoopCard(padding: NoopMetrics.cardPadding) {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                Text("On the strap").strandOverline()
                if let next = strapNext {
                    Text(Self.stamp(next))
                        .font(StrandFont.number(22))
                        .foregroundStyle(StrandPalette.restColor)
                } else {
                    Text("No strap alarm armed")
                        .font(StrandFont.headline)
                        .foregroundStyle(StrandPalette.textSecondary)
                }
                Text("The strap holds ONE wake alarm. It buzzes from the strap's own firmware, even if your phone is asleep. Edit it in Alarms.")
                    .font(StrandFont.footnote)
                    .foregroundStyle(StrandPalette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    router.openAlarms()
                } label: {
                    Text("Open alarms")
                }
                .buttonStyle(NoopButtonStyle(.secondary, fullWidth: true))
            }
        }
    }

    // MARK: Schedules

    private var schedulesCard: some View {
        VStack(alignment: .leading, spacing: NoopMetrics.gap) {
            SectionHeader("App schedules", overline: "Held by NOOP",
                          trailing: store.schedules.isEmpty ? nil : "\(store.schedules.count)")
            if store.schedules.isEmpty {
                NoopCard(padding: NoopMetrics.cardPadding) {
                    Text("No schedules yet. Add one for wake times you can copy to the strap, or reminders NOOP fires while it's running.")
                        .font(StrandFont.footnote)
                        .foregroundStyle(StrandPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                NoopCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(store.schedules) { schedule in
                            scheduleRow(schedule)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: NoopMetrics.cardRadius, style: .continuous))
                }
            }
            NoopButton("Add schedule", systemImage: "plus",
                       kind: .primary, fullWidth: true) {
                editorDraft = PersonalAlarmSchedule()
            }
        }
    }

    private func scheduleRow(_ schedule: PersonalAlarmSchedule) -> some View {
        let next = schedule.enabled ? schedule.nextOccurrence() : nil
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: schedule.kind == .wake ? "alarm.fill" : "bell.fill")
                    .foregroundStyle(schedule.kind == .wake ? StrandPalette.restColor : StrandPalette.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.label.isEmpty ? schedule.kind.label : schedule.label)
                        .font(StrandFont.headline)
                        .foregroundStyle(StrandPalette.textPrimary)
                    Text(timeLabel(schedule.minuteOfDay) + " · " + dayLabel(schedule))
                        .font(StrandFont.footnote)
                        .foregroundStyle(StrandPalette.textSecondary)
                    if let next {
                        Text("next \(Self.stamp(next))")
                            .font(StrandFont.footnote)
                            .foregroundStyle(StrandPalette.textTertiary)
                    } else if schedule.oneOffDay != nil {
                        Text("passed")
                            .font(StrandFont.footnote)
                            .foregroundStyle(StrandPalette.textTertiary)
                    }
                }
                Spacer(minLength: 0)
                Toggle("", isOn: Binding(
                    get: { schedule.enabled },
                    set: { store.setEnabled(id: schedule.id, $0) }
                ))
                .labelsHidden().toggleStyle(.switch).tint(StrandPalette.accent)
                .accessibilityLabel(Text("Schedule enabled"))
            }
            HStack(spacing: NoopMetrics.gap) {
                if schedule.kind == .wake {
                    Button {
                        store.armAsStrapAlarm(schedule, behavior: behavior, model: model)
                    } label: {
                        Text("Arm as strap alarm")
                    }
                    .buttonStyle(NoopButtonStyle(.secondary, fullWidth: true))
                }
                Button {
                    editorDraft = schedule
                } label: {
                    Text("Edit")
                }
                .buttonStyle(NoopButtonStyle(.secondary, fullWidth: true))
                Button(role: .destructive) {
                    store.delete(id: schedule.id)
                } label: {
                    Text("Delete")
                }
                .buttonStyle(NoopButtonStyle(.secondary, fullWidth: true))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(StrandPalette.hairline)
                .frame(height: 1)
                .padding(.leading, 16)
        }
    }

    private func timeLabel(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    private func dayLabel(_ schedule: PersonalAlarmSchedule) -> String {
        if schedule.oneOffDay != nil {
            let formatter = DateFormatter()
            formatter.locale = AppLanguage.activeLocale
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: schedule.oneOffDay!)
        }
        return schedule.weekdaySummary
    }

    // MARK: Footer

    private var footerCard: some View {
        NoopCard(padding: NoopMetrics.cardPadding) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How this works").strandOverline()
                Text("The strap holds ONE alarm — that's a hardware limit. NOOP holds as many schedules as you like. \"Arm as strap alarm\" copies a wake schedule into the strap's single alarm (the same one the Alarms screen edits). Reminders buzz your wrist only while NOOP is running on your phone — iOS suspends backgrounded apps — and schedule a phone notification as a fallback. Quiet hours silence reminders, never the wake alarm.")
                    .font(StrandFont.footnote)
                    .foregroundStyle(StrandPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private static func stamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.activeLocale
        formatter.setLocalizedDateFormatFromTemplate("EEE d MMM jj:mm")
        return formatter.string(from: date)
    }
}

// MARK: - Editor

/// Add / edit one schedule. A plain draft with a Save button; nothing persists until Save.
private struct ScheduleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    /// The draft being edited (the sheet's item binding already holds a copy).
    let draft: PersonalAlarmSchedule
    let onSave: (PersonalAlarmSchedule) -> Void

    @State private var label: String = ""
    @State private var kind: PersonalAlarmSchedule.Kind = .wake
    @State private var time: Date = Date()
    @State private var weekdays: Set<Int> = []
    @State private var oneOff: Bool = false
    @State private var oneOffDay: Date = Date()
    @State private var pattern: PersonalHapticPattern = .reminder

    /// Monday-first chip order, matching the smart alarm's picker.
    private static let weekdayOrder = [2, 3, 4, 5, 6, 7, 1]

    /// One-letter day chip, derived from the localized short name (the SmartAlarmView picker's
    /// initials idiom; its own helper is file-private, so the fork re-derives the same shape).
    private static func weekdayShort(_ dow: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.activeLocale
        let name = formatter.veryShortWeekdaySymbols.indices.contains(dow - 1)
            ? formatter.veryShortWeekdaySymbols[dow - 1] : "?"
        return String(name.prefix(1))
    }

    /// Full weekday name for accessibility labels (Calendar weekday 1=Sun…7=Sat).
    private static func weekdayName(_ dow: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.activeLocale
        return formatter.weekdaySymbols.indices.contains(dow - 1) ? formatter.weekdaySymbols[dow - 1] : "Day \(dow)"
    }

    var body: some View {
        NavigationStack {
            ScreenScaffold(title: "Schedule") {
                VStack(alignment: .leading, spacing: NoopMetrics.sectionGap) {
                    kindCard
                    timeCard
                    if kind == .reminder { patternCard }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(StrandFont.headline.weight(.semibold))
                }
            }
        }
        .onAppear { seed() }
    }

    private func seed() {
        label = draft.label
        kind = draft.kind
        weekdays = draft.weekdays
        oneOff = draft.oneOffDay != nil
        oneOffDay = draft.oneOffDay ?? Date()
        pattern = draft.pattern
        var comps = DateComponents()
        comps.hour = draft.minuteOfDay / 60
        comps.minute = draft.minuteOfDay % 60
        time = Calendar.current.date(from: comps) ?? Date()
    }

    private var kindCard: some View {
        NoopCard(padding: NoopMetrics.cardPadding) {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                Text("Kind").strandOverline()
                Picker("Kind", selection: $kind) {
                    ForEach(PersonalAlarmSchedule.Kind.allCases) { k in
                        Text(k.label).tag(k)
                    }
                }
                .pickerStyle(.segmented)
                Text(kind == .wake
                     ? "A wake time. Wake schedules can be copied into the strap's single alarm."
                     : "An app-side reminder. NOOP buzzes your wrist while it's running, and posts a phone notification as a fallback when it isn't.")
                    .font(StrandFont.footnote)
                    .foregroundStyle(StrandPalette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                TextField("Label (optional)", text: $label)
                    .font(StrandFont.body)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(StrandPalette.surfaceInset))
            }
        }
    }

    private var timeCard: some View {
        NoopCard(padding: NoopMetrics.cardPadding) {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                Text("When").strandOverline()
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                Toggle("One specific day", isOn: $oneOff)
                if oneOff {
                    DatePicker("Day", selection: $oneOffDay, displayedComponents: .date)
                        .datePickerStyle(.compact)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            ForEach(Self.weekdayOrder, id: \.self) { dow in
                                let selected = SmartAlarmView.alarmWeekdayIsSelected(dow, in: weekdays)
                                Text(Self.weekdayShort(dow))
                                    .font(StrandFont.caption)
                                    .foregroundStyle(selected ? StrandPalette.surfaceBase : StrandPalette.textSecondary)
                                    .frame(width: 30, height: 30)
                                    .background(selected ? StrandPalette.accent : StrandPalette.surfaceInset, in: Circle())
                                    .contentShape(Circle())
                                    .onTapGesture { weekdays = SmartAlarmView.alarmToggledWeekday(dow, in: weekdays) }
                                    .accessibilityLabel(Text(Self.weekdayName(dow)))
                                    .accessibilityAddTraits(selected ? .isSelected : [])
                            }
                        }
                        Text(SmartAlarmView.alarmWeekdaySummary(weekdays))
                            .font(StrandFont.caption)
                            .foregroundStyle(StrandPalette.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var patternCard: some View {
        NoopCard(padding: NoopMetrics.cardPadding) {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                Text("Haptic").strandOverline()
                Picker("Pattern", selection: $pattern) {
                    ForEach([PersonalHapticPattern.reminder, .event, .batteryWarning, .wake]) { p in
                        Text(p.label).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                Text(pattern.detail)
                    .font(StrandFont.footnote)
                    .foregroundStyle(StrandPalette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func save() {
        var saved = draft
        saved.label = label.trimmingCharacters(in: .whitespacesAndNewlines)
        saved.kind = kind
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        saved.minuteOfDay = ((comps.hour ?? 7) * 60) + (comps.minute ?? 0)
        saved.weekdays = oneOff ? [] : weekdays
        saved.oneOffDay = oneOff ? oneOffDay : nil
        saved.pattern = pattern
        saved.enabled = true
        onSave(saved)
        dismiss()
    }
}
#endif
