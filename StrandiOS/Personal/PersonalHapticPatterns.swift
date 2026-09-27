#if os(iOS)
import Foundation

// MARK: - Personal haptic patterns (personal fork V1)
//
// Named haptic presets for the fork's personal surfaces (Wrist screen, app-side reminder
// schedules). They map onto the EXISTING, hardware-proven buzz paths only:
//  - `AppModel.buzz(loops:)` — the graduated pattern (patternId 2) whose loop-count semantics are
//    confirmed on-device (cmd 19 maverick form on 5/MG, preset form on 4.0; see BLEManager.send);
//  - `AppModel.buzzStrapOnce()` — the acked one-shot sequence every user-facing "buzz now" uses
//    (#921).
// No new opcodes, no speculative payloads: the loop COUNT is the only variable, and every value
// below is one a shipped surface already uses (BuzzPattern single/double/triple/long = 1/2/3/5).

/// The fork's four haptic presets, distinguishable by feel. Codable (raw value) so reminder
/// schedules can persist their pattern.
enum PersonalHapticPattern: String, CaseIterable, Identifiable, Codable {
    /// One short buzz — a gentle reminder ("stand up", "wind down soon").
    case reminder
    /// Two short buzzes — something happened (a schedule fired, an event marker).
    case event
    /// Three short buzzes — a warning (low strap battery and friends).
    case batteryWarning
    /// One long train — the wake-style buzz. NOTE: this is the *test* form; the dependable wake is
    /// the strap's own firmware alarm (`AppModel.applySmartAlarm` → `armStrapAlarm`), which fires
    /// even with the phone asleep. This preset only exists so the pattern family can be felt.
    case wake

    var id: String { rawValue }

    /// Repeat count handed to the proven graduated buzz. Matches the shipped `BuzzPattern` loop
    /// values (single 1 / double 2 / triple 3 / long 5) so nothing here invents a new duration.
    var loops: UInt8 {
        switch self {
        case .reminder:       return 1
        case .event:          return 2
        case .batteryWarning: return 3
        case .wake:           return 5
        }
    }

    /// Short glance label.
    var label: String {
        switch self {
        case .reminder:       return String(localized: "Reminder (1 short)")
        case .event:          return String(localized: "Event (2 short)")
        case .batteryWarning: return String(localized: "Battery warning (3 short)")
        case .wake:           return String(localized: "Wake (long)")
        }
    }

    /// One honest line about what it is and when the fork uses it.
    var detail: String {
        switch self {
        case .reminder:
            return String(localized: "One light buzz. Used by app-side reminders; silenced inside quiet hours.")
        case .event:
            return String(localized: "Two short buzzes. Marks an event you asked to feel.")
        case .batteryWarning:
            return String(localized: "Three short buzzes. The warning pattern.")
        case .wake:
            return String(localized: "A long train, the wake-style buzz. Your real wake is the strap's own alarm, which fires even if this phone is asleep.")
        }
    }

    /// The HapticPrefs gate key for the fork's reminder haptics. `HapticPrefs.enabled(_:)` works
    /// for any key (default ON), so this needs no change to the shipped prefs type. The gate (and
    /// quiet hours) are applied by `WristHapticScheduler` — this type is the pattern DEFINITION.
    static let reminderGateKey = "haptics.personalReminders"

    /// Fire this pattern through the proven graduated-buzz path (the ambient-cue form, ungated —
    /// gating is the scheduler's policy). No-op on an unbonded link: the command characteristic is
    /// bond-gated, exactly like every other scheduled cue.
    func fire(on model: AppModel) {
        model.buzz(loops: loops)
    }

    /// The user-facing "test this pattern" path — the acked one-shot sequence, matching every other
    /// user-facing buzz button.
    func testFire(on model: AppModel) {
        model.buzzStrapOnce()
    }
}
#endif
