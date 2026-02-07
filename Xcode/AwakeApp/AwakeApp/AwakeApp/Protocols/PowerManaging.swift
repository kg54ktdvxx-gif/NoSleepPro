//
//  PowerManaging.swift
//  AwakeApp
//
//  Protocol for power management operations - enables testing with mock implementations
//

import Foundation

/// Protocol for power management operations
/// Conforming types can start/stop sleep prevention and report status
@MainActor
protocol PowerManaging {
    /// Start preventing sleep
    /// - Parameters:
    ///   - duration: Duration in seconds, or nil for indefinite
    ///   - allowDisplaySleep: If true, display can sleep but system stays awake
    ///   - reason: Why sleep prevention was activated
    func start(duration: Int?, allowDisplaySleep: Bool, reason: ActivationReason)
    
    /// Stop preventing sleep
    func stop()
    
    /// Whether sleep prevention is currently active
    var isRunning: Bool { get }
    
    /// Reason for current activation, nil if not active
    var activationReason: ActivationReason? { get }
}
