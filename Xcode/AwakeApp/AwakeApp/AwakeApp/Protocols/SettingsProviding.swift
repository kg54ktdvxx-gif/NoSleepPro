//
//  SettingsProviding.swift
//  AwakeApp
//
//  Protocol for app settings access - enables testing with mock settings
//

import Foundation

/// Protocol for app settings access
/// Conforming types provide read/write access to app preferences
@MainActor
protocol SettingsProviding: AnyObject {
    // MARK: - Display Options
    var allowDisplaySleep: Bool { get set }
    var showMenuBarCountdown: Bool { get set }

    // MARK: - Notifications
    var notifyOnTimerEnd: Bool { get set }
    var notifyOnBatteryStop: Bool { get set }

    // MARK: - Battery Protection
    var batteryProtectionEnabled: Bool { get set }
    var batteryThreshold: Int { get set }

    // MARK: - Keyboard Shortcut
    var keyboardShortcutEnabled: Bool { get set }
    var defaultPreset: TimerPreset { get set }

    // MARK: - Hardware Triggers
    var hardwareTriggersEnabled: Bool { get set }
    var activateOnPowerConnect: Bool { get set }
    var deactivateOnBattery: Bool { get set }
    var activateOnExternalDisplay: Bool { get set }

    // MARK: - Menu Bar
    var menuBarIconStyle: MenuBarIconStyle { get set }

    // MARK: - Automation
    var appTriggers: [AppTrigger] { get set }
    var schedules: [ScheduleEntry] { get set }
    var schedulesEnabled: Bool { get set }
    var appTriggersEnabled: Bool { get set }
}

// MARK: - AppSettings Conformance

extension AppSettings: SettingsProviding {}
