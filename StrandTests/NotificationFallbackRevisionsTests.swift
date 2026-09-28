import XCTest
@testable import Strand

final class NotificationFallbackRevisionsTests: XCTestCase {
    func testCancellationInvalidatesDelayedCallback() {
        var revisions = NotificationFallbackRevisions()
        let old = revisions.begin(id: "reminder")
        revisions.cancel(id: "reminder")
        XCTAssertFalse(revisions.isCurrent(id: "reminder", revision: old))
    }

    func testOnlyNewestEditCanSchedule() {
        var revisions = NotificationFallbackRevisions()
        let old = revisions.begin(id: "reminder")
        let latest = revisions.begin(id: "reminder")
        XCTAssertFalse(revisions.isCurrent(id: "reminder", revision: old))
        XCTAssertTrue(revisions.isCurrent(id: "reminder", revision: latest))
    }

    func testCancelThenReenableDoesNotReviveOldCallbackOrAffectOtherSchedules() {
        var revisions = NotificationFallbackRevisions()
        let other = revisions.begin(id: "other")
        let old = revisions.begin(id: "reminder")
        revisions.cancel(id: "reminder")
        let latest = revisions.begin(id: "reminder")
        XCTAssertFalse(revisions.isCurrent(id: "reminder", revision: old))
        XCTAssertTrue(revisions.isCurrent(id: "reminder", revision: latest))
        XCTAssertTrue(revisions.isCurrent(id: "other", revision: other))
    }
}
