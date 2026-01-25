//
//  CaffeinateManager.swift
//  AwakeApp
//
//  Manages power assertions to prevent Mac from sleeping
//  Uses IOKit APIs for Mac App Store compatibility
//

import Foundation
import IOKit.pwr_mgt
import os.log

/// Logger for power management events
private let logger = Logger(subsystem: "com.awakeapp", category: "PowerManagement")

/// Error types for power management operations
enum PowerManagementError: LocalizedError {
    case assertionCreationFailed(IOReturn)
    case assertionReleaseFailed(IOReturn)

    var errorDescription: String? {
        switch self {
        case .assertionCreationFailed(let status):
            return "Failed to create power assertion (error: \(status))"
        case .assertionReleaseFailed(let status):
            return "Failed to release power assertion (error: \(status))"
        }
    }
}

@MainActor
final class CaffeinateManager: ObservableObject {
    /// Current power assertion ID (nil when not active)
    private var assertionID: IOPMAssertionID?

    /// Timer for auto-stopping after duration
    private var durationTimer: Timer?

    /// Published error state for UI feedback
    @Published var lastError: PowerManagementError?

    /// Start preventing sleep with optional duration
    /// - Parameter duration: Duration in seconds, or nil for indefinite
    func start(duration: Int?) {
        // Stop any existing assertion first
        stop()

        // Clear previous errors
        lastError = nil

        // Create power assertion
        var assertionID: IOPMAssertionID = 0
        let assertionName = "AwakeApp preventing sleep" as CFString

        // Use NoDisplaySleep to prevent both display and system sleep
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            assertionName,
            &assertionID
        )

        if result == kIOReturnSuccess {
            self.assertionID = assertionID
            logger.info("Power assertion created successfully (ID: \(assertionID))")

            // Set up duration timer if specified
            if let seconds = duration {
                setupDurationTimer(seconds: seconds)
            }
        } else {
            let error = PowerManagementError.assertionCreationFailed(result)
            lastError = error
            logger.error("Failed to create power assertion: \(error.localizedDescription)")
        }
    }

    /// Stop preventing sleep
    func stop() {
        // Cancel duration timer
        durationTimer?.invalidate()
        durationTimer = nil

        // Release power assertion if active
        guard let assertionID = assertionID else { return }

        let result = IOPMAssertionRelease(assertionID)

        if result == kIOReturnSuccess {
            logger.info("Power assertion released successfully")
        } else {
            let error = PowerManagementError.assertionReleaseFailed(result)
            lastError = error
            logger.error("Failed to release power assertion: \(error.localizedDescription)")
        }

        self.assertionID = nil
    }

    /// Check if sleep prevention is currently active
    var isRunning: Bool {
        assertionID != nil
    }

    /// Set up timer to auto-stop after duration
    private func setupDurationTimer(seconds: Int) {
        durationTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.stop()
                logger.info("Duration timer expired, power assertion released")
            }
        }
    }

    /// Cleanup on deallocation
    deinit {
        // Note: Can't call stop() directly due to MainActor isolation
        // Release assertion synchronously if still active
        if let assertionID = assertionID {
            IOPMAssertionRelease(assertionID)
        }
        durationTimer?.invalidate()
    }
}
