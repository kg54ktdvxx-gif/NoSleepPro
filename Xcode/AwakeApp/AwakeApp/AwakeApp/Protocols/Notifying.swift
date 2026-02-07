//
//  Notifying.swift
//  AwakeApp
//
//  Protocol for notifications - enables testing without UNUserNotificationCenter
//

import Foundation

/// Protocol for notification operations
/// Conforming types can send and schedule notifications
@MainActor
protocol Notifying: AnyObject {
    /// Whether notification permission has been granted
    var hasPermission: Bool { get }

    /// Request notification permission from the user
    /// - Returns: Whether permission was granted
    func requestPermission() async -> Bool

    /// Send a notification immediately
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification body text
    func sendNotification(title: String, body: String)

    /// Send battery protection notification
    /// - Parameter batteryLevel: Current battery level
    func sendBatteryProtectionNotification(batteryLevel: Int)

    /// Send timer ended notification
    /// - Parameter presetName: Name of the preset that ended
    func sendTimerEndedNotification(presetName: String)

    /// Schedule a notification for when timer ends
    /// - Parameters:
    ///   - seconds: Seconds until notification
    ///   - presetName: Name of the preset
    func scheduleTimerEndNotification(in seconds: Int, presetName: String)

    /// Cancel any scheduled timer end notification
    func cancelTimerEndNotification()
}

// MARK: - NotificationManager Conformance

extension NotificationManager: Notifying {}
