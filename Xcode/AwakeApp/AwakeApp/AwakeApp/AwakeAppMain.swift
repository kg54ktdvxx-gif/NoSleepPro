//
//  AwakeAppMain.swift
//  AwakeApp
//
//  Main app entry point with MenuBarExtra
//

import SwiftUI

@main
struct AwakeAppMain: App {
    @StateObject private var appState = AppState()
    @StateObject private var caffeinateManager = CaffeinateManager()
    @StateObject private var settings = AppSettings.shared
    @StateObject private var automationManager: AutomationManager

    init() {
        // Initialize automation manager with dependencies
        let settings = AppSettings.shared
        let appState = AppState()
        let caffeinateManager = CaffeinateManager()

        _appState = StateObject(wrappedValue: appState)
        _caffeinateManager = StateObject(wrappedValue: caffeinateManager)
        _settings = StateObject(wrappedValue: settings)
        _automationManager = StateObject(wrappedValue: AutomationManager(
            settings: settings,
            appState: appState,
            caffeinateManager: caffeinateManager
        ))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(caffeinateManager)
                .environmentObject(settings)
                .environmentObject(automationManager)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)

        // Settings window - opens separately from menu bar
        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(settings)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // About window
        Window("About AwakeApp", id: "about") {
            AboutView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    /// Menu bar icon with optional countdown
    @ViewBuilder
    private var menuBarLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: appState.isActive
                ? settings.menuBarIconStyle.filledSystemName
                : settings.menuBarIconStyle.systemName)
                .symbolRenderingMode(.hierarchical)

            // Show countdown in menu bar if enabled and timer is active
            if settings.showMenuBarCountdown,
               appState.isActive,
               let remaining = appState.remainingSeconds {
                Text(formatMenuBarTime(remaining))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .monospacedDigit()
            }
        }
    }

    /// Format time for menu bar display (compact)
    private func formatMenuBarTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes))"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}
