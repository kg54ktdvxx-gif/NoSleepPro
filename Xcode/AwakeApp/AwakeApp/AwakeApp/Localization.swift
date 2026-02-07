//
//  Localization.swift
//  AwakeApp
//
//  Localization helpers and String extensions
//

import Foundation
import SwiftUI

// MARK: - String Extension

extension String {
    /// Returns localized string using self as key
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Returns localized string with arguments
    func localized(_ arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}

// MARK: - Localized Keys

/// Type-safe localization keys
enum L10n {
    // MARK: - App
    enum App {
        static let name = "app.name".localized
        static let tagline = "app.tagline".localized
    }

    // MARK: - Menu Bar
    enum MenuBar {
        static let active = "menubar.active".localized
        static let inactive = "menubar.inactive".localized
        static let remaining = "menubar.remaining".localized
        static let runningIndefinitely = "menubar.running_indefinitely".localized
    }

    // MARK: - Duration
    enum Duration {
        static let title = "duration.title".localized
        static let minutes = "duration.minutes".localized
        static let hours = "duration.hours".localized
        static let forever = "duration.forever".localized
        static let customPrompt = "duration.custom_prompt".localized
        static let customTitle = "duration.custom_title".localized
        static let enterMinutes = "duration.enter_minutes".localized
    }

    // MARK: - Actions
    enum Action {
        static let stopTimer = "action.stop_timer".localized
        static let start = "action.start".localized
        static let cancel = "action.cancel".localized
        static let add = "action.add".localized
        static let quit = "action.quit".localized
        static let grant = "action.grant".localized
        static let reset = "action.reset".localized
    }

    // MARK: - Settings
    enum Settings {
        static let title = "settings.title".localized
        static let general = "settings.general".localized
        static let automation = "settings.automation".localized
        static let schedule = "settings.schedule".localized
        static let apps = "settings.apps".localized

        enum Display {
            static let options = "settings.display_options".localized
            static let menuBarIcon = "settings.menubar_icon".localized
            static let showCountdown = "settings.show_countdown".localized
            static let allowDisplaySleep = "settings.allow_display_sleep".localized
            static let launchAtLogin = "settings.launch_at_login".localized
        }

        enum Notifications {
            static let title = "settings.notifications".localized
            static let timerEnd = "settings.notify_timer_end".localized
            static let battery = "settings.notify_battery".localized
        }

        enum Shortcut {
            static let title = "settings.keyboard_shortcut".localized
            static let enable = "settings.enable_shortcut".localized
            static let shortcut = "settings.shortcut".localized
            static let defaultDuration = "settings.default_duration".localized
            static let pressShortcut = "settings.press_shortcut".localized
        }

        enum Jiggler {
            static let title = "settings.mouse_jiggler".localized
            static let enable = "settings.enable_jiggler".localized
            static let interval = "settings.jiggle_interval".localized
            static let description = "settings.jiggler_description".localized
            static let accessibilityGranted = "settings.accessibility_granted".localized
            static let accessibilityRequired = "settings.accessibility_required".localized
        }

        enum Battery {
            static let protection = "settings.battery_protection".localized
            static let enable = "settings.enable_battery".localized
            static let threshold = "settings.battery_threshold".localized
            static let description = "settings.battery_description".localized
            static func current(_ level: Int) -> String {
                "settings.battery_current".localized(level)
            }
            static let connectedToPower = "settings.connected_to_power".localized
        }

        enum Hardware {
            static let triggers = "settings.hardware_triggers".localized
            static let enable = "settings.enable_hardware".localized
            static let activatePower = "settings.activate_power".localized
            static let deactivateBattery = "settings.deactivate_battery".localized
            static let activateDisplay = "settings.activate_display".localized
            static let description = "settings.hardware_description".localized
        }

        enum Schedule {
            static let enable = "settings.enable_schedules".localized
            static let add = "settings.add_schedule".localized
            static let none = "settings.no_schedules".localized
            static let description = "settings.schedules_description".localized
            static let days = "schedule.days".localized
            static let startTime = "schedule.start_time".localized
            static let endTime = "schedule.end_time".localized
        }

        enum AppTriggers {
            static let enable = "settings.enable_app_triggers".localized
            static let add = "settings.add_app".localized
            static let none = "settings.no_app_triggers".localized
            static let description = "settings.app_triggers_description".localized
            static let selectTitle = "settings.select_app".localized
            static let selectDescription = "settings.select_app_description".localized
        }
    }

    // MARK: - Icon Picker
    enum Icon {
        static let chooseStyle = "icon.choose_style".localized
        static let previewNote = "icon.preview_note".localized
    }

    // MARK: - Automation
    enum Auto {
        static let manual = "auto.manual".localized
        static let schedule = "auto.schedule".localized
        static func app(_ name: String) -> String {
            "auto.app".localized(name)
        }
        static let shortcut = "auto.shortcut".localized
        static func hardware(_ type: String) -> String {
            "auto.hardware".localized(type)
        }
        static let badge = "auto.badge".localized
    }

    // MARK: - Warnings
    enum Warning {
        static let batteryStopped = "warning.battery_stopped".localized
    }

    // MARK: - About
    enum About {
        static let title = "about.title".localized
        static func version(_ version: String) -> String {
            "about.version".localized(version)
        }
        static let description = "about.description".localized
        static let features = "about.features".localized
        static let madeWith = "about.made_with".localized

        enum Feature {
            static let timer = "about.feature.timer".localized
            static let schedule = "about.feature.schedule".localized
            static let battery = "about.feature.battery".localized
            static let shortcuts = "about.feature.shortcuts".localized
            static let triggers = "about.feature.triggers".localized
        }
    }

    // MARK: - Notifications
    enum Notification {
        static let timerEndedTitle = "notification.timer_ended.title".localized
        static func timerEndedBody(_ preset: String) -> String {
            "notification.timer_ended.body".localized(preset)
        }
        static let batteryTitle = "notification.battery.title".localized
        static func batteryBody(_ level: Int) -> String {
            "notification.battery.body".localized(level)
        }
    }
}

// MARK: - SwiftUI Text Extension

extension Text {
    /// Create Text view with localized string key
    init(l10n key: String) {
        self.init(key.localized)
    }
}
