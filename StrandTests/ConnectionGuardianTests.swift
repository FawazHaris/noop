import XCTest
@testable import Strand

final class ConnectionGuardianTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func streaming() -> ConnectionGuardian.Snapshot {
        var snapshot = ConnectionGuardian.Snapshot()
        snapshot.connected = true
        snapshot.encryptedBond = true
        snapshot.bonded = true
        snapshot.heartRate = 65
        snapshot.lastFrameAtUnix = Int(now.timeIntervalSince1970)
        return snapshot
    }

    func testStreamingWithoutCompletedSyncIsSyncDue() {
        XCTAssertEqual(ConnectionGuardian.resolve(streaming(), now: now),
                       .staleSync(hoursAgo: nil, message: nil))
    }

    func testActiveBackfillDoesNotReportMissingSyncAsFailure() {
        var snapshot = streaming()
        snapshot.backfilling = true
        snapshot.lastSyncError = "old error"
        XCTAssertEqual(ConnectionGuardian.resolve(snapshot, now: now), .healthyStream)
    }

    func testPairingGatePrecedesMissingSync() {
        var snapshot = streaming()
        snapshot.encryptedBond = false
        XCTAssertEqual(ConnectionGuardian.resolve(snapshot, now: now), .unpairedLive)
    }

    func testFreshAndStaleCompletedSync() {
        var snapshot = streaming()
        snapshot.lastSyncedAt = now.timeIntervalSince1970 - 3600
        XCTAssertEqual(ConnectionGuardian.resolve(snapshot, now: now), .healthyStream)
        snapshot.lastSyncedAt = now.timeIntervalSince1970 - 26 * 3600
        XCTAssertEqual(ConnectionGuardian.resolve(snapshot, now: now),
                       .staleSync(hoursAgo: 26, message: nil))
    }

    func testAttributedErrorPrecedesMissingSync() {
        var snapshot = streaming()
        snapshot.lastSyncError = "history failed"
        XCTAssertEqual(ConnectionGuardian.resolve(snapshot, now: now),
                       .staleSync(hoursAgo: nil, message: "history failed"))
    }
}
