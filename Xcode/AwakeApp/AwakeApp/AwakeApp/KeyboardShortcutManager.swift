//
//  KeyboardShortcutManager.swift
//  AwakeApp
//
//  Manages global keyboard shortcuts with customizable key combinations
//

import Foundation
import Carbon.HIToolbox
import AppKit
import os.log

private let logger = Logger(subsystem: "com.awakeapp", category: "KeyboardShortcut")

/// Represents a keyboard shortcut combination
struct KeyboardShortcut: Codable, Equatable {
    var keyCode: UInt16
    var modifiers: UInt // NSEvent.ModifierFlags raw value

    /// Default shortcut: ⌘⇧A
    static let `default` = KeyboardShortcut(
        keyCode: UInt16(kVK_ANSI_A),
        modifiers: NSEvent.ModifierFlags([.command, .shift]).rawValue
    )

    /// Human-readable description
    var displayString: String {
        var parts: [String] = []

        let flags = NSEvent.ModifierFlags(rawValue: modifiers)

        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }

        if let keyString = keyCodeToString(keyCode) {
            parts.append(keyString)
        }

        return parts.joined()
    }

    /// Convert key code to string representation
    private func keyCodeToString(_ keyCode: UInt16) -> String? {
        let keyMap: [UInt16: String] = [
            UInt16(kVK_ANSI_A): "A",
            UInt16(kVK_ANSI_S): "S",
            UInt16(kVK_ANSI_D): "D",
            UInt16(kVK_ANSI_F): "F",
            UInt16(kVK_ANSI_G): "G",
            UInt16(kVK_ANSI_H): "H",
            UInt16(kVK_ANSI_J): "J",
            UInt16(kVK_ANSI_K): "K",
            UInt16(kVK_ANSI_L): "L",
            UInt16(kVK_ANSI_Q): "Q",
            UInt16(kVK_ANSI_W): "W",
            UInt16(kVK_ANSI_E): "E",
            UInt16(kVK_ANSI_R): "R",
            UInt16(kVK_ANSI_T): "T",
            UInt16(kVK_ANSI_Y): "Y",
            UInt16(kVK_ANSI_U): "U",
            UInt16(kVK_ANSI_I): "I",
            UInt16(kVK_ANSI_O): "O",
            UInt16(kVK_ANSI_P): "P",
            UInt16(kVK_ANSI_Z): "Z",
            UInt16(kVK_ANSI_X): "X",
            UInt16(kVK_ANSI_C): "C",
            UInt16(kVK_ANSI_V): "V",
            UInt16(kVK_ANSI_B): "B",
            UInt16(kVK_ANSI_N): "N",
            UInt16(kVK_ANSI_M): "M",
            UInt16(kVK_ANSI_0): "0",
            UInt16(kVK_ANSI_1): "1",
            UInt16(kVK_ANSI_2): "2",
            UInt16(kVK_ANSI_3): "3",
            UInt16(kVK_ANSI_4): "4",
            UInt16(kVK_ANSI_5): "5",
            UInt16(kVK_ANSI_6): "6",
            UInt16(kVK_ANSI_7): "7",
            UInt16(kVK_ANSI_8): "8",
            UInt16(kVK_ANSI_9): "9",
            UInt16(kVK_Space): "Space",
            UInt16(kVK_Return): "↩",
            UInt16(kVK_Tab): "⇥",
            UInt16(kVK_Delete): "⌫",
            UInt16(kVK_Escape): "⎋",
            UInt16(kVK_F1): "F1",
            UInt16(kVK_F2): "F2",
            UInt16(kVK_F3): "F3",
            UInt16(kVK_F4): "F4",
            UInt16(kVK_F5): "F5",
            UInt16(kVK_F6): "F6",
            UInt16(kVK_F7): "F7",
            UInt16(kVK_F8): "F8",
            UInt16(kVK_F9): "F9",
            UInt16(kVK_F10): "F10",
            UInt16(kVK_F11): "F11",
            UInt16(kVK_F12): "F12",
        ]

        return keyMap[keyCode]
    }
}

@MainActor
class KeyboardShortcutManager: ObservableObject {
    static let shared = KeyboardShortcutManager()

    @Published var currentShortcut: KeyboardShortcut = .default
    @Published var isRecording = false
    @Published var isListening = false
    @Published var lastError: KeyboardShortcutError?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var recordingCallback: ((KeyboardShortcut) -> Void)?

    var onToggle: (() -> Void)?

    private init() {
        loadShortcut()
    }

    /// Start listening for the global keyboard shortcut
    /// - Returns: Result indicating success or failure
    @discardableResult
    func startListening() -> Result<Void, KeyboardShortcutError> {
        stopListening()
        lastError = nil

        // Global monitor (when app is not focused)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                self?.handleKeyEvent(event)
            }
        }

        // Local monitor (when app is focused)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                self?.handleKeyEvent(event)
            }
            return event
        }

        // Check if monitors were created successfully
        if globalMonitor == nil && localMonitor == nil {
            let error = KeyboardShortcutError.monitoringFailed
            lastError = error
            isListening = false
            logger.error("Failed to start keyboard monitoring")
            return .failure(error)
        }

        isListening = true
        logger.info("Keyboard shortcut listening started: \(self.currentShortcut.displayString)")
        return .success(())
    }

    /// Stop listening for keyboard shortcuts
    func stopListening() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        isListening = false
    }

    /// Handle incoming key event
    private func handleKeyEvent(_ event: NSEvent) {
        // If recording a new shortcut
        if isRecording {
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            // Require at least Command or Control
            guard modifiers.contains(.command) || modifiers.contains(.control) else { return }

            let newShortcut = KeyboardShortcut(
                keyCode: event.keyCode,
                modifiers: modifiers.rawValue
            )

            currentShortcut = newShortcut
            saveShortcut()
            isRecording = false
            recordingCallback?(newShortcut)
            recordingCallback = nil

            logger.info("New shortcut recorded: \(newShortcut.displayString)")
            return
        }

        // Check if event matches our shortcut
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let expectedModifiers = NSEvent.ModifierFlags(rawValue: currentShortcut.modifiers)

        if event.keyCode == currentShortcut.keyCode && modifiers == expectedModifiers {
            logger.info("Shortcut triggered: \(self.currentShortcut.displayString)")
            onToggle?()
        }
    }

    /// Start recording a new shortcut
    func startRecording(completion: @escaping (KeyboardShortcut) -> Void) {
        isRecording = true
        recordingCallback = completion
    }

    /// Cancel recording
    func cancelRecording() {
        isRecording = false
        recordingCallback = nil
    }

    /// Reset to default shortcut
    func resetToDefault() {
        currentShortcut = .default
        saveShortcut()
    }

    // MARK: - Persistence

    private func saveShortcut() {
        if let encoded = try? JSONEncoder().encode(currentShortcut) {
            UserDefaults.standard.set(encoded, forKey: "keyboardShortcut")
        }
    }

    private func loadShortcut() {
        if let data = UserDefaults.standard.data(forKey: "keyboardShortcut"),
           let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: data) {
            currentShortcut = decoded
        }
    }
}
