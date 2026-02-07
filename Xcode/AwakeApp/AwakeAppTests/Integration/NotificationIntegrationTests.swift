//
//  NotificationIntegrationTests.swift
//  AwakeAppTests
//
//  Integration tests for notification workflows
//

import XCTest
@testable import AwakeApp

final class NotificationIntegrationTests: XCTestCase {

    // MARK: - Timer End Notification Tests

    func testTimerEndNotificationScheduled() {
        let mockNotifications = MockNotificationManager()

        let preset = TimerPreset.fifteenMinutes
        let durationSeconds = preset.seconds!

        // Simulate scheduling notification when timer starts
        mockNotifications.scheduleTimerEndNotification(in: durationSeconds, presetName: preset.displayName)

        XCTAssertEqual(mockNotifications.scheduledNotifications.count, 1)
        XCTAssertEqual(mockNotifications.scheduledNotifications.first?.seconds, 15 * 60)
        XCTAssertEqual(mockNotifications.scheduledNotifications.first?.presetName, "15 minutes")
    }

    func testTimerEndNotificationCancelledOnManualStop() {
        let mockNotifications = MockNotificationManager()

        // Schedule notification
        mockNotifications.scheduleTimerEndNotification(in: 3600, presetName: "1 hour")

        // User manually stops timer
        mockNotifications.cancelTimerEndNotification()

        XCTAssertEqual(mockNotifications.cancelledNotifications.count, 1)
        XCTAssertTrue(mockNotifications.cancelledNotifications.contains("timer.end"))
    }

    func testIndefiniteModeNoNotificationScheduled() {
        let mockNotifications = MockNotificationManager()

        let preset = TimerPreset.indefinite

        // Indefinite mode has no seconds, so no notification
        if let seconds = preset.seconds {
            mockNotifications.scheduleTimerEndNotification(in: seconds, presetName: preset.displayName)
        }

        XCTAssertEqual(mockNotifications.scheduledNotifications.count, 0)
    }

    func testCustomDurationNotification() {
        let mockNotifications = MockNotificationManager()

        let preset = TimerPreset.custom(minutes: 90)
        let durationSeconds = preset.seconds!

        mockNotifications.scheduleTimerEndNotification(in: durationSeconds, presetName: preset.displayName)

        XCTAssertEqual(mockNotifications.scheduledNotifications.first?.seconds, 90 * 60)
        XCTAssertEqual(mockNotifications.scheduledNotifications.first?.presetName, "1h 30m")
    }

    // MARK: - Battery Protection Notification Tests

    func testBatteryProtectionNotification() {
        let mockNotifications = MockNotificationManager()

        let batteryLevel = 18

        // Battery dropped below threshold
        mockNotifications.sendNotification(
            title: "Battery Protection Activated",
            body: "Sleep prevention stopped at \(batteryLevel)% battery to preserve power."
        )

        XCTAssertEqual(mockNotifications.sentNotifications.count, 1)
        XCTAssertEqual(mockNotifications.sentNotifications.first?.title, "Battery Protection Activated")
        XCTAssertTrue(mockNotifications.sentNotifications.first?.body.contains("18%") ?? false)
    }

    func testBatteryNotificationOnlyWhenEnabled() {
        let mockNotifications = MockNotificationManager()

        let notifyOnBatteryStop = false
        let batteryLevel = 15

        if notifyOnBatteryStop {
            mockNotifications.sendNotification(
                title: "Battery Protection",
                body: "Stopped at \(batteryLevel)%"
            )
        }

        XCTAssertEqual(mockNotifications.sentNotifications.count, 0)
    }

    // MARK: - Notification Settings Integration

    func testNotificationSettingsRespected() {
        let mockNotifications = MockNotificationManager()

        // Settings
        let notifyOnTimerEnd = true
        let notifyOnBatteryStop = false

        // Timer ends
        if notifyOnTimerEnd {
            mockNotifications.sendNotification(title: "Timer Ended", body: "Your Mac can now sleep.")
        }

        // Battery protection triggers
        if notifyOnBatteryStop {
            mockNotifications.sendNotification(title: "Battery", body: "Stopped")
        }

        XCTAssertEqual(mockNotifications.sentNotifications.count, 1)
        XCTAssertEqual(mockNotifications.sentNotifications.first?.title, "Timer Ended")
    }

    // MARK: - Notification Timing Tests

    func testCorrectNotificationTimingForPresets() {
        let mockNotifications = MockNotificationManager()

        let presets: [(TimerPreset, Int?)] = [
            (.fifteenMinutes, 15 * 60),
            (.thirtyMinutes, 30 * 60),
            (.oneHour, 60 * 60),
            (.twoHours, 2 * 60 * 60),
            (.fiveHours, 5 * 60 * 60),
            (.indefinite, nil),
            (.custom(minutes: 45), 45 * 60)
        ]

        for (preset, expectedSeconds) in presets {
            mockNotifications.reset()

            if let seconds = preset.seconds {
                mockNotifications.scheduleTimerEndNotification(in: seconds, presetName: preset.displayName)
            }

            if let expected = expectedSeconds {
                XCTAssertEqual(mockNotifications.scheduledNotifications.first?.seconds, expected, "Failed for \(preset)")
            } else {
                XCTAssertEqual(mockNotifications.scheduledNotifications.count, 0, "Indefinite should not schedule notification")
            }
        }
    }

    // MARK: - Notification Replacement Tests

    func testChangingPresetReplacesNotification() {
        let mockNotifications = MockNotificationManager()

        // Start with 1 hour
        mockNotifications.scheduleTimerEndNotification(in: 3600, presetName: "1 hour")
        XCTAssertEqual(mockNotifications.scheduledNotifications.count, 1)

        // User changes to 30 minutes - cancel old and schedule new
        mockNotifications.cancelTimerEndNotification()
        mockNotifications.scheduleTimerEndNotification(in: 1800, presetName: "30 minutes")

        XCTAssertEqual(mockNotifications.scheduledNotifications.count, 2) // Both scheduled
        XCTAssertEqual(mockNotifications.cancelledNotifications.count, 1) // One cancelled
        XCTAssertEqual(mockNotifications.scheduledNotifications.last?.seconds, 1800)
    }
}
