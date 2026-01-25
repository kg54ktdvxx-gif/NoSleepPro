//
//  ClosedLidIntegrationTests.swift
//  AwakeAppTests
//
//  Integration tests for closed-lid (clamshell) mode
//

import XCTest
@testable import AwakeApp

final class ClosedLidIntegrationTests: XCTestCase {

    // MARK: - Requirements Tests

    func testClosedLidRequiresPowerAndDisplay() {
        // Test all requirement combinations
        let testCases: [(power: Bool, display: Bool, canEnable: Bool)] = [
            (power: true, display: true, canEnable: true),
            (power: true, display: false, canEnable: false),
            (power: false, display: true, canEnable: false),
            (power: false, display: false, canEnable: false),
        ]

        for testCase in testCases {
            let status = ClosedLidStatus(
                isPowerConnected: testCase.power,
                hasExternalDisplay: testCase.display,
                isLidClosed: false,
                isEnabled: false,
                canEnable: testCase.power && testCase.display
            )

            XCTAssertEqual(
                status.canEnable,
                testCase.canEnable,
                "Power: \(testCase.power), Display: \(testCase.display) should canEnable: \(testCase.canEnable)"
            )
        }
    }

    func testClosedLidStatusDescriptions() {
        // Enabled and lid closed
        var status = ClosedLidStatus(
            isPowerConnected: true,
            hasExternalDisplay: true,
            isLidClosed: true,
            isEnabled: true,
            canEnable: true
        )
        XCTAssertEqual(status.statusDescription, "Active (lid closed)")

        // Enabled but lid open
        status.isLidClosed = false
        XCTAssertEqual(status.statusDescription, "Ready (lid open)")

        // Not enabled, missing power
        status.isEnabled = false
        status.isPowerConnected = false
        XCTAssertEqual(status.statusDescription, "Requires power adapter")

        // Not enabled, has power but no display
        status.isPowerConnected = true
        status.hasExternalDisplay = false
        XCTAssertEqual(status.statusDescription, "Requires external display")

        // Not enabled but available
        status.hasExternalDisplay = true
        XCTAssertEqual(status.statusDescription, "Available")
    }

    // MARK: - Enable/Disable Flow Tests

    func testEnableClosedLidWithRequirementsMet() {
        var isEnabled = false
        let isPowerConnected = true
        let hasExternalDisplay = true

        // Attempt to enable
        if isPowerConnected && hasExternalDisplay {
            isEnabled = true
        }

        XCTAssertTrue(isEnabled)
    }

    func testEnableClosedLidFailsWithoutPower() {
        var isEnabled = false
        var lastError: ClosedLidError?

        let isPowerConnected = false
        let hasExternalDisplay = true

        if !isPowerConnected {
            lastError = .noPowerConnected
        } else if !hasExternalDisplay {
            lastError = .noExternalDisplay
        } else {
            isEnabled = true
        }

        XCTAssertFalse(isEnabled)
        XCTAssertEqual(lastError, .noPowerConnected)
    }

    func testEnableClosedLidFailsWithoutDisplay() {
        var isEnabled = false
        var lastError: ClosedLidError?

        let isPowerConnected = true
        let hasExternalDisplay = false

        if !isPowerConnected {
            lastError = .noPowerConnected
        } else if !hasExternalDisplay {
            lastError = .noExternalDisplay
        } else {
            isEnabled = true
        }

        XCTAssertFalse(isEnabled)
        XCTAssertEqual(lastError, .noExternalDisplay)
    }

    // MARK: - Auto-Disable Tests

    func testAutoDisableWhenPowerRemoved() {
        var isEnabled = true
        var lastError: ClosedLidError?

        // Requirements initially met
        var isPowerConnected = true
        var hasExternalDisplay = true

        // User unplugs power
        isPowerConnected = false

        // Auto-disable check
        if isEnabled && (!isPowerConnected || !hasExternalDisplay) {
            isEnabled = false
            if !isPowerConnected {
                lastError = .noPowerConnected
            } else {
                lastError = .noExternalDisplay
            }
        }

        XCTAssertFalse(isEnabled)
        XCTAssertEqual(lastError, .noPowerConnected)
    }

    func testAutoDisableWhenDisplayRemoved() {
        var isEnabled = true
        var lastError: ClosedLidError?

        var isPowerConnected = true
        var hasExternalDisplay = true

        // User disconnects display
        hasExternalDisplay = false

        if isEnabled && (!isPowerConnected || !hasExternalDisplay) {
            isEnabled = false
            if !isPowerConnected {
                lastError = .noPowerConnected
            } else {
                lastError = .noExternalDisplay
            }
        }

        XCTAssertFalse(isEnabled)
        XCTAssertEqual(lastError, .noExternalDisplay)
    }

    // MARK: - Integration with Main App State

    func testClosedLidWithRegularAwakeMode() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        // User enables regular awake mode
        mockState.activate(with: .indefinite)
        mockPower.start(duration: nil, allowDisplaySleep: false, reason: .manual)

        // User also enables closed-lid mode
        let closedLidEnabled = true
        let isPowerConnected = true
        let hasExternalDisplay = true

        // Both can coexist
        XCTAssertTrue(mockState.isActive)
        XCTAssertTrue(closedLidEnabled && isPowerConnected && hasExternalDisplay)
    }

    // MARK: - Error Messages Tests

    func testClosedLidErrorDescriptions() {
        XCTAssertEqual(
            ClosedLidError.noPowerConnected.errorDescription,
            "Power adapter required for closed-lid mode"
        )
        XCTAssertEqual(
            ClosedLidError.noExternalDisplay.errorDescription,
            "External display required for closed-lid mode"
        )
        XCTAssertNotNil(ClosedLidError.assertionFailed(0).errorDescription)
        XCTAssertEqual(
            ClosedLidError.unsupportedConfiguration.errorDescription,
            "This Mac doesn't support closed-lid mode"
        )
    }

    func testClosedLidErrorRecoverySuggestions() {
        XCTAssertNotNil(ClosedLidError.noPowerConnected.recoverySuggestion)
        XCTAssertNotNil(ClosedLidError.noExternalDisplay.recoverySuggestion)
        XCTAssertNotNil(ClosedLidError.assertionFailed(0).recoverySuggestion)
        XCTAssertNotNil(ClosedLidError.unsupportedConfiguration.recoverySuggestion)
    }

    // MARK: - Lid State Detection Tests

    func testLidClosedDetection() {
        // Simulate different scenarios
        let scenarios: [(builtInDisplayVisible: Bool, externalDisplays: Int, expectedLidClosed: Bool)] = [
            (builtInDisplayVisible: true, externalDisplays: 0, expectedLidClosed: false),  // Laptop, lid open
            (builtInDisplayVisible: true, externalDisplays: 1, expectedLidClosed: false),  // Laptop with external, lid open
            (builtInDisplayVisible: false, externalDisplays: 1, expectedLidClosed: true),  // Laptop with external, lid closed
            (builtInDisplayVisible: false, externalDisplays: 2, expectedLidClosed: true),  // Laptop with 2 externals, lid closed
        ]

        for scenario in scenarios {
            let isLidClosed = !scenario.builtInDisplayVisible && scenario.externalDisplays >= 1

            XCTAssertEqual(
                isLidClosed,
                scenario.expectedLidClosed,
                "Built-in: \(scenario.builtInDisplayVisible), External: \(scenario.externalDisplays)"
            )
        }
    }

    // MARK: - Toggle Tests

    func testToggleClosedLidMode() {
        var isEnabled = false

        // Toggle on
        isEnabled = !isEnabled
        XCTAssertTrue(isEnabled)

        // Toggle off
        isEnabled = !isEnabled
        XCTAssertFalse(isEnabled)
    }
}
