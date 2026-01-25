//
//  HardwareMonitors.swift
//  AwakeApp
//
//  Monitors hardware state: power adapter, external displays, lid state
//

import Foundation
import AppKit
import IOKit.ps
import os.log

private let logger = Logger(subsystem: "com.awakeapp", category: "Hardware")

// MARK: - Power Adapter Monitor

@MainActor
class PowerMonitor: ObservableObject {
    static let shared = PowerMonitor()

    @Published var isOnACPower: Bool = true

    private var runLoopSource: CFRunLoopSource?

    private init() {
        updatePowerStatus()
    }

    func startMonitoring() {
        let context = Unmanaged.passUnretained(self).toOpaque()

        let callback: IOPowerSourceCallbackType = { context in
            guard let context = context else { return }
            let monitor = Unmanaged<PowerMonitor>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in
                monitor.updatePowerStatus()
            }
        }

        runLoopSource = IOPSNotificationCreateRunLoopSource(callback, context).takeRetainedValue()

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }

        logger.info("Power monitoring started")
    }

    func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
            runLoopSource = nil
        }
        logger.info("Power monitoring stopped")
    }

    private func updatePowerStatus() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        var onAC = true // Default to AC if no battery

        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                if let powerSource = description[kIOPSPowerSourceStateKey] as? String {
                    onAC = (powerSource == kIOPSACPowerValue)
                    break
                }
            }
        }

        if isOnACPower != onAC {
            logger.info("Power state changed: \(onAC ? "AC Power" : "Battery")")
            isOnACPower = onAC
        }
    }
}

// MARK: - External Display Monitor

@MainActor
class DisplayMonitor: ObservableObject {
    static let shared = DisplayMonitor()

    @Published var externalDisplayConnected: Bool = false
    @Published var displayCount: Int = 1

    private var observer: NSObjectProtocol?

    private init() {
        updateDisplayStatus()
    }

    func startMonitoring() {
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateDisplayStatus()
            }
        }

        logger.info("Display monitoring started")
    }

    func stopMonitoring() {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        logger.info("Display monitoring stopped")
    }

    private func updateDisplayStatus() {
        let screens = NSScreen.screens
        let newCount = screens.count
        let hasExternal = newCount > 1

        if displayCount != newCount {
            logger.info("Display count changed: \(newCount)")
            displayCount = newCount
        }

        if externalDisplayConnected != hasExternal {
            logger.info("External display: \(hasExternal ? "connected" : "disconnected")")
            externalDisplayConnected = hasExternal
        }
    }

    /// Get info about connected displays
    var displayInfo: [(name: String, isBuiltIn: Bool)] {
        NSScreen.screens.enumerated().map { index, screen in
            let name = screen.localizedName
            let isBuiltIn = index == 0 && !externalDisplayConnected
            return (name: name, isBuiltIn: isBuiltIn)
        }
    }
}

// MARK: - Lid State Monitor (for future clamshell mode)

@MainActor
class LidMonitor: ObservableObject {
    static let shared = LidMonitor()

    @Published var isLidClosed: Bool = false

    private var timer: Timer?

    private init() {}

    func startMonitoring() {
        // Check lid state periodically
        // Note: Direct lid state detection requires IOKit private APIs
        // For now, infer from display configuration
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkLidState()
            }
        }
        checkLidState()
        logger.info("Lid monitoring started")
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        logger.info("Lid monitoring stopped")
    }

    private func checkLidState() {
        // Heuristic: If on a laptop with external display and only 1 screen visible,
        // the lid is likely closed (clamshell mode)
        // This is not 100% reliable but works for most cases

        let hasExternalDisplay = DisplayMonitor.shared.externalDisplayConnected
        let screenCount = NSScreen.screens.count

        // If we have external display configured but only see 1 screen,
        // and we're on AC power, lid might be closed
        let mightBeClamshell = hasExternalDisplay && screenCount == 1 && PowerMonitor.shared.isOnACPower

        if isLidClosed != mightBeClamshell {
            isLidClosed = mightBeClamshell
            logger.info("Lid state (inferred): \(mightBeClamshell ? "closed" : "open")")
        }
    }
}
