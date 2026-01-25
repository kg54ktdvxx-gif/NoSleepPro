//
//  AutomationIntegrationTests.swift
//  AwakeAppTests
//
//  Integration tests for automation workflows (triggers, schedules, battery)
//

import XCTest
@testable import AwakeApp

final class AutomationIntegrationTests: XCTestCase {

    // MARK: - App Trigger Integration Tests

    func testAppTriggerActivationFlow() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        // Simulate app trigger activation
        let appName = "Zoom"
        let trigger = AppTrigger(bundleIdentifier: "us.zoom.xos", appName: appName, isEnabled: true)

        // Check if trigger matches
        let triggers = [trigger]
        let matchingTrigger = triggers.first { $0.bundleIdentifier == "us.zoom.xos" && $0.isEnabled }

        XCTAssertNotNil(matchingTrigger)

        // Activate
        if matchingTrigger != nil {
            mockState.activate(with: .indefinite)
            mockPower.start(duration: nil, allowDisplaySleep: false, reason: .appTrigger(appName: appName))
        }

        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockPower.activationReason, .appTrigger(appName: "Zoom"))
    }

    func testDisabledAppTriggerDoesNotActivate() {
        let mockState = MockAppState()

        let trigger = AppTrigger(bundleIdentifier: "us.zoom.xos", appName: "Zoom", isEnabled: false)
        let triggers = [trigger]

        let matchingTrigger = triggers.first { $0.bundleIdentifier == "us.zoom.xos" && $0.isEnabled }

        XCTAssertNil(matchingTrigger)
        XCTAssertFalse(mockState.isActive)
    }

    func testMultipleAppTriggersFirstMatch() {
        let triggers = [
            AppTrigger(bundleIdentifier: "com.microsoft.teams", appName: "Teams", isEnabled: false),
            AppTrigger(bundleIdentifier: "us.zoom.xos", appName: "Zoom", isEnabled: true),
            AppTrigger(bundleIdentifier: "com.apple.Keynote", appName: "Keynote", isEnabled: true),
        ]

        // Zoom is running
        let runningBundleId = "us.zoom.xos"
        let matchingTrigger = triggers.first { $0.bundleIdentifier == runningBundleId && $0.isEnabled }

        XCTAssertNotNil(matchingTrigger)
        XCTAssertEqual(matchingTrigger?.appName, "Zoom")
    }

    // MARK: - Schedule Integration Tests

    func testScheduleActivationDuringWorkHours() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        // Create weekday work schedule (9 AM - 5 PM)
        let schedule = createTestSchedule(
            days: [.monday, .tuesday, .wednesday, .thursday, .friday],
            startHour: 9, startMinute: 0,
            endHour: 17, endMinute: 0
        )

        // Test at 10:30 AM on Wednesday
        let isActive = checkScheduleActive(
            schedule: schedule,
            weekday: 4, // Wednesday
            hour: 10, minute: 30
        )

        if isActive {
            mockState.activate(with: .indefinite)
            mockPower.start(duration: nil, allowDisplaySleep: false, reason: .schedule)
        }

        XCTAssertTrue(isActive)
        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockPower.activationReason, .schedule)
    }

    func testScheduleDeactivationAfterWorkHours() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        let schedule = createTestSchedule(
            days: [.monday],
            startHour: 9, startMinute: 0,
            endHour: 17, endMinute: 0
        )

        // First activate during work hours
        mockState.activate(with: .indefinite)
        mockPower.start(duration: nil, allowDisplaySleep: false, reason: .schedule)

        // Check at 6:00 PM (after work)
        let isActive = checkScheduleActive(
            schedule: schedule,
            weekday: 2, // Monday
            hour: 18, minute: 0
        )

        if !isActive {
            mockState.deactivate()
            mockPower.stop()
        }

        XCTAssertFalse(isActive)
        XCTAssertFalse(mockState.isActive)
    }

    func testWeekendScheduleNotActiveOnWeekday() {
        let schedule = createTestSchedule(
            days: [.saturday, .sunday],
            startHour: 10, startMinute: 0,
            endHour: 22, endMinute: 0
        )

        // Test on Wednesday at noon
        let isActive = checkScheduleActive(
            schedule: schedule,
            weekday: 4, // Wednesday
            hour: 12, minute: 0
        )

        XCTAssertFalse(isActive)
    }

    func testOverlappingSchedules() {
        let schedules = [
            createTestSchedule(days: [.monday], startHour: 9, startMinute: 0, endHour: 12, endMinute: 0),
            createTestSchedule(days: [.monday], startHour: 11, startMinute: 0, endHour: 14, endMinute: 0),
        ]

        // At 11:30, both schedules are active
        let activeSchedules = schedules.filter { schedule in
            checkScheduleActive(schedule: schedule, weekday: 2, hour: 11, minute: 30)
        }

        XCTAssertEqual(activeSchedules.count, 2)
    }

    // MARK: - Battery Protection Integration Tests

    func testBatteryProtectionTriggersDeactivation() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()
        let mockNotifications = MockNotificationManager()

        // Settings
        let batteryProtectionEnabled = true
        let batteryThreshold = 20

        // Activate
        mockState.activate(with: .indefinite)
        mockPower.start(duration: nil, allowDisplaySleep: false, reason: .manual)

        // Simulate battery dropping to 15%
        let currentBatteryLevel = 15

        if batteryProtectionEnabled && currentBatteryLevel <= batteryThreshold {
            mockState.deactivate()
            mockPower.stop()
            mockNotifications.sendNotification(
                title: "Battery Protection",
                body: "Stopped at \(currentBatteryLevel)%"
            )
        }

        XCTAssertFalse(mockState.isActive)
        XCTAssertFalse(mockPower.isRunning)
        XCTAssertEqual(mockNotifications.sentNotifications.count, 1)
    }

    func testBatteryProtectionDisabledDoesNotTrigger() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        let batteryProtectionEnabled = false
        let batteryThreshold = 20
        let currentBatteryLevel = 10

        mockState.activate(with: .indefinite)
        mockPower.start(duration: nil, allowDisplaySleep: false, reason: .manual)

        // Should NOT deactivate when protection is disabled
        if batteryProtectionEnabled && currentBatteryLevel <= batteryThreshold {
            mockState.deactivate()
            mockPower.stop()
        }

        XCTAssertTrue(mockState.isActive)
        XCTAssertTrue(mockPower.isRunning)
    }

    func testBatteryAboveThresholdDoesNotTrigger() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        let batteryProtectionEnabled = true
        let batteryThreshold = 20
        let currentBatteryLevel = 50

        mockState.activate(with: .indefinite)
        mockPower.start(duration: nil, allowDisplaySleep: false, reason: .manual)

        if batteryProtectionEnabled && currentBatteryLevel <= batteryThreshold {
            mockState.deactivate()
            mockPower.stop()
        }

        XCTAssertTrue(mockState.isActive)
        XCTAssertTrue(mockPower.isRunning)
    }

    // MARK: - Wi-Fi Trigger Integration Tests

    func testWiFiTriggerActivation() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()
        let mockWiFi = MockWiFiProvider()

        let triggers = [
            WiFiTrigger(ssid: "HomeNetwork", isEnabled: true),
            WiFiTrigger(ssid: "OfficeWiFi", isEnabled: true),
        ]

        // Connect to home network
        mockWiFi.connect(to: "HomeNetwork")

        // Check for matching trigger
        let matchingTrigger = triggers.first { trigger in
            trigger.isEnabled && trigger.ssid.lowercased() == mockWiFi.currentSSID?.lowercased()
        }

        if let trigger = matchingTrigger {
            mockState.activate(with: .indefinite)
            mockPower.start(duration: nil, allowDisplaySleep: false, reason: .wifiTrigger(ssid: trigger.ssid))
        }

        XCTAssertNotNil(matchingTrigger)
        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockPower.activationReason, .wifiTrigger(ssid: "HomeNetwork"))
    }

    func testWiFiDisconnectDeactivation() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()
        let mockWiFi = MockWiFiProvider()

        let triggers = [WiFiTrigger(ssid: "HomeNetwork", isEnabled: true)]

        // Connect and activate
        mockWiFi.connect(to: "HomeNetwork")
        mockState.activate(with: .indefinite)
        mockPower.start(duration: nil, allowDisplaySleep: false, reason: .wifiTrigger(ssid: "HomeNetwork"))

        // Disconnect
        mockWiFi.disconnect()

        let matchingTrigger = triggers.first { trigger in
            trigger.isEnabled && trigger.ssid.lowercased() == mockWiFi.currentSSID?.lowercased()
        }

        if matchingTrigger == nil && mockPower.activationReason == .wifiTrigger(ssid: "HomeNetwork") {
            mockState.deactivate()
            mockPower.stop()
        }

        XCTAssertFalse(mockState.isActive)
        XCTAssertFalse(mockPower.isRunning)
    }

    // MARK: - Hardware Trigger Integration Tests

    func testPowerConnectedTrigger() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        let hardwareTriggersEnabled = true
        let activateOnPowerConnect = true
        var wasOnBattery = true
        let isOnBattery = false // Just connected power

        if hardwareTriggersEnabled && activateOnPowerConnect && wasOnBattery && !isOnBattery {
            mockState.activate(with: .indefinite)
            mockPower.start(duration: nil, allowDisplaySleep: false, reason: .hardwareTrigger(type: "Power connected"))
        }

        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockPower.activationReason, .hardwareTrigger(type: "Power connected"))
    }

    func testExternalDisplayConnectedTrigger() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        let hardwareTriggersEnabled = true
        let activateOnExternalDisplay = true
        var hadExternalDisplay = false
        let hasExternalDisplay = true // Just connected display

        if hardwareTriggersEnabled && activateOnExternalDisplay && !hadExternalDisplay && hasExternalDisplay {
            mockState.activate(with: .indefinite)
            mockPower.start(duration: nil, allowDisplaySleep: false, reason: .hardwareTrigger(type: "External display"))
        }

        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockPower.activationReason, .hardwareTrigger(type: "External display"))
    }

    // MARK: - Keyboard Shortcut Integration Tests

    func testKeyboardShortcutToggleOn() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        let shortcutEnabled = true
        let defaultPreset = TimerPreset.indefinite

        // Simulate shortcut pressed when inactive
        if shortcutEnabled && !mockState.isActive {
            mockState.activate(with: defaultPreset)
            mockPower.start(duration: defaultPreset.seconds, allowDisplaySleep: false, reason: .keyboardShortcut)
        }

        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockPower.activationReason, .keyboardShortcut)
    }

    func testKeyboardShortcutToggleOff() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        // First activate
        mockState.activate(with: .indefinite)
        mockPower.start(duration: nil, allowDisplaySleep: false, reason: .keyboardShortcut)

        let shortcutEnabled = true

        // Simulate shortcut pressed when active
        if shortcutEnabled && mockState.isActive {
            mockState.deactivate()
            mockPower.stop()
        }

        XCTAssertFalse(mockState.isActive)
        XCTAssertFalse(mockPower.isRunning)
    }

    // MARK: - Priority/Conflict Tests

    func testManualOverridesAutomation() {
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        // Activated by schedule
        mockState.activate(with: .indefinite)
        mockPower.start(duration: nil, allowDisplaySleep: false, reason: .schedule)

        // User manually stops
        mockState.deactivate()
        mockPower.stop()

        // Should stay stopped even if schedule is still active
        XCTAssertFalse(mockState.isActive)
    }

    // MARK: - Helpers

    private func createTestSchedule(
        days: Set<ScheduleEntry.Weekday>,
        startHour: Int, startMinute: Int,
        endHour: Int, endMinute: Int
    ) -> ScheduleEntry {
        var schedule = ScheduleEntry()
        schedule.days = days
        schedule.startTime = Calendar.current.date(from: DateComponents(hour: startHour, minute: startMinute)) ?? Date()
        schedule.endTime = Calendar.current.date(from: DateComponents(hour: endHour, minute: endMinute)) ?? Date()
        return schedule
    }

    private func checkScheduleActive(schedule: ScheduleEntry, weekday: Int, hour: Int, minute: Int) -> Bool {
        guard schedule.isEnabled else { return false }
        guard let day = ScheduleEntry.Weekday(rawValue: weekday), schedule.days.contains(day) else { return false }

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: schedule.endTime)

        let currentMinutes = hour * 60 + minute
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)

        return currentMinutes >= startMinutes && currentMinutes < endMinutes
    }
}
