//
//  ClosedLidManager.swift
//  AwakeApp
//
//  Manages closed-lid (clamshell) mode for external display setups
//  Allows Mac to stay awake with lid closed when connected to power and external display
//

import Foundation
import Combine
import SwiftUI
import IOKit
import IOKit.pwr_mgt
import IOKit.ps
import AppKit
import os.log

private let logger = Logger(subsystem: "com.awakeapp", category: "ClosedLid")

/// Errors related to closed-lid mode
enum ClosedLidError: LocalizedError {
    case noPowerConnected
    case noExternalDisplay
    case assertionFailed(IOReturn)
    case unsupportedConfiguration

    var errorDescription: String? {
        switch self {
        case .noPowerConnected:
            return "Power adapter required for closed-lid mode"
        case .noExternalDisplay:
            return "External display required for closed-lid mode"
        case .assertionFailed(let code):
            return "Failed to enable closed-lid mode (error: \(code))"
        case .unsupportedConfiguration:
            return "This Mac doesn't support closed-lid mode"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noPowerConnected:
            return "Connect your Mac to a power adapter to use closed-lid mode."
        case .noExternalDisplay:
            return "Connect an external display to use closed-lid mode."
        case .assertionFailed:
            return "Try restarting the app or your Mac."
        case .unsupportedConfiguration:
            return "Closed-lid mode is only available on MacBooks with external display support."
        }
    }
}

/// Status of closed-lid mode requirements
struct ClosedLidStatus {
    var isPowerConnected: Bool
    var hasExternalDisplay: Bool
    var isLidClosed: Bool
    var isEnabled: Bool
    var canEnable: Bool

    var statusDescription: String {
        if isEnabled && isLidClosed {
            return "Active (lid closed)"
        } else if isEnabled {
            return "Ready (lid open)"
        } else if !isPowerConnected {
            return "Requires power adapter"
        } else if !hasExternalDisplay {
            return "Requires external display"
        } else {
            return "Available"
        }
    }
}

@MainActor
final class ClosedLidManager: ObservableObject {
    static let shared = ClosedLidManager()

    // MARK: - Published State

    @Published var isEnabled: Bool = false
    @Published var status: ClosedLidStatus
    @Published var lastError: ClosedLidError?

    // MARK: - Private State

    private var assertionID: IOPMAssertionID?
    private var monitorTimer: Timer?

    // MARK: - Initialization

    private init() {
        self.status = ClosedLidStatus(
            isPowerConnected: false,
            hasExternalDisplay: false,
            isLidClosed: false,
            isEnabled: false,
            canEnable: false
        )
        updateStatus()
    }

    // MARK: - Public Methods

    /// Start monitoring for closed-lid mode conditions
    func startMonitoring() {
        updateStatus()

        // Monitor every 5 seconds
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatus()
                self?.checkAndUpdateAssertion()
            }
        }

        logger.info("Closed-lid monitoring started")
    }

    /// Stop monitoring
    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
        disable()
        logger.info("Closed-lid monitoring stopped")
    }

    /// Enable closed-lid mode
    @discardableResult
    func enable() -> Result<Void, ClosedLidError> {
        lastError = nil

        // Check requirements
        guard status.isPowerConnected else {
            let error = ClosedLidError.noPowerConnected
            lastError = error
            logger.warning("Cannot enable closed-lid: no power")
            return .failure(error)
        }

        guard status.hasExternalDisplay else {
            let error = ClosedLidError.noExternalDisplay
            lastError = error
            logger.warning("Cannot enable closed-lid: no external display")
            return .failure(error)
        }

        // Create power assertion to prevent sleep with lid closed
        let result = createClosedLidAssertion()
        if case .failure(let error) = result {
            lastError = error
            return .failure(error)
        }

        isEnabled = true
        updateStatus()
        logger.info("Closed-lid mode enabled")
        return .success(())
    }

    /// Disable closed-lid mode
    func disable() {
        releaseAssertion()
        isEnabled = false
        updateStatus()
        logger.info("Closed-lid mode disabled")
    }

    /// Toggle closed-lid mode
    @discardableResult
    func toggle() -> Result<Void, ClosedLidError> {
        if isEnabled {
            disable()
            return .success(())
        } else {
            return enable()
        }
    }

    // MARK: - Private Methods

    private func updateStatus() {
        let isPowerConnected = !CaffeinateManager.isOnBattery()
        let hasExternalDisplay = NSScreen.screens.count > 1
        let isLidClosed = checkLidClosed()

        status = ClosedLidStatus(
            isPowerConnected: isPowerConnected,
            hasExternalDisplay: hasExternalDisplay,
            isLidClosed: isLidClosed,
            isEnabled: isEnabled,
            canEnable: isPowerConnected && hasExternalDisplay
        )
    }

    private func checkAndUpdateAssertion() {
        guard isEnabled else { return }

        // If requirements no longer met, disable
        if !status.isPowerConnected || !status.hasExternalDisplay {
            logger.warning("Closed-lid requirements no longer met, disabling")
            disable()

            // Notify user
            if !status.isPowerConnected {
                lastError = .noPowerConnected
            } else {
                lastError = .noExternalDisplay
            }
        }
    }

    private func checkLidClosed() -> Bool {
        // Check if the built-in display is off (indicating lid is closed)
        // When lid is closed with external display, built-in display disappears from NSScreen.screens

        // First, check if this is a laptop (has built-in display capability)
        guard isLaptop() else { return false }

        // If we have external displays but the built-in isn't showing, lid is likely closed
        let screens = NSScreen.screens
        let hasBuiltInDisplay = screens.contains { screen in
            // Built-in displays typically have a specific device description
            let deviceDescription = screen.deviceDescription
            if let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
                // The built-in display is usually screen 0 on laptops
                // This is a heuristic - in practice checking CGDisplayIsBuiltin is more reliable
                return CGDisplayIsBuiltin(screenNumber.uint32Value) != 0
            }
            return false
        }

        // If we have external displays but no built-in, lid is closed
        return !hasBuiltInDisplay && screens.count >= 1
    }

    private func isLaptop() -> Bool {
        // Check if this Mac has a battery (laptops have batteries)
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        for source in sources {
            let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as! [String: Any]
            if let type = description[kIOPSTypeKey] as? String,
               type == kIOPSInternalBatteryType {
                return true
            }
        }
        return false
    }

    private func createClosedLidAssertion() -> Result<Void, ClosedLidError> {
        // Release any existing assertion
        releaseAssertion()

        var assertionID: IOPMAssertionID = 0
        let assertionName = "AwakeApp closed-lid mode" as CFString

        // Use PreventUserIdleSystemSleep to keep system awake
        // Combined with external display, this enables clamshell mode
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            assertionName,
            &assertionID
        )

        if result == kIOReturnSuccess {
            self.assertionID = assertionID
            logger.info("Closed-lid assertion created (ID: \(assertionID))")
            return .success(())
        } else {
            logger.error("Failed to create closed-lid assertion: \(result)")
            return .failure(.assertionFailed(result))
        }
    }

    private func releaseAssertion() {
        guard let assertionID = assertionID else { return }

        let result = IOPMAssertionRelease(assertionID)
        if result == kIOReturnSuccess {
            logger.info("Closed-lid assertion released")
        } else {
            logger.error("Failed to release closed-lid assertion: \(result)")
        }

        self.assertionID = nil
    }

    deinit {
        if let assertionID = assertionID {
            IOPMAssertionRelease(assertionID)
        }
        monitorTimer?.invalidate()
    }
}

// MARK: - Settings Extension

extension AppSettings {
    /// Enable closed-lid mode feature
    var closedLidModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "closedLidModeEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "closedLidModeEnabled") }
    }

    /// Auto-enable closed-lid when conditions are met
    var autoEnableClosedLid: Bool {
        get { UserDefaults.standard.bool(forKey: "autoEnableClosedLid") }
        set { UserDefaults.standard.set(newValue, forKey: "autoEnableClosedLid") }
    }
}
