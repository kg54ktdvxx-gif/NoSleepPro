//
//  KeyboardShortcutManager.swift
//  AwakeApp
//
//  Manages global keyboard shortcuts using Carbon RegisterEventHotKey API.
//  This approach does NOT require accessibility permissions and is App Store approved.
//

import Foundation
import Combine
import Carbon.HIToolbox
import AppKit
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "thisisvision.AwakeApp", category: "KeyboardShortcut")

/// Represents a keyboard shortcut combination
struct KeyboardShortcut: Codable, Equatable {
    var keyCode: UInt16
    var modifiers: UInt // NSEvent.ModifierFlags raw value

    /// Default shortcut: ⌘⇧A
    static let `default` = Self(
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

    /// Convert NSEvent modifier flags to Carbon modifier flags
    var carbonModifiers: UInt32 {
        var carbonMods: UInt32 = 0
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)

        if flags.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if flags.contains(.option) { carbonMods |= UInt32(optionKey) }
        if flags.contains(.control) { carbonMods |= UInt32(controlKey) }
        if flags.contains(.shift) { carbonMods |= UInt32(shiftKey) }

        return carbonMods
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
            UInt16(kVK_F12): "F12"
        ]

        return keyMap[keyCode]
    }
}

// MARK: - Carbon Hotkey ID

/// Unique hotkey signature for this app
private let kHotKeySignature: FourCharCode = {
    let chars: [UInt8] = [0x4E, 0x53, 0x4C, 0x50] // "NSLP" for No Sleep Pro
    return FourCharCode(chars[0]) << 24 | FourCharCode(chars[1]) << 16 | FourCharCode(chars[2]) << 8 | FourCharCode(chars[3])
}()

private let kHotKeyID: UInt32 = 1

/// Global reference to the shared manager for the Carbon callback
private weak var _sharedManager: KeyboardShortcutManager?

@MainActor
class KeyboardShortcutManager: ObservableObject {
    static let shared = KeyboardShortcutManager()

    @Published var currentShortcut: KeyboardShortcut = .default
    @Published var isRecording = false
    @Published var isListening = false
    @Published var lastError: KeyboardShortcutError?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var localMonitor: Any?
    private var recordingCallback: ((KeyboardShortcut) -> Void)?

    var onToggle: (() -> Void)?

    private init() {
        loadShortcut()
        _sharedManager = self
    }

    /// Start listening for the global keyboard shortcut using Carbon API
    /// - Returns: Result indicating success or failure
    @discardableResult
    func startListening() -> Result<Void, KeyboardShortcutError> {
        stopListening()
        lastError = nil

        // Register the Carbon hotkey
        let result = registerCarbonHotKey()

        if case .failure(let error) = result {
            lastError = error
            isListening = false
            logger.error("Failed to register hotkey: \(error.localizedDescription)")
            return .failure(error)
        }

        isListening = true
        logger.info("Keyboard shortcut listening started: \(self.currentShortcut.displayString)")
        return .success(())
    }

    /// Stop listening for keyboard shortcuts
    func stopListening() {
        // Remove in reverse order of registration: hotkey first, then handler
        unregisterCarbonHotKey()

        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }

        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }

        isListening = false
    }

    /// Start recording a new shortcut
    func startRecording(completion: @escaping (KeyboardShortcut) -> Void) {
        isRecording = true
        recordingCallback = completion

        // Use a local monitor to capture the next keypress while recording
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                self?.handleRecordingEvent(event)
            }
            return nil // Consume the event during recording
        }
    }

    /// Cancel recording
    func cancelRecording() {
        isRecording = false
        recordingCallback = nil

        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    /// Reset to default shortcut
    func resetToDefault() {
        let wasListening = isListening
        if wasListening { stopListening() }

        currentShortcut = .default
        saveShortcut()

        if wasListening { startListening() }
    }

    // MARK: - Carbon Hotkey Registration

    private func registerCarbonHotKey() -> Result<Void, KeyboardShortcutError> {
        // Install event handler if not already installed
        if eventHandlerRef == nil {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )

            let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
                guard let event = event else { return OSStatus(eventNotHandledErr) }

                var hotKeyID = EventHotKeyID()
                let result = GetEventParameter(
                    event,
                    UInt32(kEventParamDirectObject),
                    UInt32(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard result == noErr else {
                    return OSStatus(eventNotHandledErr)
                }

                DispatchQueue.main.async {
                    _sharedManager?.hotKeyPressed()
                }

                return noErr
            }

            let status = InstallEventHandler(
                GetApplicationEventTarget(),
                handler,
                1,
                &eventType,
                nil,
                &eventHandlerRef
            )

            guard status == noErr else {
                return .failure(.registrationFailed)
            }
        }

        // Register the hotkey
        let hotKeyID = EventHotKeyID(signature: kHotKeySignature, id: kHotKeyID)

        let status = RegisterEventHotKey(
            UInt32(currentShortcut.keyCode),
            currentShortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else {
            return .failure(.registrationFailed)
        }

        return .success(())
    }

    private func unregisterCarbonHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    // MARK: - Event Handling

    /// Called from the Carbon callback when the hotkey is pressed
    fileprivate func hotKeyPressed() {
        guard !isRecording else { return }

        logger.info("Shortcut triggered: \(self.currentShortcut.displayString)")
        onToggle?()
    }

    /// Handle key event during shortcut recording
    private func handleRecordingEvent(_ event: NSEvent) {
        guard isRecording else { return }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Require at least Command or Control
        guard modifiers.contains(.command) || modifiers.contains(.control) else { return }

        let newShortcut = KeyboardShortcut(
            keyCode: event.keyCode,
            modifiers: modifiers.rawValue
        )

        // Stop recording
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }

        // Re-register with new shortcut
        let wasListening = isListening
        if wasListening { stopListening() }

        currentShortcut = newShortcut
        saveShortcut()
        isRecording = false
        recordingCallback?(newShortcut)
        recordingCallback = nil

        if wasListening { startListening() }

        logger.info("New shortcut recorded: \(newShortcut.displayString)")
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

