import XCTest

/// iOS-only wiring cannot run in the macOS test host. Pin its safety contracts from source;
/// actual notification delivery, SwiftUI behavior and strap commands still need device tests.
final class PersonalReminderWiringTests: XCTestCase {
    private func source(_ path: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try String(contentsOf: root.appendingPathComponent(path), encoding: .utf8)
    }

    func testUnsupportedOneOffWakeCannotBeSavedOrAdvertisedAsUpcoming() throws {
        let alarms = try source("StrandiOS/Personal/PersonalAlarms.swift")
        XCTAssertTrue(alarms.contains("var isSupported: Bool { kind != .wake || oneOffDay == nil }"))
        XCTAssertTrue(alarms.contains("guard isSupported else { return nil }"))
        XCTAssertTrue(alarms.contains("guard schedule.isSupported else { return }"))
        XCTAssertTrue(alarms.contains(".disabled(kind == .wake && oneOff)"))
        XCTAssertTrue(alarms.contains("guard kind != .wake || !oneOff else { return }"))
    }

    func testCountdownReresolvesFromTimelineClock() throws {
        let today = try source("StrandiOS/Personal/PersonalTodayView.swift")
        XCTAssertTrue(today.contains("if let next = nextAlarm(from: tick.date)"))
        XCTAssertTrue(today.contains("Self.countdown(to: next, from: tick.date)"))
        XCTAssertTrue(today.contains("Text(Self.stamp(next))"))
    }

    func testForegroundReconcilesWithoutVisitingAlarmScreen() throws {
        let app = try source("StrandiOS/App/StrandiOSApp.swift")
        let alarms = try source("StrandiOS/Personal/PersonalAlarms.swift")
        XCTAssertTrue(app.contains("PersonalAlarmStore.shared.attach(model: model)"))
        XCTAssertTrue(alarms.contains("self.model = model\n        refreshNotificationFallbacks()\n        poll()"))
        XCTAssertTrue(alarms.contains("model.live.connected, model.live.encryptedBond"))
        XCTAssertTrue(alarms.contains("fireReminder(schedule.pattern, on: model, now: fire)"))
    }

    func testOnlyFirmwareWakeBypassesReminderQuietHours() throws {
        let scheduler = try source("StrandiOS/Personal/WristHapticScheduler.swift")
        XCTAssertTrue(scheduler.contains("if Self.inQuietHours(now) { return }"))
        XCTAssertFalse(scheduler.contains("pattern != .wake"))
    }

    func testAllPersonalBuzzActionsRequireEncryptedBond() throws {
        for path in ["Strand/Screens/WristView.swift", "StrandiOS/Personal/PersonalTodayView.swift"] {
            XCTAssertTrue(try source(path).contains(".disabled(!live.connected || !live.encryptedBond)"), path)
        }
    }
}
