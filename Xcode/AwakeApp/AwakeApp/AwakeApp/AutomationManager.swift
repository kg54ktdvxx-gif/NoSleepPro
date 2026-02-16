//
//  AutomationManager.swift
//  AwakeApp
//
//  Handles automatic activation via app triggers, schedules, battery monitoring, keyboard shortcuts,
//  and hardware triggers
//

import Foundation
import AppKit
import Combine
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "thisisvision.AwakeApp", category: "Automation")

@MainActor
final class AutomationManager: ObservableObject {
    // MARK: - Dependencies

    private let settings: AppSettings
    private let appState: AppState
    private let caffeinateManager: CaffeinateManager

    // MARK: - Monitoring State

    private var appObserver: NSObjectProtocol?
    private var appTerminateObserver: NSObjectProtocol?
    private var scheduleTimer: Timer?
    private var batteryTimer: Timer?
    private var hardwareTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Hardware State Tracking

    private var wasOnPower: Bool = true
    private var hadExternalDisplay: Bool = false

    /// Currently triggered app (if any)
    @Published var triggeredByApp: String?

    /// Whether currently activated by schedule
    @Published var activatedBySchedule: Bool = false

    /// Whether currently activated by hardware trigger
    @Published var activatedByHardware: Bool = false

    /// Current battery level (nil if on AC power)
    @Published var batteryLevel: Int?

    /// Whether battery protection stopped the timer
    @Published var stoppedByBattery: Bool = false

    // MARK: - Initialization

    init(settings: AppSettings, appState: AppState, caffeinateManager: CaffeinateManager) {
        self.settings = settings
        self.appState = appState
        self.caffeinateManager = caffeinateManager

        setupObservers()
    }

    private func setupObservers() {
        // Watch for settings changes (objectWillChange fires when any @Published/@AppStorage changes)
        settings.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.onSettingsChanged()
                }
            }
            .store(in: &cancellables)
    }

    private func onSettingsChanged() {
        // Re-evaluate automation rules when settings change
    }

    /// Start all automation monitoring
    func startMonitoring() {
        startAppMonitoring()
        startScheduleMonitoring()
        startBatteryMonitoring()
        startHardwareMonitoring()
        setupKeyboardShortcut()

        // Initialize hardware state
        wasOnPower = !CaffeinateManager.isOnBattery()
        hadExternalDisplay = hasExternalDisplay()

        logger.info("Automation monitoring started")
    }

    /// Stop all automation monitoring
    func stopMonitoring() {
        stopAppMonitoring()
        stopScheduleMonitoring()
        stopBatteryMonitoring()
        stopHardwareMonitoring()
        removeKeyboardShortcut()

        logger.info("Automation monitoring stopped")
    }

    // MARK: - App Trigger Monitoring

    private func startAppMonitoring() {
        // Monitor app launches
        appObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                self?.handleAppLaunch(notification)
            }
        }

        // Monitor app terminations
        appTerminateObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                self?.handleAppTerminate(notification)
            }
        }

        // Check currently running apps
        checkRunningApps()
    }

    private func stopAppMonitoring() {
        if let observer = appObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            appObserver = nil
        }
        if let observer = appTerminateObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            appTerminateObserver = nil
        }
    }

    private func handleAppLaunch(_ notification: Notification) {
        guard settings.appTriggersEnabled else { return }
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }

        // Check if this app is in our trigger list
        if let trigger = settings.appTriggers.first(where: { $0.bundleIdentifier == bundleId && $0.isEnabled }) {
            logger.info("Trigger app launched: \(trigger.appName)")
            activateForApp(trigger.appName)
        }
    }

    private func handleAppTerminate(_ notification: Notification) {
        guard settings.appTriggersEnabled else { return }
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }

        // Check if this was our trigger app
        if let trigger = settings.appTriggers.first(where: { $0.bundleIdentifier == bundleId && $0.isEnabled }),
           triggeredByApp == trigger.appName {
            logger.info("Trigger app terminated: \(trigger.appName)")
            deactivateForApp()
        }
    }

    private func checkRunningApps() {
        guard settings.appTriggersEnabled else { return }

        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            guard let bundleId = app.bundleIdentifier else { continue }

            if let trigger = settings.appTriggers.first(where: { $0.bundleIdentifier == bundleId && $0.isEnabled }) {
                logger.info("Trigger app already running: \(trigger.appName)")
                activateForApp(trigger.appName)
                break
            }
        }
    }

    private func activateForApp(_ appName: String) {
        guard !appState.isActive else { return }

        triggeredByApp = appName
        appState.activate(with: settings.defaultPreset)
        caffeinateManager.start(
            duration: settings.defaultPreset.seconds,
            allowDisplaySleep: settings.allowDisplaySleep,
            reason: .appTrigger(appName: appName)
        )
    }

    private func deactivateForApp() {
        guard triggeredByApp != nil else { return }

        triggeredByApp = nil

        // Only deactivate if it was triggered by app (not manual)
        if caffeinateManager.activationReason?.description.starts(with: "App:") == true {
            appState.deactivate()
            caffeinateManager.stop()
        }
    }

    // MARK: - Schedule Monitoring

    private func startScheduleMonitoring() {
        // Check schedule every minute
        scheduleTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkSchedule()
            }
        }

        // Check immediately
        checkSchedule()
    }

    private func stopScheduleMonitoring() {
        scheduleTimer?.invalidate()
        scheduleTimer = nil
    }

    private func checkSchedule() {
        guard settings.schedulesEnabled else {
            if activatedBySchedule {
                deactivateForSchedule()
            }
            return
        }

        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)

        var shouldBeActive = false

        for schedule in settings.schedules where schedule.isEnabled {
            // Check if today is in the schedule's days
            guard let weekday = ScheduleEntry.Weekday(rawValue: currentWeekday),
                  schedule.days.contains(weekday) else { continue }

            // Check if current time is within the schedule
            let startComponents = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: schedule.endTime)

            let currentMinutes = (currentTime.hour ?? 0) * 60 + (currentTime.minute ?? 0)
            let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
            let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)

            if currentMinutes >= startMinutes && currentMinutes < endMinutes {
                shouldBeActive = true
                break
            }
        }

        if shouldBeActive && !activatedBySchedule && !appState.isActive {
            activateForSchedule()
        } else if !shouldBeActive && activatedBySchedule {
            deactivateForSchedule()
        }
    }

    private func activateForSchedule() {
        activatedBySchedule = true
        appState.activate(with: .indefinite)
        caffeinateManager.start(
            duration: nil,
            allowDisplaySleep: settings.allowDisplaySleep,
            reason: .schedule
        )
        logger.info("Activated by schedule")
    }

    private func deactivateForSchedule() {
        guard activatedBySchedule else { return }
        activatedBySchedule = false

        if caffeinateManager.activationReason == .schedule {
            appState.deactivate()
            caffeinateManager.stop()
            logger.info("Deactivated by schedule end")
        }
    }

    // MARK: - Battery Monitoring

    private func startBatteryMonitoring() {
        // Check battery every 30 seconds
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkBattery()
            }
        }

        // Check immediately
        checkBattery()
    }

    private func stopBatteryMonitoring() {
        batteryTimer?.invalidate()
        batteryTimer = nil
    }

    private func checkBattery() {
        batteryLevel = CaffeinateManager.getBatteryLevel()

        guard settings.batteryProtectionEnabled,
              appState.isActive,
              let level = batteryLevel,
              level <= settings.batteryThreshold else {
            stoppedByBattery = false
            return
        }

        // Battery is low, stop to preserve battery
        logger.warning("Battery low (\(level)%), stopping sleep prevention")
        stoppedByBattery = true
        appState.deactivate()
        caffeinateManager.stop()

        // Send notification if enabled
        if settings.notifyOnBatteryStop {
            NotificationManager.shared.sendBatteryProtectionNotification(batteryLevel: level)
        }
    }

    // MARK: - Hardware Trigger Monitoring

    private func startHardwareMonitoring() {
        // Check hardware state every 5 seconds
        hardwareTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkHardware()
            }
        }
    }

    private func stopHardwareMonitoring() {
        hardwareTimer?.invalidate()
        hardwareTimer = nil
    }

    private func checkHardware() {
        guard settings.hardwareTriggersEnabled else {
            if activatedByHardware {
                deactivateForHardware()
            }
            return
        }

        let isOnPower = !CaffeinateManager.isOnBattery()
        let hasExternal = hasExternalDisplay()

        // Power adapter connected
        if settings.activateOnPowerConnect && isOnPower && !wasOnPower {
            logger.info("Power adapter connected")
            if !appState.isActive {
                activateForHardware(reason: "Power connected")
            }
        }

        // Switched to battery
        if settings.deactivateOnBattery && !isOnPower && wasOnPower {
            logger.info("Switched to battery power")
            if activatedByHardware {
                deactivateForHardware()
            }
        }

        // External display connected
        if settings.activateOnExternalDisplay && hasExternal && !hadExternalDisplay {
            logger.info("External display connected")
            if !appState.isActive {
                activateForHardware(reason: "External display")
            }
        }

        // External display disconnected
        if !hasExternal && hadExternalDisplay && activatedByHardware {
            logger.info("External display disconnected")
            deactivateForHardware()
        }

        wasOnPower = isOnPower
        hadExternalDisplay = hasExternal
    }

    private func hasExternalDisplay() -> Bool {
        NSScreen.screens.count > 1
    }

    private func activateForHardware(reason: String) {
        activatedByHardware = true
        appState.activate(with: .indefinite)
        caffeinateManager.start(
            duration: nil,
            allowDisplaySleep: settings.allowDisplaySleep,
            reason: .hardwareTrigger(type: reason)
        )
    }

    private func deactivateForHardware() {
        guard activatedByHardware else { return }
        activatedByHardware = false

        if case .hardwareTrigger = caffeinateManager.activationReason {
            appState.deactivate()
            caffeinateManager.stop()
            logger.info("Deactivated by hardware change")
        }
    }

    // MARK: - Keyboard Shortcut

    private func setupKeyboardShortcut() {
        guard settings.keyboardShortcutEnabled else { return }

        KeyboardShortcutManager.shared.onToggle = { [weak self] in
            Task { @MainActor [weak self] in
                self?.toggleViaShortcut()
            }
        }

        KeyboardShortcutManager.shared.startListening()
    }

    private func removeKeyboardShortcut() {
        KeyboardShortcutManager.shared.stopListening()
        KeyboardShortcutManager.shared.onToggle = nil
    }

    private func toggleViaShortcut() {
        if appState.isActive {
            appState.deactivate()
            caffeinateManager.stop()
            logger.info("Toggled OFF via keyboard shortcut")
        } else {
            appState.activate(with: settings.defaultPreset)
            caffeinateManager.start(
                duration: settings.defaultPreset.seconds,
                allowDisplaySleep: settings.allowDisplaySleep,
                reason: .keyboardShortcut
            )
            logger.info("Toggled ON via keyboard shortcut")
        }
    }

    /// Called when app state changes
    func onAppStateChanged() {
        // Re-evaluate automation rules when app state changes
    }
}
