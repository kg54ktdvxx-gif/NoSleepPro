//
//  WindowManager.swift
//  AwakeApp
//
//  Manages opening Settings and About windows from MenuBarExtra
//

import SwiftUI
import AppKit
import Combine

@MainActor
final class WindowManager: ObservableObject {
    static let shared = WindowManager()

    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?

    private init() {}

    func openSettings() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
            .environmentObject(AppSettings.shared)

        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "AwakeApp Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 520, height: 500))
        window.center()
        window.isReleasedWhenClosed = false

        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openAbout() {
        if let window = aboutWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let aboutView = AboutView()

        let hostingController = NSHostingController(rootView: aboutView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "About AwakeApp"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 480, height: 460))
        window.center()
        window.isReleasedWhenClosed = false

        aboutWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
