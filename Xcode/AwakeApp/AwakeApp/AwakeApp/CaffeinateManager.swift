//
//  CaffeinateManager.swift
//  AwakeApp
//
//  Manages power assertions to prevent Mac from sleeping
//  Uses IOKit APIs for Mac App Store compatibility
//

import Foundation
import Combine
import IOKit.pwr_mgt
import IOKit.ps
import os.log

/// Logger for power management events
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "thisisvision.AwakeApp", category: "PowerManagement")

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

/// Reason why sleep prevention was activated
enum ActivationReason: Equatable {
    case manual
    case schedule
    case appTrigger(appName: String)
    case keyboardShortcut
    case hardwareTrigger(type: String)
    case scenario(name: String)

    var description: String {
        switch self {
        case .manual: return "Manual"
        case .schedule: return "Schedule"
        case .appTrigger(let appName): return "App: \(appName)"
        case .keyboardShortcut: return "Shortcut"
        case .hardwareTrigger(let type): return "Hardware: \(type)"
        case .scenario(let name): return "Smart: \(name)"
        }
    }
}

@MainActor
final class CaffeinateManager: ObservableObject {
    /// Current power assertion IDs (empty when not active)
    private var assertionIDs: [IOPMAssertionID] = []

    /// Timer for auto-stopping after duration
    private var durationTimer: Timer?

    /// Published error state for UI feedback
    @Published var lastError: PowerManagementError?

    /// Reason for current activation
    @Published var activationReason: ActivationReason?

    /// Whether display sleep is allowed (only system stays awake)
    private var allowDisplaySleep: Bool = false

    /// Start preventing sleep with optional duration
    /// - Parameters:
    ///   - duration: Duration in seconds, or nil for indefinite
    ///   - allowDisplaySleep: If true, display can sleep but system stays awake
    ///   - reason: Why sleep prevention was activated
    func start(duration: Int?, allowDisplaySleep: Bool = false, reason: ActivationReason = .manual) {
        // Stop any existing assertion first
        stop()

        // Clear previous errors
        lastError = nil
        self.allowDisplaySleep = allowDisplaySleep
        self.activationReason = reason

        // Create power assertion
        var assertionID: IOPMAssertionID = 0
        let assertionName = "No Sleep Pro preventing sleep" as CFString

        // Choose assertion type based on display sleep preference
        let assertionType = allowDisplaySleep
            ? kIOPMAssertionTypeNoIdleSleep as CFString  // System awake, display can sleep
            : kIOPMAssertionTypeNoDisplaySleep as CFString // Both system and display awake

        let result = IOPMAssertionCreateWithName(
            assertionType,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            assertionName,
            &assertionID
        )

        if result == kIOReturnSuccess {
            self.assertionIDs.append(assertionID)
            logger.info("Power assertion created (ID: \(assertionID), displaySleep: \(allowDisplaySleep), reason: \(reason.description))")

            // Set up duration timer if specified
            if let seconds = duration {
                setupDurationTimer(seconds: seconds)
            }
        } else {
            let error = PowerManagementError.assertionCreationFailed(result)
            lastError = error
            activationReason = nil
            logger.error("Failed to create power assertion: \(error.localizedDescription)")
        }
    }

    /// Start preventing sleep with a scenario preset (indefinite)
    /// - Parameters:
    ///   - scenario: The scenario preset to activate
    ///   - reason: Why sleep prevention was activated
    func start(scenario: ScenarioPreset, reason: ActivationReason) {
        // Stop any existing assertion first
        stop()

        // Clear previous errors
        lastError = nil
        self.allowDisplaySleep = scenario.allowDisplaySleep
        self.activationReason = reason

        // Create power assertion using the scenario's assertion type
        var assertionID: IOPMAssertionID = 0
        let assertionName = "No Sleep Pro: \(scenario.displayName)" as CFString
        let assertionType = scenario.assertionType as CFString

        let result = IOPMAssertionCreateWithName(
            assertionType,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            assertionName,
            &assertionID
        )

        if result == kIOReturnSuccess {
            self.assertionIDs.append(assertionID)
            logger.info("Scenario assertion created (ID: \(assertionID), scenario: \(scenario.displayName), type: \(scenario.assertionType))")
        } else {
            let error = PowerManagementError.assertionCreationFailed(result)
            lastError = error
            activationReason = nil
            logger.error("Failed to create scenario assertion: \(error.localizedDescription)")
        }
    }

    /// Stop preventing sleep
    func stop() {
        // Cancel duration timer
        durationTimer?.invalidate()
        durationTimer = nil

        // Release all power assertions
        for assertionID in assertionIDs {
            let result = IOPMAssertionRelease(assertionID)

            if result == kIOReturnSuccess {
                logger.info("Power assertion released (ID: \(assertionID))")
            } else {
                let error = PowerManagementError.assertionReleaseFailed(result)
                lastError = error
                logger.error("Failed to release power assertion: \(error.localizedDescription)")
            }
        }

        self.assertionIDs.removeAll()
        self.activationReason = nil
    }

    /// Check if sleep prevention is currently active
    var isRunning: Bool {
        !assertionIDs.isEmpty
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

    // MARK: - Battery Monitoring

    /// Get current battery level (0-100) or nil if on AC power or no battery
    static func getBatteryLevel() -> Int? {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            if let type = description[kIOPSTypeKey] as? String,
               type == kIOPSInternalBatteryType {
                // Check if on battery power
                if let powerSource = description[kIOPSPowerSourceStateKey] as? String,
                   powerSource == kIOPSBatteryPowerValue {
                    // Return battery level
                    if let capacity = description[kIOPSCurrentCapacityKey] as? Int {
                        return capacity
                    }
                }
            }
        }

        return nil // On AC power or no battery
    }

    /// Check if Mac is currently on battery power
    static func isOnBatteryPower() -> Bool {
        getBatteryLevel() != nil
    }

    /// Alias for isOnBatteryPower for convenience
    static func isOnBattery() -> Bool {
        isOnBatteryPower()
    }

    /// Cleanup on deallocation
    deinit {
        for assertionID in assertionIDs {
            IOPMAssertionRelease(assertionID)
        }
        durationTimer?.invalidate()
    }
}

// MARK: - Protocol Conformance

extension CaffeinateManager: PowerManaging {}
