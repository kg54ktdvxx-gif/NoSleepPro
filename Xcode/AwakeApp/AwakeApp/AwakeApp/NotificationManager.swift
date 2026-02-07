//
//  NotificationManager.swift
//  AwakeApp
//
//  Handles macOS notifications for timer events
//

import Foundation
import Combine
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var hasPermission = false

    private init() {
        checkPermission()
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            hasPermission = granted
            return granted
        } catch {
            return false
        }
    }

    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }

    /// Schedule notification for when timer ends
    func scheduleTimerEndNotification(in seconds: Int, presetName: String) {
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = "No Sleep Pro"
        content.body = "Timer ended (\(presetName)). Your Mac can now sleep normally."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "awakeapp.timer.end",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Cancel pending timer notification
    func cancelTimerEndNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["awakeapp.timer.end"]
        )
    }

    /// Send immediate notification (e.g., battery protection triggered)
    func sendNotification(title: String, body: String) {
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Send notification when battery protection triggers
    func sendBatteryProtectionNotification(batteryLevel: Int) {
        sendNotification(
            title: "Battery Protection Activated",
            body: "Sleep prevention stopped at \(batteryLevel)% battery to preserve power."
        )
    }

    /// Send notification when timer naturally ends
    func sendTimerEndedNotification(presetName: String) {
        sendNotification(
            title: "Timer Ended",
            body: "\(presetName) timer completed. Your Mac can now sleep normally."
        )
    }
}
