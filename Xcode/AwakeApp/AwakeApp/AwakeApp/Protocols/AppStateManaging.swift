//
//  AppStateManaging.swift
//  AwakeApp
//
//  Protocol for app state management - enables testing with mock implementations
//

import Foundation

/// Protocol for app state management
/// Conforming types track activation status and timer state
@MainActor
protocol AppStateManaging: AnyObject {
    /// Whether sleep prevention is currently active
    var isActive: Bool { get }
    
    /// Current timer preset, nil if not active
    var currentPreset: TimerPreset? { get }
    
    /// Remaining seconds for timed presets, nil for indefinite or inactive
    var remainingSeconds: Int? { get }

    /// Currently active scenario preset, nil if not in scenario mode
    var activeScenario: ScenarioPreset? { get }

    /// Activate sleep prevention with a timer preset
    func activate(with preset: TimerPreset)

    /// Activate sleep prevention with a scenario preset
    func activate(with scenario: ScenarioPreset)
    
    /// Deactivate sleep prevention
    func deactivate()
}
