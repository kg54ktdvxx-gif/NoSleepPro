//
//  ShortcutManaging.swift
//  AwakeApp
//
//  Protocol for keyboard shortcuts - enables testing without NSEvent
//

import Foundation

/// Protocol for keyboard shortcut management
/// Conforming types can listen for and manage global keyboard shortcuts
@MainActor
protocol ShortcutManaging: AnyObject {
    /// The current keyboard shortcut
    var currentShortcut: KeyboardShortcut { get set }

    /// Whether recording a new shortcut
    var isRecording: Bool { get }

    /// Whether currently listening for shortcuts
    var isListening: Bool { get }

    /// Last error that occurred, if any
    var lastError: KeyboardShortcutError? { get }

    /// Callback when shortcut is triggered
    var onToggle: (() -> Void)? { get set }

    /// Start listening for the keyboard shortcut
    /// - Returns: Result indicating success or error
    @discardableResult
    func startListening() -> Result<Void, KeyboardShortcutError>

    /// Stop listening for keyboard shortcuts
    func stopListening()

    /// Start recording a new shortcut
    /// - Parameter completion: Called with the recorded shortcut
    func startRecording(completion: @escaping (KeyboardShortcut) -> Void)

    /// Cancel recording without saving
    func cancelRecording()

    /// Reset to default shortcut
    func resetToDefault()
}

// MARK: - KeyboardShortcutManager Conformance

extension KeyboardShortcutManager: ShortcutManaging {}
