//
//  TimerPreset.swift
//  AwakeApp
//
//  Duration presets for sleep prevention timer
//

import Foundation

enum TimerPreset: CaseIterable, Identifiable {
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case twoHours
    case fiveHours
    case indefinite

    var id: Self { self }

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
        }
    }
}
