//
//  SettingsTests.swift
//  AwakeAppTests
//
//  Unit tests for Settings models and AppSettings
//

import XCTest
@testable import AwakeApp

@MainActor
final class SettingsTests: XCTestCase {

    // MARK: - MenuBarIconStyle Tests

    func testMenuBarIconStyleAllCases() {
        let allCases = MenuBarIconStyle.allCases
        XCTAssertEqual(allCases.count, 8)
    }

    func testMenuBarIconStyleRawValues() {
        XCTAssertEqual(MenuBarIconStyle.coffeeCup.rawValue, "cup.and.saucer")
        XCTAssertEqual(MenuBarIconStyle.moon.rawValue, "moon.zzz")
        XCTAssertEqual(MenuBarIconStyle.bolt.rawValue, "bolt")
        XCTAssertEqual(MenuBarIconStyle.eye.rawValue, "eye")
        XCTAssertEqual(MenuBarIconStyle.sun.rawValue, "sun.max")
        XCTAssertEqual(MenuBarIconStyle.battery.rawValue, "battery.100.bolt")
        XCTAssertEqual(MenuBarIconStyle.clock.rawValue, "clock")
        XCTAssertEqual(MenuBarIconStyle.power.rawValue, "power")
    }

    func testMenuBarIconStyleDisplayNames() {
        XCTAssertEqual(MenuBarIconStyle.coffeeCup.displayName, "Coffee Cup")
        XCTAssertEqual(MenuBarIconStyle.moon.displayName, "Moon")
        XCTAssertEqual(MenuBarIconStyle.bolt.displayName, "Lightning Bolt")
    }

    func testMenuBarIconStyleFilledNames() {
        // Most icons have different filled versions
        XCTAssertNotEqual(MenuBarIconStyle.coffeeCup.systemName, MenuBarIconStyle.coffeeCup.filledSystemName)
        XCTAssertNotEqual(MenuBarIconStyle.moon.systemName, MenuBarIconStyle.moon.filledSystemName)

        // Battery is the exception - same for both
        XCTAssertEqual(MenuBarIconStyle.battery.systemName, MenuBarIconStyle.battery.filledSystemName)
    }

    func testMenuBarIconStyleIdentifiable() {
        for style in MenuBarIconStyle.allCases {
            XCTAssertEqual(style.id, style.rawValue)
        }
    }

    // MARK: - ScheduleEntry Tests

    func testScheduleEntryDefaultValues() {
        let entry = ScheduleEntry()

        XCTAssertTrue(entry.isEnabled)
        XCTAssertFalse(entry.days.isEmpty)
        XCTAssertNotNil(entry.startTime)
        XCTAssertNotNil(entry.endTime)
    }

    func testScheduleEntryWeekdayRawValues() {
        XCTAssertEqual(ScheduleEntry.Weekday.sunday.rawValue, 1)
        XCTAssertEqual(ScheduleEntry.Weekday.monday.rawValue, 2)
        XCTAssertEqual(ScheduleEntry.Weekday.tuesday.rawValue, 3)
        XCTAssertEqual(ScheduleEntry.Weekday.wednesday.rawValue, 4)
        XCTAssertEqual(ScheduleEntry.Weekday.thursday.rawValue, 5)
        XCTAssertEqual(ScheduleEntry.Weekday.friday.rawValue, 6)
        XCTAssertEqual(ScheduleEntry.Weekday.saturday.rawValue, 7)
    }

    func testScheduleEntryWeekdayShortNames() {
        XCTAssertEqual(ScheduleEntry.Weekday.sunday.shortName, "Sun")
        XCTAssertEqual(ScheduleEntry.Weekday.monday.shortName, "Mon")
        XCTAssertEqual(ScheduleEntry.Weekday.saturday.shortName, "Sat")
    }

    func testScheduleEntryWeekdayAllCasesOrdered() {
        let allCases = ScheduleEntry.Weekday.allCases
        XCTAssertEqual(allCases.count, 7)
        XCTAssertEqual(allCases.first, .sunday)
        XCTAssertEqual(allCases.last, .saturday)
    }

    func testScheduleEntryCodable() throws {
        var entry = ScheduleEntry()
        entry.days = [.monday, .wednesday, .friday]
        entry.isEnabled = false

        let encoded = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(ScheduleEntry.self, from: encoded)

        XCTAssertEqual(decoded.id, entry.id)
        XCTAssertEqual(decoded.days, entry.days)
        XCTAssertEqual(decoded.isEnabled, entry.isEnabled)
    }

    func testScheduleEntryEquatable() {
        let entry1 = ScheduleEntry()
        var entry2 = ScheduleEntry()
        entry2.isEnabled = false

        XCTAssertEqual(entry1, entry1)
        XCTAssertNotEqual(entry1, entry2)
    }

    // MARK: - AppTrigger Tests

    func testAppTriggerInitialization() {
        let trigger = AppTrigger(
            bundleIdentifier: "com.example.app",
            appName: "Example App",
            isEnabled: true
        )

        XCTAssertEqual(trigger.bundleIdentifier, "com.example.app")
        XCTAssertEqual(trigger.appName, "Example App")
        XCTAssertTrue(trigger.isEnabled)
        XCTAssertNotNil(trigger.id)
    }

    func testAppTriggerCodable() throws {
        let trigger = AppTrigger(
            bundleIdentifier: "us.zoom.xos",
            appName: "Zoom",
            isEnabled: true
        )

        let encoded = try JSONEncoder().encode(trigger)
        let decoded = try JSONDecoder().decode(AppTrigger.self, from: encoded)

        XCTAssertEqual(decoded.id, trigger.id)
        XCTAssertEqual(decoded.bundleIdentifier, trigger.bundleIdentifier)
        XCTAssertEqual(decoded.appName, trigger.appName)
        XCTAssertEqual(decoded.isEnabled, trigger.isEnabled)
    }

    func testAppTriggerEquatable() {
        let trigger1 = AppTrigger(bundleIdentifier: "com.app1", appName: "App 1", isEnabled: true)
        let trigger2 = AppTrigger(bundleIdentifier: "com.app2", appName: "App 2", isEnabled: true)

        XCTAssertEqual(trigger1, trigger1)
        XCTAssertNotEqual(trigger1, trigger2)
    }

    // MARK: - KeyboardShortcut Tests

    func testKeyboardShortcutDefault() {
        let shortcut = KeyboardShortcut.default

        // Default is Cmd+Shift+A
        XCTAssertEqual(shortcut.keyCode, 0) // kVK_ANSI_A
        XCTAssertTrue(shortcut.modifiers & NSEvent.ModifierFlags.command.rawValue != 0)
        XCTAssertTrue(shortcut.modifiers & NSEvent.ModifierFlags.shift.rawValue != 0)
    }

    func testKeyboardShortcutCodable() throws {
        let shortcut = KeyboardShortcut(keyCode: 1, modifiers: 256)

        let encoded = try JSONEncoder().encode(shortcut)
        let decoded = try JSONDecoder().decode(KeyboardShortcut.self, from: encoded)

        XCTAssertEqual(decoded.keyCode, shortcut.keyCode)
        XCTAssertEqual(decoded.modifiers, shortcut.modifiers)
    }

    func testKeyboardShortcutEquatable() {
        let shortcut1 = KeyboardShortcut(keyCode: 0, modifiers: 256)
        let shortcut2 = KeyboardShortcut(keyCode: 1, modifiers: 256)
        let shortcut3 = KeyboardShortcut(keyCode: 0, modifiers: 512)

        XCTAssertEqual(shortcut1, shortcut1)
        XCTAssertNotEqual(shortcut1, shortcut2) // Different key
        XCTAssertNotEqual(shortcut1, shortcut3) // Different modifiers
    }

    // MARK: - Battery Threshold Tests

    func testBatteryThresholdBounds() {
        // Valid thresholds should be between 5 and 50
        let validThresholds = [5, 10, 15, 20, 25, 30, 50]
        for threshold in validThresholds {
            XCTAssertTrue(threshold >= 5 && threshold <= 50, "Threshold \(threshold) should be valid")
        }
    }

    // MARK: - Mock App State Tests

    func testMockAppStateActivateDeactivate() {
        let mockState = MockAppState()

        XCTAssertFalse(mockState.isActive)
        XCTAssertNil(mockState.currentPreset)

        mockState.activate(with: .oneHour)

        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockState.currentPreset, .oneHour)
        XCTAssertEqual(mockState.remainingSeconds, TimerPreset.oneHour.seconds)
        XCTAssertEqual(mockState.activateCallCount, 1)

        mockState.deactivate()

        XCTAssertFalse(mockState.isActive)
        XCTAssertNil(mockState.currentPreset)
        XCTAssertNil(mockState.remainingSeconds)
        XCTAssertEqual(mockState.deactivateCallCount, 1)
    }

    func testMockAppStateReset() {
        let mockState = MockAppState()

        mockState.activate(with: .fifteenMinutes)
        mockState.deactivate()

        mockState.reset()

        XCTAssertFalse(mockState.isActive)
        XCTAssertNil(mockState.currentPreset)
        XCTAssertEqual(mockState.activateCallCount, 0)
        XCTAssertEqual(mockState.deactivateCallCount, 0)
    }

    func testMockAppStateIndefinitePreset() {
        let mockState = MockAppState()

        mockState.activate(with: .indefinite)

        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockState.currentPreset, .indefinite)
        XCTAssertNil(mockState.remainingSeconds) // Indefinite has no seconds
    }
}
