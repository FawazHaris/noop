#if os(iOS)
import Foundation
import UserNotifications

// MARK: - Wrist haptic scheduler (personal fork V1)
//
// Schedules the fork's app-side reminder haptics. It is honest about what iOS lets a sideloaded
// app do:
//
//  - FOREGROUND (or within the short reconnect window after backgrounding): a scheduled reminder
//    fires on the strap through the proven `AppModel.buzz(loops:)` path. This is the only case a
//    timer can actually reach the strap, because iOS suspends the process — and with it every
//    DispatchWorkItem — moments after backgrounding.
//  - BACKGROUND: the ONLY dependable phone-side channel is a local notification, so the scheduler
//    offers a notification fallback (`scheduleNotificationFallback`). The notification does NOT
//    buzz the strap; it taps the phone. Scheduling one silently no-ops when notifications are not
//    authorized (status-only check — this path never prompts).
//  - The one dependable TIMED WRIST event is the strap's own firmware wake alarm, which the fork
//    continues to arm through the existing Smart Alarm path. Nothing here competes with it.
//
// Quiet hours are respected for every non-wake reminder: the same `notif.quietHours*` keys the
// notification settings own, evaluated against the reminder's local fire time.

/// Schedules and fires the fork's app-side reminder haptics, foreground-first with an honest
/// notification fallback for the background case.
@MainActor
final class WristHapticScheduler {

    static let shared = WristHapticScheduler()

    /// In-flight foreground timer work, keyed by the schedule id so re-scheduling replaces cleanly.
    private var workItems: [UUID: DispatchWorkItem] = [:]
    private static var fallbackRevisions = NotificationFallbackRevisions()

    private init() {}

    // MARK: Quiet hours (pure)

    /// The quiet-hours keys NotificationSettingsStore owns. Read, never written, here.
    private enum QuietKeys {
        static let enabled = "notif.quietHoursEnabled"
        static let start = "notif.quietStartMinutes"
        static let end = "notif.quietEndMinutes"
    }

    /// Whether `date` falls inside the notification quiet-hours window. Pure + injectable clock so
    /// the overnight wrap (22:00–07:00) is testable. Mirrors the engine semantics the
    /// SedentaryDetector applies to its own nudges: the window is evaluated against the event's
    /// LOCAL time, start-inclusive, end-exclusive.
    nonisolated static func inQuietHours(_ date: Date,
                                         calendar: Calendar = .current,
                                         defaults: UserDefaults = .standard) -> Bool {
        guard defaults.object(forKey: QuietKeys.enabled) as? Bool ?? false else { return false }
        let start = defaults.object(forKey: QuietKeys.start) as? Int ?? 22 * 60
        let end = defaults.object(forKey: QuietKeys.end) as? Int ?? 7 * 60
        let minute = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        if start <= end {
            return minute >= start && minute < end
        }
        // Overnight window wraps midnight.
        return minute >= start || minute < end
    }

    // MARK: Fire now

    /// Fire a reminder pattern now, applying the fork's policy gates: the HapticPrefs reminder
    /// gate (default ON) and quiet hours. A long/wake-style reminder is still an app reminder;
    /// only the separate firmware wake alarm bypasses quiet hours.
    func fireReminder(_ pattern: PersonalHapticPattern, on model: AppModel, now: Date = Date()) {
        guard HapticPrefs.enabled(PersonalHapticPattern.reminderGateKey) else { return }
        if Self.inQuietHours(now) { return }
        pattern.fire(on: model)
    }

    // MARK: Foreground scheduling

    /// Schedule a reminder to fire on the strap at `date`, WHILE THE APP IS ALIVE. If the process
    /// is suspended before `date` (the common case on iOS), the work item dies with it — that is
    /// the platform limit, not a bug; pair important times with `scheduleNotificationFallback`
    /// and/or the strap's own wake alarm.
    func scheduleForegroundReminder(id: UUID = UUID(),
                                    _ pattern: PersonalHapticPattern,
                                    at date: Date,
                                    on model: AppModel) {
        cancel(id: id)
        let delay = max(0, date.timeIntervalSinceNow)
        let item = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                self?.fireReminder(pattern, on: model)
                self?.workItems[id] = nil
            }
        }
        workItems[id] = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    /// Cancel a scheduled foreground reminder.
    func cancel(id: UUID) {
        if let item = workItems.removeValue(forKey: id) {
            item.cancel()
        }
    }

    /// Cancel every scheduled foreground reminder (e.g. schedules changed wholesale).
    func cancelAll() {
        for (_, item) in workItems { item.cancel() }
        workItems.removeAll()
    }

    // MARK: Background fallback

    /// Schedule a phone-side local notification as the background fallback for a reminder time.
    /// Status-only authorization check (never prompts — matching the wrist-alert posting rule);
    /// silently no-ops when notifications are off, which is the honest outcome, not a failure.
    static func scheduleNotificationFallback(id: String,
                                             title: String,
                                             body: String,
                                             minuteOfDay: Int,
                                             weekdays: Set<Int>,
                                             oneOffDay: Date?,
                                             next: Date) {
        let center = UNUserNotificationCenter.current()
        let revision = fallbackRevisions.begin(id: id)
        // Clear every previous shape even when authorization has since been revoked.
        let ownedIds = [id] + (1...7).map { "\(id)-w\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ownedIds)
        center.getNotificationSettings { settings in
            let authorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            Task { @MainActor in
                // Edits and cancellation invalidate older asynchronous authorization completions.
                // All add/remove calls are serialized here, never issued by an off-main callback.
                guard fallbackRevisions.isCurrent(id: id, revision: revision), authorized else { return }
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body

                if oneOffDay != nil {
                    let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                                     from: next)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
                    return
                }

                let hour = minuteOfDay / 60
                let minute = minuteOfDay % 60
                let validWeekdays = weekdays.filter { (1...7).contains($0) }

                if weekdays.isEmpty {
                    var components = DateComponents()
                    components.hour = hour
                    components.minute = minute
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                    center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
                    return
                }

                for weekday in validWeekdays {
                    var components = DateComponents()
                    components.weekday = weekday
                    components.hour = hour
                    components.minute = minute
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                    center.add(UNNotificationRequest(identifier: "\(id)-w\(weekday)",
                                                     content: content,
                                                     trigger: trigger))
                }
            }
        }
    }

    /// Remove every pending request shape a schedule can own (one-off/daily base id + weekly ids).
    static func cancelNotificationFallback(id: String) {
        fallbackRevisions.cancel(id: id)
        let ids = [id] + (1...7).map { "\(id)-w\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}
#endif
