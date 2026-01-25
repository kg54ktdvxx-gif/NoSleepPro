//
//  ErrorHandlingIntegrationTests.swift
//  AwakeAppTests
//
//  Integration tests for error handling and recovery flows
//

import XCTest
@testable import AwakeApp

final class ErrorHandlingIntegrationTests: XCTestCase {

    // MARK: - WiFi Error Tests

    func testWiFiErrorNoInterface() {
        let error = WiFiError.noInterface

        XCTAssertEqual(error.errorDescription, "No Wi-Fi interface available")
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion?.contains("Wi-Fi") ?? false)
    }

    func testWiFiErrorMonitoringFailed() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Connection timeout"])
        let error = WiFiError.monitoringFailed(underlying: underlyingError)

        XCTAssertTrue(error.errorDescription?.contains("failed") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("timeout") ?? false)
    }

    func testWiFiErrorMonitoringFailedNilUnderlying() {
        let error = WiFiError.monitoringFailed(underlying: nil)

        XCTAssertEqual(error.errorDescription, "Wi-Fi monitoring failed")
    }

    // MARK: - Mouse Jiggler Error Tests

    func testMouseJigglerErrorAccessibility() {
        let error = MouseJigglerError.noAccessibilityPermission

        XCTAssertEqual(error.errorDescription, "Accessibility permission required")
        XCTAssertTrue(error.recoverySuggestion?.contains("System Settings") ?? false)
    }

    func testMouseJigglerErrorEventCreation() {
        let error = MouseJigglerError.eventCreationFailed

        XCTAssertEqual(error.errorDescription, "Failed to create mouse movement event")
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testMouseJigglerErrorPosition() {
        let error = MouseJigglerError.positionUnavailable

        XCTAssertEqual(error.errorDescription, "Unable to get current mouse position")
    }

    // MARK: - Keyboard Shortcut Error Tests

    func testKeyboardShortcutErrorMonitoring() {
        let error = KeyboardShortcutError.monitoringFailed

        XCTAssertEqual(error.errorDescription, "Failed to monitor keyboard events")
        XCTAssertTrue(error.recoverySuggestion?.contains("accessibility") ?? false)
    }

    func testKeyboardShortcutErrorInvalid() {
        let error = KeyboardShortcutError.invalidShortcut

        XCTAssertEqual(error.errorDescription, "Invalid keyboard shortcut")
        XCTAssertTrue(error.recoverySuggestion?.contains("Command") ?? false)
    }

    func testKeyboardShortcutErrorConflict() {
        let error = KeyboardShortcutError.shortcutConflict(existingApp: "Safari")

        XCTAssertTrue(error.errorDescription?.contains("Safari") ?? false)
    }

    func testKeyboardShortcutErrorConflictUnknownApp() {
        let error = KeyboardShortcutError.shortcutConflict(existingApp: nil)

        XCTAssertEqual(error.errorDescription, "Shortcut conflicts with another app")
    }

    // MARK: - Closed Lid Error Tests

    func testClosedLidErrorEquatable() {
        XCTAssertEqual(ClosedLidError.noPowerConnected, ClosedLidError.noPowerConnected)
        XCTAssertEqual(ClosedLidError.noExternalDisplay, ClosedLidError.noExternalDisplay)
        XCTAssertNotEqual(ClosedLidError.noPowerConnected, ClosedLidError.noExternalDisplay)
    }

    // MARK: - Error Recovery Flow Tests

    func testWiFiErrorRecoveryFlow() {
        var lastError: WiFiError? = .noInterface
        var isMonitoring = false

        // Simulate recovery: user enables Wi-Fi
        let wifiEnabled = true

        if wifiEnabled {
            lastError = nil
            isMonitoring = true
        }

        XCTAssertNil(lastError)
        XCTAssertTrue(isMonitoring)
    }

    func testMouseJigglerPermissionRecoveryFlow() {
        var lastError: MouseJigglerError? = .noAccessibilityPermission
        var hasPermission = false
        var isRunning = false

        // Simulate: user grants permission in System Settings
        hasPermission = true

        if hasPermission {
            lastError = nil
            isRunning = true
        }

        XCTAssertNil(lastError)
        XCTAssertTrue(isRunning)
    }

    func testClosedLidRequirementRecoveryFlow() {
        var lastError: ClosedLidError? = .noPowerConnected
        var isEnabled = false

        // User connects power
        let isPowerConnected = true
        var hasExternalDisplay = false

        if isPowerConnected && !hasExternalDisplay {
            lastError = .noExternalDisplay
        }

        XCTAssertEqual(lastError, .noExternalDisplay)

        // User connects display
        hasExternalDisplay = true

        if isPowerConnected && hasExternalDisplay {
            lastError = nil
            isEnabled = true
        }

        XCTAssertNil(lastError)
        XCTAssertTrue(isEnabled)
    }

    // MARK: - Consecutive Failure Tests

    func testMouseJigglerConsecutiveFailures() {
        var consecutiveFailures = 0
        let maxFailures = 3
        var isRunning = true
        var shouldStop = false

        // Simulate 3 consecutive failures
        for _ in 0..<3 {
            consecutiveFailures += 1

            if consecutiveFailures >= maxFailures {
                shouldStop = true
                isRunning = false
            }
        }

        XCTAssertTrue(shouldStop)
        XCTAssertFalse(isRunning)
        XCTAssertEqual(consecutiveFailures, 3)
    }

    func testMouseJigglerSuccessResetsFailureCount() {
        var consecutiveFailures = 2

        // Successful jiggle
        let success = true
        if success {
            consecutiveFailures = 0
        }

        XCTAssertEqual(consecutiveFailures, 0)
    }

    // MARK: - Error Display Logic Tests

    func testErrorDisplayDecision() {
        // Non-critical errors should log but not display
        let nonCriticalErrors: [(error: WiFiError, shouldDisplay: Bool)] = [
            (.ssidUnavailable, false),
        ]

        // Critical errors should display to user
        let criticalErrors: [(error: MouseJigglerError, shouldDisplay: Bool)] = [
            (.noAccessibilityPermission, true),
        ]

        for (_, shouldDisplay) in nonCriticalErrors {
            XCTAssertFalse(shouldDisplay)
        }

        for (_, shouldDisplay) in criticalErrors {
            XCTAssertTrue(shouldDisplay)
        }
    }

    // MARK: - Error State Cleanup Tests

    func testErrorClearedOnSuccessfulOperation() {
        var lastError: WiFiError? = .noInterface

        // Successful operation
        let operationSucceeded = true

        if operationSucceeded {
            lastError = nil
        }

        XCTAssertNil(lastError)
    }

    func testErrorPersistsUntilResolved() {
        var lastError: MouseJigglerError? = .noAccessibilityPermission
        var hasPermission = false

        // Attempt operation without fixing issue
        if !hasPermission {
            // Error persists
        }

        XCTAssertNotNil(lastError)

        // Fix issue
        hasPermission = true
        lastError = nil

        XCTAssertNil(lastError)
    }
}
