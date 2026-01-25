//
//  MockPowerManager.swift
//  AwakeAppTests
//
//  Mock implementations for testing power management
//

import Foundation
@testable import AwakeApp

// MARK: - Power Manager Protocol

/// Protocol for power management operations (enables testing)
protocol PowerManaging {
    func start(duration: Int?, allowDisplaySleep: Bool, reason: ActivationReason)
    func stop()
    var isRunning: Bool { get }
    var activationReason: ActivationReason? { get }
}

// MARK: - Mock Power Manager

/// Mock implementation for unit testing
class MockPowerManager: PowerManaging {
    var isRunning: Bool = false
    var activationReason: ActivationReason?

    var startCallCount = 0
    var stopCallCount = 0
    var lastDuration: Int?
    var lastAllowDisplaySleep: Bool?
    var lastReason: ActivationReason?

    func start(duration: Int?, allowDisplaySleep: Bool, reason: ActivationReason) {
        startCallCount += 1
        lastDuration = duration
        lastAllowDisplaySleep = allowDisplaySleep
        lastReason = reason
        activationReason = reason
        isRunning = true
    }

    func stop() {
        stopCallCount += 1
        isRunning = false
        activationReason = nil
    }

    func reset() {
        startCallCount = 0
        stopCallCount = 0
        lastDuration = nil
        lastAllowDisplaySleep = nil
        lastReason = nil
        isRunning = false
        activationReason = nil
    }
}

// MARK: - Mock Battery Provider

/// Protocol for battery information
protocol BatteryProviding {
    static func getBatteryLevel() -> Int?
    static func isOnBattery() -> Bool
}

/// Mock battery provider for testing
class MockBatteryProvider: BatteryProviding {
    static var mockBatteryLevel: Int? = 100
    static var mockIsOnBattery: Bool = false

    static func getBatteryLevel() -> Int? {
        mockIsOnBattery ? mockBatteryLevel : nil
    }

    static func isOnBattery() -> Bool {
        mockIsOnBattery
    }

    static func reset() {
        mockBatteryLevel = 100
        mockIsOnBattery = false
    }
}

// MARK: - Mock WiFi Provider

/// Protocol for WiFi information
protocol WiFiProviding {
    var currentSSID: String? { get }
    var isConnected: Bool { get }
}

/// Mock WiFi provider for testing
class MockWiFiProvider: WiFiProviding {
    var currentSSID: String?
    var isConnected: Bool = false

    func connect(to ssid: String) {
        currentSSID = ssid
        isConnected = true
    }

    func disconnect() {
        currentSSID = nil
        isConnected = false
    }
}

// MARK: - Mock App State

/// Mock app state for testing
class MockAppState {
    var isActive: Bool = false
    var currentPreset: TimerPreset?
    var remainingSeconds: Int?

    var activateCallCount = 0
    var deactivateCallCount = 0

    func activate(with preset: TimerPreset) {
        activateCallCount += 1
        isActive = true
        currentPreset = preset
        remainingSeconds = preset.seconds
    }

    func deactivate() {
        deactivateCallCount += 1
        isActive = false
        currentPreset = nil
        remainingSeconds = nil
    }

    func reset() {
        isActive = false
        currentPreset = nil
        remainingSeconds = nil
        activateCallCount = 0
        deactivateCallCount = 0
    }
}

// MARK: - Mock Notification Manager

/// Mock notification manager for testing
class MockNotificationManager {
    var scheduledNotifications: [(seconds: Int, presetName: String)] = []
    var cancelledNotifications: [String] = []
    var sentNotifications: [(title: String, body: String)] = []

    func scheduleTimerEndNotification(in seconds: Int, presetName: String) {
        scheduledNotifications.append((seconds, presetName))
    }

    func cancelTimerEndNotification() {
        cancelledNotifications.append("timer.end")
    }

    func sendNotification(title: String, body: String) {
        sentNotifications.append((title, body))
    }

    func reset() {
        scheduledNotifications.removeAll()
        cancelledNotifications.removeAll()
        sentNotifications.removeAll()
    }
}
