//
//  KeyboardShortcutTests.swift
//  AwakeAppTests
//
//  Unit tests for KeyboardShortcut struct
//

import XCTest
import Carbon.HIToolbox
@testable import AwakeApp

final class KeyboardShortcutTests: XCTestCase {

    // MARK: - Default Shortcut Tests

    func testDefaultShortcut() {
        let shortcut = KeyboardShortcut.default

        XCTAssertEqual(shortcut.keyCode, UInt16(kVK_ANSI_A))
    }

    func testDefaultShortcutDisplayString() {
        let shortcut = KeyboardShortcut.default

        // Should contain Command and Shift symbols and A
        XCTAssertTrue(shortcut.displayString.contains("⌘"))
        XCTAssertTrue(shortcut.displayString.contains("⇧"))
        XCTAssertTrue(shortcut.displayString.contains("A"))
    }

    // MARK: - Display String Tests

    func testDisplayStringWithAllModifiers() {
        let modifiers = NSEvent.ModifierFlags([.control, .option, .shift, .command])
        let shortcut = KeyboardShortcut(keyCode: UInt16(kVK_ANSI_A), modifiers: modifiers.rawValue)

        let display = shortcut.displayString
        XCTAssertTrue(display.contains("⌃")) // Control
        XCTAssertTrue(display.contains("⌥")) // Option
        XCTAssertTrue(display.contains("⇧")) // Shift
        XCTAssertTrue(display.contains("⌘")) // Command
        XCTAssertTrue(display.contains("A"))
    }

    func testDisplayStringModifierOrder() {
        // Modifiers should appear in order: Control, Option, Shift, Command
        let modifiers = NSEvent.ModifierFlags([.control, .option, .shift, .command])
        let shortcut = KeyboardShortcut(keyCode: UInt16(kVK_ANSI_A), modifiers: modifiers.rawValue)

        let display = shortcut.displayString
        let controlIndex = display.firstIndex(of: "⌃")!
        let optionIndex = display.firstIndex(of: "⌥")!
        let shiftIndex = display.firstIndex(of: "⇧")!
        let commandIndex = display.firstIndex(of: "⌘")!

        XCTAssertLessThan(controlIndex, optionIndex)
        XCTAssertLessThan(optionIndex, shiftIndex)
        XCTAssertLessThan(shiftIndex, commandIndex)
    }

    // MARK: - Key Code Mapping Tests

    func testLetterKeyCodes() {
        let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
                       "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

        for letter in letters {
            // Find the key code for this letter
            let keyCodes: [String: UInt16] = [
                "A": UInt16(kVK_ANSI_A), "B": UInt16(kVK_ANSI_B), "C": UInt16(kVK_ANSI_C),
                "D": UInt16(kVK_ANSI_D), "E": UInt16(kVK_ANSI_E), "F": UInt16(kVK_ANSI_F),
                "G": UInt16(kVK_ANSI_G), "H": UInt16(kVK_ANSI_H), "I": UInt16(kVK_ANSI_I),
                "J": UInt16(kVK_ANSI_J), "K": UInt16(kVK_ANSI_K), "L": UInt16(kVK_ANSI_L),
                "M": UInt16(kVK_ANSI_M), "N": UInt16(kVK_ANSI_N), "O": UInt16(kVK_ANSI_O),
                "P": UInt16(kVK_ANSI_P), "Q": UInt16(kVK_ANSI_Q), "R": UInt16(kVK_ANSI_R),
                "S": UInt16(kVK_ANSI_S), "T": UInt16(kVK_ANSI_T), "U": UInt16(kVK_ANSI_U),
                "V": UInt16(kVK_ANSI_V), "W": UInt16(kVK_ANSI_W), "X": UInt16(kVK_ANSI_X),
                "Y": UInt16(kVK_ANSI_Y), "Z": UInt16(kVK_ANSI_Z)
            ]

            if let keyCode = keyCodes[letter] {
                let shortcut = KeyboardShortcut(keyCode: keyCode, modifiers: NSEvent.ModifierFlags.command.rawValue)
                XCTAssertTrue(shortcut.displayString.contains(letter), "Display string should contain \(letter)")
            }
        }
    }

    func testSpecialKeyCodes() {
        let specialKeys: [(keyCode: Int, expected: String)] = [
            (kVK_Space, "Space"),
            (kVK_Return, "↩"),
            (kVK_Tab, "⇥"),
            (kVK_Delete, "⌫"),
            (kVK_Escape, "⎋"),
        ]

        for (keyCode, expected) in specialKeys {
            let shortcut = KeyboardShortcut(keyCode: UInt16(keyCode), modifiers: NSEvent.ModifierFlags.command.rawValue)
            XCTAssertTrue(shortcut.displayString.contains(expected), "Display string should contain \(expected)")
        }
    }

    func testFunctionKeyCodes() {
        let functionKeys: [(keyCode: Int, expected: String)] = [
            (kVK_F1, "F1"), (kVK_F2, "F2"), (kVK_F3, "F3"), (kVK_F4, "F4"),
            (kVK_F5, "F5"), (kVK_F6, "F6"), (kVK_F7, "F7"), (kVK_F8, "F8"),
            (kVK_F9, "F9"), (kVK_F10, "F10"), (kVK_F11, "F11"), (kVK_F12, "F12"),
        ]

        for (keyCode, expected) in functionKeys {
            let shortcut = KeyboardShortcut(keyCode: UInt16(keyCode), modifiers: NSEvent.ModifierFlags.command.rawValue)
            XCTAssertTrue(shortcut.displayString.contains(expected), "Display string should contain \(expected)")
        }
    }

    // MARK: - Codable Tests

    func testCodable() throws {
        let shortcut = KeyboardShortcut.default
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(shortcut)
        let decoded = try decoder.decode(KeyboardShortcut.self, from: data)

        XCTAssertEqual(shortcut.keyCode, decoded.keyCode)
        XCTAssertEqual(shortcut.modifiers, decoded.modifiers)
    }

    // MARK: - Equatable Tests

    func testEquatable() {
        let shortcut1 = KeyboardShortcut.default
        let shortcut2 = KeyboardShortcut.default
        let shortcut3 = KeyboardShortcut(keyCode: UInt16(kVK_ANSI_B), modifiers: NSEvent.ModifierFlags.command.rawValue)

        XCTAssertEqual(shortcut1, shortcut2)
        XCTAssertNotEqual(shortcut1, shortcut3)
    }
}
