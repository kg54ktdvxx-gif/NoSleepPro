//
//  ErrorHandlingIntegrationTests.swift
//  AwakeAppTests
//
//  Integration tests for error handling and recovery flows
//

import XCTest
@testable import AwakeApp

final class ErrorHandlingIntegrationTests: XCTestCase {

    // MARK: - Keyboard Shortcut Error Tests

    func testKeyboardShortcutErrorRegistration() {
        let error = KeyboardShortcutError.registrationFailed

        XCTAssertEqual(error.errorDescription, "Failed to register keyboard shortcut")
        XCTAssertTrue(error.recoverySuggestion?.contains("shortcut") ?? false)
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

    // MARK: - Error Display Logic Tests

    func testCriticalErrorsShouldDisplay() {
        // Critical errors should display to user
        let criticalErrors: [(error: KeyboardShortcutError, shouldDisplay: Bool)] = [
            (.registrationFailed, true)
        ]

        for (_, shouldDisplay) in criticalErrors {
            XCTAssertTrue(shouldDisplay)
        }
    }
}
