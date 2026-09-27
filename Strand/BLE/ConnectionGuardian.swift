import Foundation

// MARK: - Connection Guardian (personal fork V1)
//
// A PURE, read-only observer over the live-connection surfaces that already exist. It maps the
// facts `LiveState` publishes into one named, user-facing state, so the personal Today glance and
// the Wrist screen can show ONE honest banner instead of each re-deriving (and drifting on) the
// same diagnosis.
//
// Rules it obeys (AGENTS.md):
//  - "A diagnostic may only assert what it can attribute": every state below names only facts
//    LiveState actually carries. It never guesses WHY a link dropped; it reports what was seen.
//  - "Two readouts of one fact must not disagree": connected / bonded / encryptedBond /
//    lastFrameAtUnix / lastSyncedAt / lastSyncError are read from LiveState — the single funnel
//    BLEManager and FrameRouter already write — and nothing here writes anything back.
//  - It observes; it never commands. Recovery actions are SUGGESTIONS the host view maps onto
//    existing entry points (BLEManager.connect / Repository.refresh / NavRouter.openDevices).
//
// Cross-platform on purpose (Foundation only): the same states can back a future macOS banner.

/// How serious a guardian state is, so hosts can tint without inventing their own scale.
enum GuardianSeverity {
    /// Everything the wearer asked for is flowing.
    case healthy
    /// Working as intended, but transient (a reconnect in flight, a sync running).
    case info
    /// Usable but degraded — worth a glance, not an alarm.
    case attention
    /// Nothing is flowing; action is needed.
    case warning
}

/// The recovery affordances that make sense for a state. The host view decides what each does;
/// they deliberately map onto existing entry points only, never new commands.
enum GuardianAction {
    /// Ask the BLE engine for a fresh connect attempt (`BLEManager.connect()`).
    case reconnect
    /// Re-read the local caches (`Repository.refresh()`).
    case refresh
    /// Open the Devices manager (`NavRouter.openDevices()`).
    case openDevices
}

/// One named connection state, with user-readable copy attached.
enum GuardianState: Equatable {
    /// Connected with a live heart-rate sample that arrived recently.
    case healthyStream
    /// Connected, but no readable live sample for a while (`secondsSinceFrame` = age of the last
    /// routed frame; nil when no frame arrived this session at all).
    case staleHr(secondsSinceFrame: Int?)
    /// Connected, but the last completed history sync is old (`hoursAgo`), or the engine surfaced
    /// a sync error (`message`, surfaced verbatim from `LiveState.lastSyncError`).
    case staleSync(hoursAgo: Int?, message: String?)
    /// The link is down and a user-initiated reboot is reconnecting (the "Reconnecting…" fact
    /// DevicesView reads: `rebootInProgress && !connected`).
    case connecting
    /// Previously bonded, currently not connected (LiveState's "Bonded · idle").
    case bondedIdle
    /// Not connected, nothing more specific known.
    case disconnected
    /// Bluetooth radio is off. Detected through the surface `BLEManager.centralManagerDidUpdateState`
    /// already publishes for exactly this fact: it writes a "Bluetooth is off…" message into
    /// `LiveState.lastSyncError` (the #280 single funnel for radio-state guidance).
    case bluetoothUnavailable

    /// Short glance label (pills, compact chrome).
    var shortLabel: String {
        switch self {
        case .healthyStream:          return String(localized: "Streaming")
        case .staleHr:                return String(localized: "Connected, no live reading")
        case .staleSync:              return String(localized: "Sync due")
        case .connecting:             return String(localized: "Reconnecting…")
        case .bondedIdle:             return String(localized: "Paired, offline")
        case .disconnected:           return String(localized: "Disconnected")
        case .bluetoothUnavailable:   return String(localized: "Bluetooth off")
        }
    }

    /// The headline for the banner / card.
    var title: String {
        switch self {
        case .healthyStream:          return String(localized: "Live and streaming")
        case .staleHr:                return String(localized: "Connected, but no live heart rate")
        case .staleSync(let h, let message):
            if let message, !message.isEmpty { return message }
            if let h { return String(localized: "Last strap sync was \(h) h ago") }
            return String(localized: "Strap hasn't synced yet")
        case .connecting:             return String(localized: "Reconnecting…")
        case .bondedIdle:             return String(localized: "Paired, not connected")
        case .disconnected:           return String(localized: "Strap not connected")
        case .bluetoothUnavailable:   return String(localized: "Bluetooth is off")
        }
    }

    /// One or two sentences of plain guidance. Only names what the state can attribute.
    var message: String {
        switch self {
        case .healthyStream:
            return String(localized: "Your strap is connected and live heart rate is flowing.")
        case .staleHr(let seconds):
            if let seconds {
                return String(localized: "The link is up, but no readable sample has arrived for about \(seconds) s. Reconnect usually clears this.")
            }
            return String(localized: "The link is up, but no readable sample has arrived yet this session. Reconnect usually clears this.")
        case .staleSync(let hours, let message):
            if let message, !message.isEmpty {
                return String(localized: "The strap link reported a sync problem: \(message)")
            }
            if let hours {
                return String(localized: "Connected, but the last completed history sync was about \(hours) h ago. Open the Wrist screen and sync to catch up.")
            }
            return String(localized: "Connected, but no history sync has completed yet. Open the Wrist screen and sync to catch up.")
        case .connecting:
            return String(localized: "The strap is coming back after a restart. This usually settles on its own.")
        case .bondedIdle:
            return String(localized: "Your strap is paired but the link is down. Reconnect, or open Devices to pair again.")
        case .disconnected:
            return String(localized: "No strap link. Reconnect, or open Devices to pair your strap.")
        case .bluetoothUnavailable:
            return String(localized: "Turn Bluetooth on in Settings to connect to your strap.")
        }
    }

    var severity: GuardianSeverity {
        switch self {
        case .healthyStream: return .healthy
        case .connecting:    return .info
        case .staleHr, .staleSync, .bondedIdle: return .attention
        case .disconnected, .bluetoothUnavailable: return .warning
        }
    }

    var actions: [GuardianAction] {
        switch self {
        case .healthyStream:          return []
        case .staleHr:                return [.reconnect, .openDevices]
        case .staleSync:              return [.refresh]
        case .connecting:             return [.refresh]
        case .bondedIdle:             return [.reconnect, .openDevices]
        case .disconnected:           return [.reconnect, .openDevices]
        case .bluetoothUnavailable:   return [.openDevices]
        }
    }
}

/// The pure resolver. `Snapshot` exists so the mapping is testable without a strap, a LiveState,
/// or a clock — views build the snapshot from the LiveState they already observe.
enum ConnectionGuardian {

    /// How long the last routed frame may stand before a connected link reads "no live reading".
    /// LiveState itself blanks the heart rate after `LiveState.heartRateSilenceSeconds` (10 s); the
    /// guardian is deliberately more patient (a minute) so brief gaps don't page the wearer.
    static let staleFrameSeconds: Int = 60

    /// A connected strap whose last completed sync is older than this reads "sync due" (a night's
    /// data should land well inside 26 h on any wearing pattern).
    static let staleSyncHours: Int = 26

    /// The verbatim prefix BLEManager writes into `LiveState.lastSyncError` when the radio is off
    /// (Strand/BLE/BLEManager.swift, `centralManagerDidUpdateState`, case .poweredOff). Matching it
    /// keeps this observer read-only: it consumes the surface the engine already publishes rather
    /// than reaching into CoreBluetooth state itself.
    static let bluetoothOffErrorPrefix = "Bluetooth is off"

    /// One honest read of the live surfaces. All fields are plain values so the struct is Equatable,
    /// testable, and carries no references into the BLE layer.
    struct Snapshot: Equatable {
        var connected = false
        var encryptedBond = false
        var bonded = false
        var heartRate: Int? = nil
        var lastFrameAtUnix: Int? = nil
        var lastSyncedAt: TimeInterval? = nil
        var lastSyncError: String? = nil
        var backfilling = false
        var rebootInProgress = false

        init() {}

        /// Built from the LiveState a host view already observes. `@MainActor` because LiveState is.
        @MainActor init(live: LiveState) {
            connected = live.connected
            encryptedBond = live.encryptedBond
            bonded = live.bonded
            heartRate = live.heartRate
            lastFrameAtUnix = live.lastFrameAtUnix
            lastSyncedAt = live.lastSyncedAt
            lastSyncError = live.lastSyncError
            backfilling = live.backfilling
            rebootInProgress = live.rebootInProgress
        }
    }

    /// Map a snapshot to the single worst honest state, most specific first. Pure; `now` injectable.
    static func resolve(_ s: Snapshot, now: Date = Date()) -> GuardianState {
        // Radio-off is reported by the engine through lastSyncError's dedicated message; it is the
        // most specific fact and the one whose fix lives outside the app (iOS Settings).
        if !s.connected,
           let err = s.lastSyncError, err.hasPrefix(Self.bluetoothOffErrorPrefix) {
            return .bluetoothUnavailable
        }
        // A user-initiated reboot keeps its own "Reconnecting…" pill (DevicesView does the same).
        if !s.connected && s.rebootInProgress { return .connecting }
        if !s.connected {
            return (s.encryptedBond || s.bonded) ? .bondedIdle : .disconnected
        }
        // Connected: a surfaced sync problem beats a staleness estimate (it is attributed, the
        // estimate is derived). A sync in progress is NOT a problem — it is the fix running.
        if !s.backfilling, let err = s.lastSyncError, !err.isEmpty {
            return .staleSync(hoursAgo: nil, message: err)
        }
        if !s.backfilling, let synced = s.lastSyncedAt {
            let hoursAgo = Int(now.timeIntervalSince1970 - synced) / 3600
            if hoursAgo >= Self.staleSyncHours {
                return .staleSync(hoursAgo: hoursAgo, message: nil)
            }
        }
        // Live-sample freshness: the strap clears its own heart rate after 10 s of silence, so a nil
        // heart rate on a live link is itself the honest "no readable sample" signal.
        if s.heartRate == nil { return .staleHr(secondsSinceFrame: nil) }
        if let frame = s.lastFrameAtUnix {
            let age = Int(now.timeIntervalSince1970) - frame
            if age > Self.staleFrameSeconds { return .staleHr(secondsSinceFrame: age) }
        }
        return .healthyStream
    }
}
