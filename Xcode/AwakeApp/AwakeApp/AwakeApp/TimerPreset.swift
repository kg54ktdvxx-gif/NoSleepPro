//
//  TimerPreset.swift
//  AwakeApp
//
//  Duration presets for sleep prevention timer
//

import Foundation

enum TimerPreset: Equatable, Identifiable, Hashable {
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case twoHours
    case fiveHours
    case indefinite
    case custom(minutes: Int)

    var id: String {
        switch self {
        case .fifteenMinutes: return "15min"
        case .thirtyMinutes: return "30min"
        case .oneHour: return "1hr"
        case .twoHours: return "2hr"
        case .fiveHours: return "5hr"
        case .indefinite: return "indefinite"
        case .custom(let minutes): return "custom-\(minutes)"
        }
    }

    var displayName: String {
        switch self {
        case .fifteenMinutes:
            return "15 minutes"
        case .thirtyMinutes:
            return "30 minutes"
        case .oneHour:
            return "1 hour"
        case .twoHours:
            return "2 hours"
        case .fiveHours:
            return "5 hours"
        case .indefinite:
            return "Indefinite"
        case .custom(let minutes):
            if minutes >= 60 {
                let hours = minutes / 60
                let mins = minutes % 60
                if mins == 0 {
                    return "\(hours) hour\(hours == 1 ? "" : "s")"
                } else {
                    return "\(hours)h \(mins)m"
                }
            } else {
                return "\(minutes) minutes"
            }
        }
    }

    /// Short display name for menu bar
    var shortDisplayName: String {
        switch self {
        case .fifteenMinutes: return "15m"
        case .thirtyMinutes: return "30m"
        case .oneHour: return "1h"
        case .twoHours: return "2h"
        case .fiveHours: return "5h"
        case .indefinite: return "∞"
        case .custom(let minutes):
            if minutes >= 60 {
                let hours = minutes / 60
                let mins = minutes % 60
                return mins == 0 ? "\(hours)h" : "\(hours)h\(mins)m"
            } else {
                return "\(minutes)m"
            }
        }
    }

    /// Duration in seconds, or nil for indefinite
    var seconds: Int? {
        switch self {
        case .fifteenMinutes:
            return 15 * 60
        case .thirtyMinutes:
            return 30 * 60
        case .oneHour:
            return 60 * 60
        case .twoHours:
            return 2 * 60 * 60
        case .fiveHours:
            return 5 * 60 * 60
        case .indefinite:
            return nil
        case .custom(let minutes):
            return minutes * 60
        }
    }

    /// Duration in minutes, or nil for indefinite
    var minutes: Int? {
        switch self {
        case .fifteenMinutes: return 15
        case .thirtyMinutes: return 30
        case .oneHour: return 60
        case .twoHours: return 120
        case .fiveHours: return 300
        case .indefinite: return nil
        case .custom(let minutes): return minutes
        }
    }

    /// Standard presets (excluding custom)
    static var allCases: [TimerPreset] {
        [.fifteenMinutes, .thirtyMinutes, .oneHour, .twoHours, .fiveHours, .indefinite]
    }

    /// Check if this is a custom duration
    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }
}
