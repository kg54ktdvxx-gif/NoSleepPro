//
//  MouseJiggling.swift
//  AwakeApp
//
//  Protocol for mouse jiggler - enables testing without accessibility permissions
//

import Foundation

/// Protocol for mouse jiggler operations
/// Conforming types can jiggle the mouse to prevent "Away" status
@MainActor
protocol MouseJiggling: AnyObject {
    /// Whether the jiggler is currently running
    var isRunning: Bool { get }

    /// Whether accessibility permission has been granted
    var hasAccessibilityPermission: Bool { get }

    /// Last error that occurred, if any
    var lastError: MouseJigglerError? { get }

    /// Start jiggling the mouse at the specified interval
    /// - Parameter intervalSeconds: Time between jiggles in seconds
    /// - Returns: Result indicating success or error
    @discardableResult
    func start(intervalSeconds: Double) -> Result<Void, MouseJigglerError>

    /// Stop jiggling the mouse
    func stop()

    /// Check if accessibility permission is granted
    func checkAccessibilityPermission()

    /// Request accessibility permission from the user
    func requestAccessibilityPermission()
}

// MARK: - MouseJiggler Conformance

extension MouseJiggler: MouseJiggling {}
