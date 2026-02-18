//
//  ScenarioPreset.swift
//  AwakeApp
//
//  Named scenario presets for common use cases (Smart Modes)
//

import SwiftUI
import IOKit.pwr_mgt

/// Named scenario presets with correct power assertion behavior baked in
enum ScenarioPreset: String, CaseIterable, Identifiable, Equatable {
    /// Terminal sessions (overnight autonomous runs) — system stays awake, display can sleep
    case claudeCode

    /// Colab notebooks, large downloads — display AND system stay awake
    case browserActive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .browserActive: return "Browser Active"
        }
    }

    var subtitle: String {
        switch self {
        case .claudeCode: return "System awake, display sleeps"
        case .browserActive: return "Display & system stay awake"
        }
    }

    var iconName: String {
        switch self {
        case .claudeCode: return "terminal"
        case .browserActive: return "globe"
        }
    }

    var accentColor: Color {
        switch self {
        case .claudeCode: return .awakePurple
        case .browserActive: return .awakeOrange
        }
    }

    /// Whether the display is allowed to sleep in this scenario
    var allowDisplaySleep: Bool {
        switch self {
        case .claudeCode: return true
        case .browserActive: return false
        }
    }

    /// The IOKit assertion type string for this scenario
    var assertionType: String {
        switch self {
        case .claudeCode: return kIOPMAssertionTypeNoIdleSleep as String
        case .browserActive: return kIOPMAssertionTypeNoDisplaySleep as String
        }
    }
}
