//
//  CaffeinateManagerTests.swift
//  AwakeAppTests
//
//  Unit tests for CaffeinateManager power management
//

import XCTest
@testable import AwakeApp

@MainActor
final class CaffeinateManagerTests: XCTestCase {

    // MARK: - PowerManagementError Tests

    func testPowerManagementErrorDescriptions() {
        let creationError = PowerManagementError.assertionCreationFailed(0)
        XCTAssertTrue(creationError.errorDescription?.contains("create") ?? false)
        XCTAssertTrue(creationError.errorDescription?.contains("0") ?? false)

        let releaseError = PowerManagementError.assertionReleaseFailed(1)
        XCTAssertTrue(releaseError.errorDescription?.contains("release") ?? false)
        XCTAssertTrue(releaseError.errorDescription?.contains("1") ?? false)
    }

    // MARK: - ActivationReason Tests

    func testActivationReasonDescriptions() {
        XCTAssertEqual(ActivationReason.manual.description, "Manual")
        XCTAssertEqual(ActivationReason.schedule.description, "Schedule")
        XCTAssertEqual(ActivationReason.keyboardShortcut.description, "Shortcut")

        let appTrigger = ActivationReason.appTrigger(appName: "Zoom")
        XCTAssertTrue(appTrigger.description.contains("Zoom"))

        let hardwareTrigger = ActivationReason.hardwareTrigger(type: "Power")
        XCTAssertTrue(hardwareTrigger.description.contains("Power"))
    }

    func testActivationReasonEquatable() {
        XCTAssertEqual(ActivationReason.manual, ActivationReason.manual)
        XCTAssertEqual(ActivationReason.schedule, ActivationReason.schedule)
        XCTAssertNotEqual(ActivationReason.manual, ActivationReason.schedule)

        XCTAssertEqual(
            ActivationReason.appTrigger(appName: "App1"),
            ActivationReason.appTrigger(appName: "App1")
        )
        XCTAssertNotEqual(
            ActivationReason.appTrigger(appName: "App1"),
            ActivationReason.appTrigger(appName: "App2")
        )

        XCTAssertEqual(
            ActivationReason.hardwareTrigger(type: "Power"),
            ActivationReason.hardwareTrigger(type: "Power")
        )
        XCTAssertNotEqual(
            ActivationReason.hardwareTrigger(type: "Power"),
            ActivationReason.hardwareTrigger(type: "Display")
        )
    }

    // MARK: - Mock Power Manager Behavior Tests

    func testMockPowerManagerStartStop() {
        let mock = MockPowerManager()

        XCTAssertFalse(mock.isRunning)
        XCTAssertNil(mock.activationReason)
        XCTAssertEqual(mock.startCallCount, 0)
        XCTAssertEqual(mock.stopCallCount, 0)

        mock.start(duration: 60, allowDisplaySleep: true, reason: .manual)

        XCTAssertTrue(mock.isRunning)
        XCTAssertEqual(mock.activationReason, .manual)
        XCTAssertEqual(mock.startCallCount, 1)
        XCTAssertEqual(mock.lastDuration, 60)
        XCTAssertEqual(mock.lastAllowDisplaySleep, true)

        mock.stop()

        XCTAssertFalse(mock.isRunning)
        XCTAssertNil(mock.activationReason)
        XCTAssertEqual(mock.stopCallCount, 1)
    }

    func testMockPowerManagerReset() {
        let mock = MockPowerManager()

        mock.start(duration: 120, allowDisplaySleep: false, reason: .schedule)
        mock.stop()

        XCTAssertEqual(mock.startCallCount, 1)
        XCTAssertEqual(mock.stopCallCount, 1)

        mock.reset()

        XCTAssertEqual(mock.startCallCount, 0)
        XCTAssertEqual(mock.stopCallCount, 0)
        XCTAssertNil(mock.lastDuration)
        XCTAssertNil(mock.lastAllowDisplaySleep)
        XCTAssertNil(mock.lastReason)
        XCTAssertFalse(mock.isRunning)
    }

    func testMockPowerManagerMultipleStarts() {
        let mock = MockPowerManager()

        // Start multiple times (simulating changing duration)
        mock.start(duration: 60, allowDisplaySleep: false, reason: .manual)
        mock.start(duration: 120, allowDisplaySleep: true, reason: .keyboardShortcut)

        XCTAssertEqual(mock.startCallCount, 2)
        XCTAssertEqual(mock.lastDuration, 120)
        XCTAssertEqual(mock.lastAllowDisplaySleep, true)
        XCTAssertEqual(mock.lastReason, .keyboardShortcut)
    }

    func testMockPowerManagerIndefiniteDuration() {
        let mock = MockPowerManager()

        mock.start(duration: nil, allowDisplaySleep: false, reason: .schedule)

        XCTAssertTrue(mock.isRunning)
        XCTAssertNil(mock.lastDuration)
    }

    // MARK: - Protocol Conformance Tests

    func testPowerManagingProtocolConformance() {
        // Verify MockPowerManager conforms to PowerManaging
        let powerManager: PowerManaging = MockPowerManager()

        powerManager.start(duration: 300, allowDisplaySleep: false, reason: .manual)
        XCTAssertTrue(powerManager.isRunning)
        XCTAssertEqual(powerManager.activationReason, .manual)

        powerManager.stop()
        XCTAssertFalse(powerManager.isRunning)
        XCTAssertNil(powerManager.activationReason)
    }

    // MARK: - Edge Case Tests

    func testStopWhenNotRunning() {
        let mock = MockPowerManager()

        // Stop when not running should be safe
        mock.stop()

        XCTAssertEqual(mock.stopCallCount, 1)
        XCTAssertFalse(mock.isRunning)
    }

    func testStartWithZeroDuration() {
        let mock = MockPowerManager()

        mock.start(duration: 0, allowDisplaySleep: false, reason: .manual)

        XCTAssertTrue(mock.isRunning)
        XCTAssertEqual(mock.lastDuration, 0)
    }

    func testStartWithNegativeDuration() {
        let mock = MockPowerManager()

        // Negative duration should still be accepted (validation is caller's responsibility)
        mock.start(duration: -1, allowDisplaySleep: false, reason: .manual)

        XCTAssertTrue(mock.isRunning)
        XCTAssertEqual(mock.lastDuration, -1)
    }
}
