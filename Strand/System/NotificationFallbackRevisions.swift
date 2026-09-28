import Foundation

/// Reject delayed notification-authorization callbacks after a schedule is edited or cancelled.
/// Owned by the scheduler on the main actor; pure so ordering is testable without notifications.
struct NotificationFallbackRevisions {
    private var revisions: [String: UUID] = [:]

    mutating func begin(id: String) -> UUID {
        let revision = UUID()
        revisions[id] = revision
        return revision
    }

    func isCurrent(id: String, revision: UUID) -> Bool { revisions[id] == revision }

    mutating func cancel(id: String) { revisions.removeValue(forKey: id) }
}
