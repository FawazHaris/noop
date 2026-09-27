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
    /// gate (default ON) and quiet hours. Wake-class patterns bypass quiet hours — a wake the
    /// window silenced would be a wake that lied.
    func fireReminder(_ pattern: PersonalHapticPattern, on model: AppModel, now: Date = Date()) {
        guard HapticPrefs.enabled(PersonalHapticPattern.reminderGateKey) else { return }
        if pattern != .wake, Self.inQuietHours(now) { return }
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
                                             at date: Date) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                             from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    /// Remove a previously scheduled fallback notification.
    static func cancelNotificationFallback(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
#endif
