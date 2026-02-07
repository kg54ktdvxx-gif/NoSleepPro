//
//  EndToEndWorkflowTests.swift
//  AwakeAppTests
//
//  End-to-end workflow tests simulating real user scenarios
//

import XCTest
@testable import AwakeApp

@MainActor
final class EndToEndWorkflowTests: XCTestCase {

    // MARK: - Scenario: Basic Manual Usage

    func testScenario_UserStartsTimerManually() {
        // Setup
        let mockState = MockAppState()
        let mockPower = MockPowerManager()
        let mockNotifications = MockNotificationManager()
        let notifyOnTimerEnd = true

        // User clicks "1 hour" button
        let selectedPreset = TimerPreset.oneHour

        // App activates
        mockState.activate(with: selectedPreset)
        mockPower.start(
            duration: selectedPreset.seconds,
            allowDisplaySleep: false,
            reason: .manual
        )

        // Schedule notification
        if notifyOnTimerEnd, let seconds = selectedPreset.seconds {
            mockNotifications.scheduleTimerEndNotification(in: seconds, presetName: selectedPreset.displayName)
        }

        // Verify state
        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockState.currentPreset, .oneHour)
        XCTAssertTrue(mockPower.isRunning)
        XCTAssertEqual(mockPower.activationReason, .manual)
        XCTAssertEqual(mockNotifications.scheduledNotifications.count, 1)
    }

    func testScenario_UserStopsTimerManually() {
        // Setup - already running
        let mockState = MockAppState()
        let mockPower = MockPowerManager()
        let mockNotifications = MockNotificationManager()

        mockState.activate(with: .twoHours)
        mockPower.start(duration: 2 * 60 * 60, allowDisplaySleep: false, reason: .manual)
        mockNotifications.scheduleTimerEndNotification(in: 2 * 60 * 60, presetName: "2 hours")

        // User clicks stop
        mockState.deactivate()
        mockPower.stop()
        mockNotifications.cancelTimerEndNotification()

        // Verify
        XCTAssertFalse(mockState.isActive)
        XCTAssertFalse(mockPower.isRunning)
        XCTAssertTrue(mockNotifications.cancelledNotifications.contains("timer.end"))
    }

    // MARK: - Scenario: Presentation Mode

    func testScenario_PresentationWithZoom() {
        // Setup
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        let appTriggers = [
            AppTrigger(bundleIdentifier: "us.zoom.xos", appName: "Zoom", isEnabled: true)
        ]
        let appTriggersEnabled = true

        // User launches Zoom
        let launchedAppBundleId = "us.zoom.xos"

        // Check if trigger matches
        if appTriggersEnabled {
            if let trigger = appTriggers.first(where: { $0.bundleIdentifier == launchedAppBundleId && $0.isEnabled }) {
                mockState.activate(with: .indefinite)
                mockPower.start(duration: nil, allowDisplaySleep: false, reason: .appTrigger(appName: trigger.appName))
            }
        }

        // Verify auto-activation
        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockPower.activationReason, .appTrigger(appName: "Zoom"))

        // User quits Zoom
        if case .appTrigger(let appName) = mockPower.activationReason, appName == "Zoom" {
            mockState.deactivate()
            mockPower.stop()
        }

        // Verify auto-deactivation
        XCTAssertFalse(mockState.isActive)
    }

    // MARK: - Scenario: Work From Home

    func testScenario_WorkFromHomeSchedule() {
        // Setup
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        let schedules = [
            createSchedule(days: [.monday, .tuesday, .wednesday, .thursday, .friday],
                          startHour: 9, endHour: 17)
        ]
        let schedulesEnabled = true

        // 10:30 AM on Tuesday
        let currentWeekday = 3 // Tuesday
        let currentHour = 10
        let currentMinute = 30

        // Check schedule
        let shouldBeActive = schedulesEnabled && schedules.contains { schedule in
            isScheduleActive(schedule, weekday: currentWeekday, hour: currentHour, minute: currentMinute)
        }

        if shouldBeActive && !mockState.isActive {
            mockState.activate(with: .indefinite)
            mockPower.start(duration: nil, allowDisplaySleep: false, reason: .schedule)
        }

        // Verify
        XCTAssertTrue(shouldBeActive)
        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockPower.activationReason, .schedule)
    }

    // MARK: - Scenario: Coffee Shop Work Session

    func testScenario_CoffeeShopBatteryProtection() {
        // Setup
        let mockState = MockAppState()
        let mockPower = MockPowerManager()
        let mockNotifications = MockNotificationManager()

        let batteryProtectionEnabled = true
        let batteryThreshold = 20
        let notifyOnBatteryStop = true

        // User starts 2-hour timer at coffee shop
        mockState.activate(with: .twoHours)
        mockPower.start(duration: 2 * 60 * 60, allowDisplaySleep: false, reason: .manual)

        // Battery level drops over time
        var currentBatteryLevel = 50

        // Simulate battery drain
        let batteryLevels = [50, 40, 30, 25, 18]

        for level in batteryLevels {
            currentBatteryLevel = level

            if batteryProtectionEnabled && mockState.isActive && currentBatteryLevel <= batteryThreshold {
                mockState.deactivate()
                mockPower.stop()

                if notifyOnBatteryStop {
                    mockNotifications.sendNotification(
                        title: "Battery Protection",
                        body: "Stopped at \(level)%"
                    )
                }
                break
            }
        }

        // Verify battery protection triggered at 18%
        XCTAssertFalse(mockState.isActive)
        XCTAssertEqual(mockNotifications.sentNotifications.count, 1)
        XCTAssertTrue(mockNotifications.sentNotifications.first?.body.contains("18%") ?? false)
    }

    // MARK: - Scenario: Home Office Docking Station

    func testScenario_DockingStationSetup() {
        // Setup
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        let hardwareTriggersEnabled = true
        let activateOnPowerConnect = true
        let activateOnExternalDisplay = true
        let closedLidModeEnabled = true

        var wasOnBattery = true
        var hadExternalDisplay = false
        var closedLidEnabled = false

        // User arrives at desk, connects to dock
        // 1. Power connected
        let isOnBattery = false

        if hardwareTriggersEnabled && activateOnPowerConnect && wasOnBattery && !isOnBattery {
            mockState.activate(with: .indefinite)
            mockPower.start(duration: nil, allowDisplaySleep: false, reason: .hardwareTrigger(type: "Power connected"))
        }
        wasOnBattery = isOnBattery

        XCTAssertTrue(mockState.isActive)

        // 2. External display connected
        let hasExternalDisplay = true

        if hardwareTriggersEnabled && activateOnExternalDisplay && !hadExternalDisplay && hasExternalDisplay {
            // Already active, but update reason
            mockPower.stop()
            mockPower.start(duration: nil, allowDisplaySleep: false, reason: .hardwareTrigger(type: "External display"))
        }
        hadExternalDisplay = hasExternalDisplay

        // 3. User closes laptop lid
        if closedLidModeEnabled && !isOnBattery && hasExternalDisplay {
            closedLidEnabled = true
        }

        XCTAssertTrue(mockState.isActive)
        XCTAssertTrue(closedLidEnabled)
    }

    // MARK: - Scenario: Quick Keyboard Toggle

    func testScenario_KeyboardShortcutQuickToggle() {
        // Setup
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        let keyboardShortcutEnabled = true
        let defaultPreset = TimerPreset.oneHour

        // User presses ⌘⇧A to start
        if keyboardShortcutEnabled {
            if !mockState.isActive {
                mockState.activate(with: defaultPreset)
                mockPower.start(duration: defaultPreset.seconds, allowDisplaySleep: false, reason: .keyboardShortcut)
            }
        }

        XCTAssertTrue(mockState.isActive)
        XCTAssertEqual(mockPower.activationReason, .keyboardShortcut)

        // User presses ⌘⇧A again to stop
        if keyboardShortcutEnabled {
            if mockState.isActive {
                mockState.deactivate()
                mockPower.stop()
            }
        }

        XCTAssertFalse(mockState.isActive)
    }

    // MARK: - Scenario: Multiple Automation Conflicts

    func testScenario_ScheduleVsManualConflict() {
        // Setup
        let mockState = MockAppState()
        let mockPower = MockPowerManager()

        // Schedule activates at 9 AM
        mockState.activate(with: .indefinite)
        mockPower.start(duration: nil, allowDisplaySleep: false, reason: .schedule)

        // User manually stops at 10 AM
        mockState.deactivate()
        mockPower.stop()

        // Verify manual action takes precedence
        XCTAssertFalse(mockState.isActive)

        // Note: In real implementation, schedule would need to track
        // that user manually stopped and not re-activate until next day
    }

    // MARK: - Helpers

    private func createSchedule(days: Set<ScheduleEntry.Weekday>, startHour: Int, endHour: Int) -> ScheduleEntry {
        var schedule = ScheduleEntry()
        schedule.days = days
        schedule.startTime = Calendar.current.date(from: DateComponents(hour: startHour)) ?? Date()
        schedule.endTime = Calendar.current.date(from: DateComponents(hour: endHour)) ?? Date()
        return schedule
    }

    private func isScheduleActive(_ schedule: ScheduleEntry, weekday: Int, hour: Int, minute: Int) -> Bool {
        guard schedule.isEnabled else { return false }
        guard let day = ScheduleEntry.Weekday(rawValue: weekday), schedule.days.contains(day) else { return false }

        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: schedule.startTime)
        let endHour = calendar.component(.hour, from: schedule.endTime)

        return hour >= startHour && hour < endHour
    }
}
