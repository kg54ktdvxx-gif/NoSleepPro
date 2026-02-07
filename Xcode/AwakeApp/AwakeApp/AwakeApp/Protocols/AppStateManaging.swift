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
    
    /// Activate sleep prevention with a timer preset
    func activate(with preset: TimerPreset)
    
    /// Deactivate sleep prevention
    func deactivate()
}
