//
//  Settings.swift
//  AwakeApp
//
//  User preferences and settings storage using UserDefaults
//

import Foundation
import SwiftUI
import Combine

/// Schedule entry for automatic activation
struct ScheduleEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var isEnabled: Bool = true
    var days: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    var startTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    var endTime: Date = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()

    enum Weekday: Int, Codable, CaseIterable, Identifiable {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

        var id: Int { rawValue }

        var shortName: String {
            switch self {
            case .sunday: return "Sun"
            case .monday: return "Mon"
            case .tuesday: return "Tue"
            case .wednesday: return "Wed"
            case .thursday: return "Thu"
            case .friday: return "Fri"
            case .saturday: return "Sat"
            }
        }

        var initial: String {
            switch self {
            case .sunday: return "S"
            case .monday: return "M"
            case .tuesday: return "T"
            case .wednesday: return "W"
            case .thursday: return "T"
            case .friday: return "F"
            case .saturday: return "S"
            }
        }
    }
}

/// App trigger configuration
struct AppTrigger: Codable, Identifiable, Equatable {
    var id = UUID()
    var bundleIdentifier: String
    var appName: String
    var isEnabled: Bool = true
}

/// Global app settings manager
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - Display Options

    /// Allow display to sleep while preventing system sleep
    @AppStorage("allowDisplaySleep") var allowDisplaySleep: Bool = false

    /// Show countdown in menu bar
    @AppStorage("showMenuBarCountdown") var showMenuBarCountdown: Bool = true

    // MARK: - Notifications

    /// Send notification when timer ends
    @AppStorage("notifyOnTimerEnd") var notifyOnTimerEnd: Bool = true

    /// Send notification when battery protection triggers
    @AppStorage("notifyOnBatteryStop") var notifyOnBatteryStop: Bool = true

    // MARK: - Battery Protection

    /// Enable battery threshold protection
    @AppStorage("batteryProtectionEnabled") var batteryProtectionEnabled: Bool = true

    /// Battery percentage threshold (stop when below this)
    @AppStorage("batteryThreshold") var batteryThreshold: Int = 20

    // MARK: - Keyboard Shortcut

    /// Enable global keyboard shortcut
    @AppStorage("keyboardShortcutEnabled") var keyboardShortcutEnabled: Bool = true

    /// Default preset to use when toggling via keyboard
    @AppStorage("defaultPresetRawValue") private var defaultPresetRawValue: Int = 5 // indefinite

    var defaultPreset: TimerPreset {
        get { TimerPreset.allCases[safe: defaultPresetRawValue] ?? .indefinite }
        set { defaultPresetRawValue = TimerPreset.allCases.firstIndex(of: newValue) ?? 5 }
    }

    // MARK: - Hardware Triggers

    /// Activate when power adapter is connected
    @AppStorage("activateOnPowerConnect") var activateOnPowerConnect: Bool = false

    /// Deactivate when switching to battery
    @AppStorage("deactivateOnBattery") var deactivateOnBattery: Bool = false

    /// Activate when external display is connected
    @AppStorage("activateOnExternalDisplay") var activateOnExternalDisplay: Bool = false

    /// Enable hardware trigger-based activation
    @AppStorage("hardwareTriggersEnabled") var hardwareTriggersEnabled: Bool = false

    // MARK: - Custom Duration

    /// Last used custom duration in minutes
    @AppStorage("lastCustomDurationMinutes") var lastCustomDurationMinutes: Int = 45

    // MARK: - App Triggers

    /// Apps that trigger automatic activation
    @Published var appTriggers: [AppTrigger] = [] {
        didSet { saveAppTriggers() }
    }

    // MARK: - Schedules

    /// Schedule entries for automatic activation
    @Published var schedules: [ScheduleEntry] = [] {
        didSet { saveSchedules() }
    }

    /// Enable schedule-based activation
    @AppStorage("schedulesEnabled") var schedulesEnabled: Bool = false

    /// Enable app trigger-based activation
    @AppStorage("appTriggersEnabled") var appTriggersEnabled: Bool = false

    // MARK: - Launch at Login

    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false

    // MARK: - Menu Bar Appearance

    /// Menu bar icon style
    @AppStorage("menuBarIconStyleRaw") private var menuBarIconStyleRaw: String = MenuBarIconStyle.coffeeCup.rawValue

    var menuBarIconStyle: MenuBarIconStyle {
        get { MenuBarIconStyle(rawValue: menuBarIconStyleRaw) ?? .coffeeCup }
        set { menuBarIconStyleRaw = newValue.rawValue }
    }

    // MARK: - Initialization

    private init() {
        loadAppTriggers()
        loadSchedules()
    }

    // MARK: - Persistence Helpers

    private func saveAppTriggers() {
        if let encoded = try? JSONEncoder().encode(appTriggers) {
            UserDefaults.standard.set(encoded, forKey: "appTriggers")
        }
    }

    private func loadAppTriggers() {
        if let data = UserDefaults.standard.data(forKey: "appTriggers"),
           let decoded = try? JSONDecoder().decode([AppTrigger].self, from: data) {
            appTriggers = decoded
        } else {
            // Default app triggers
            appTriggers = [
                AppTrigger(bundleIdentifier: "us.zoom.xos", appName: "Zoom", isEnabled: true),
                AppTrigger(bundleIdentifier: "com.microsoft.Powerpoint", appName: "PowerPoint", isEnabled: false),
                AppTrigger(bundleIdentifier: "com.apple.Keynote", appName: "Keynote", isEnabled: false),
                AppTrigger(bundleIdentifier: "com.google.Chrome", appName: "Chrome (presenting)", isEnabled: false)
            ]
        }
    }

    private func saveSchedules() {
        if let encoded = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(encoded, forKey: "schedules")
        }
    }

    private func loadSchedules() {
        if let data = UserDefaults.standard.data(forKey: "schedules"),
           let decoded = try? JSONDecoder().decode([ScheduleEntry].self, from: data) {
            schedules = decoded
        }
    }

    // MARK: - Preset App Triggers

    static let commonAppTriggers: [(bundleId: String, name: String)] = [
        ("us.zoom.xos", "Zoom"),
        ("com.microsoft.teams", "Microsoft Teams"),
        ("com.microsoft.Powerpoint", "PowerPoint"),
        ("com.apple.Keynote", "Keynote"),
        ("com.google.Chrome", "Google Chrome"),
        ("com.apple.Safari", "Safari"),
        ("com.netflix.Netflix", "Netflix"),
        ("com.spotify.client", "Spotify"),
        ("com.apple.FinalCut", "Final Cut Pro"),
        ("com.adobe.PremierePro", "Premiere Pro"),
        ("com.apple.Logic10", "Logic Pro"),
        ("com.vmware.fusion", "VMware Fusion"),
        ("com.parallels.desktop", "Parallels Desktop")
    ]
}

// MARK: - Safe Array Access

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
