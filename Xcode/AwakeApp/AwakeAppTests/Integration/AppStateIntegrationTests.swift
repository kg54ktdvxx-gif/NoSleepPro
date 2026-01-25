//
//  AppStateIntegrationTests.swift
//  AwakeAppTests
//
//  Integration tests for app state transitions and timer behavior
//

import XCTest
@testable import AwakeApp

final class AppStateIntegrationTests: XCTestCase {

    // MARK: - Activation Flow Tests

    func testActivationWithPresetSetsCorrectState() {
        let mockState = MockAppState()

        // Activate with 1 hour preset
        mockState.activate(with: .oneHour)

        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockState.currentPreset, .oneHour)
        XCTAssertEqual(mockState.remainingSeconds, 3600)
        XCTAssertEqual(mockState.activateCallCount, 1)
    }

    func testDeactivationClearsState() {
        let mockState = MockAppState()

        // Activate then deactivate
        mockState.activate(with: .thirtyMinutes)
        mockState.deactivate()

        XCTAssertFalse(mockState.isActive)
        XCTAssertNil(mockState.currentPreset)
        XCTAssertNil(mockState.remainingSeconds)
        XCTAssertEqual(mockState.deactivateCallCount, 1)
    }

    func testIndefiniteModeHasNoRemainingTime() {
        let mockState = MockAppState()

        mockState.activate(with: .indefinite)

        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockState.currentPreset, .indefinite)
        XCTAssertNil(mockState.remainingSeconds)
    }

    func testCustomDurationSetsCorrectSeconds() {
        let mockState = MockAppState()

        mockState.activate(with: .custom(minutes: 45))

        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockState.currentPreset, .custom(minutes: 45))
        XCTAssertEqual(mockState.remainingSeconds, 45 * 60)
    }

    func testReactivationWithDifferentPreset() {
        let mockState = MockAppState()

        // Activate with one preset
        mockState.activate(with: .fifteenMinutes)
        XCTAssertEqual(mockState.remainingSeconds, 15 * 60)

        // Reactivate with different preset
        mockState.activate(with: .twoHours)
        XCTAssertEqual(mockState.remainingSeconds, 2 * 60 * 60)
        XCTAssertEqual(mockState.activateCallCount, 2)
    }

    // MARK: - Power Manager Integration Tests

    func testPowerManagerStartStop() {
        let mockPower = MockPowerManager()

        // Start
        mockPower.start(duration: 3600, allowDisplaySleep: false, reason: .manual)

        XCTAssertTrue(mockPower.isRunning)
        XCTAssertEqual(mockPower.lastDuration, 3600)
        XCTAssertEqual(mockPower.lastAllowDisplaySleep, false)
        XCTAssertEqual(mockPower.lastReason, .manual)
        XCTAssertEqual(mockPower.startCallCount, 1)

        // Stop
        mockPower.stop()

        XCTAssertFalse(mockPower.isRunning)
        XCTAssertNil(mockPower.activationReason)
        XCTAssertEqual(mockPower.stopCallCount, 1)
    }

    func testPowerManagerWithDisplaySleep() {
        let mockPower = MockPowerManager()

        mockPower.start(duration: nil, allowDisplaySleep: true, reason: .schedule)

        XCTAssertTrue(mockPower.isRunning)
        XCTAssertNil(mockPower.lastDuration)
        XCTAssertEqual(mockPower.lastAllowDisplaySleep, true)
        XCTAssertEqual(mockPower.activationReason, .schedule)
    }

    func testPowerManagerActivationReasons() {
        let mockPower = MockPowerManager()

        // Test each activation reason
        let reasons: [ActivationReason] = [
            .manual,
            .schedule,
            .keyboardShortcut,
            .appTrigger(appName: "Zoom"),
            .wifiTrigger(ssid: "HomeNetwork"),
            .hardwareTrigger(type: "Power connected")
        ]

        for reason in reasons {
            mockPower.start(duration: nil, allowDisplaySleep: false, reason: reason)
            XCTAssertEqual(mockPower.activationReason, reason)
            mockPower.stop()
        }
    }

    // MARK: - State + Power Coordination Tests

    func testCoordinatedActivation() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        // Simulate coordinated activation
        let preset = TimerPreset.oneHour
        mockState.activate(with: preset)
        mockPower.start(duration: preset.seconds, allowDisplaySleep: false, reason: .manual)

        XCTAssertTrue(mockState.isActive)
        XCTAssertTrue(mockPower.isRunning)
        XCTAssertEqual(mockState.remainingSeconds, mockPower.lastDuration)
    }

    func testCoordinatedDeactivation() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        // Activate
        mockState.activate(with: .thirtyMinutes)
        mockPower.start(duration: 30 * 60, allowDisplaySleep: false, reason: .manual)

        // Deactivate
        mockState.deactivate()
        mockPower.stop()

        XCTAssertFalse(mockState.isActive)
        XCTAssertFalse(mockPower.isRunning)
    }

    // MARK: - Preset Transitions Tests

    func testAllPresetTransitions() {
        let mockState = MockAppState()
        let presets = TimerPreset.allCases

        for preset in presets {
            mockState.activate(with: preset)
            XCTAssertTrue(mockState.isActive)
            XCTAssertEqual(mockState.currentPreset, preset)

            if preset == .indefinite {
                XCTAssertNil(mockState.remainingSeconds)
            } else {
                XCTAssertNotNil(mockState.remainingSeconds)
            }

            mockState.deactivate()
            XCTAssertFalse(mockState.isActive)
        }
    }

    func testRapidActivationDeactivation() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        // Rapid toggling
        for _ in 0..<10 {
            mockState.activate(with: .fifteenMinutes)
            mockPower.start(duration: 15 * 60, allowDisplaySleep: false, reason: .manual)
            mockState.deactivate()
            mockPower.stop()
        }

        XCTAssertEqual(mockState.activateCallCount, 10)
        XCTAssertEqual(mockState.deactivateCallCount, 10)
        XCTAssertEqual(mockPower.startCallCount, 10)
        XCTAssertEqual(mockPower.stopCallCount, 10)
        XCTAssertFalse(mockState.isActive)
        XCTAssertFalse(mockPower.isRunning)
    }
}
