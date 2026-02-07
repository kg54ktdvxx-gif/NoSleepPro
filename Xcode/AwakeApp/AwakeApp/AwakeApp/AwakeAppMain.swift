//
//  AwakeAppMain.swift
//  AwakeApp
//
//  Main app entry point with MenuBarExtra
//

import SwiftUI

@main
struct AwakeAppMain: App {
    /// Centralized dependency container
    private let container = DependencyContainer.shared

    init() {
        // Start monitoring services at app launch
        Task { @MainActor in
            DependencyContainer.shared.startServices()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(container.appState)
                .environmentObject(container.caffeinateManager)
                .environmentObject(container.settings)
                .environmentObject(container.automationManager)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    /// Menu bar icon with optional countdown
    @ViewBuilder
    private var menuBarLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: container.appState.isActive
                ? container.settings.menuBarIconStyle.filledSystemName
                : container.settings.menuBarIconStyle.systemName)
                .symbolRenderingMode(.hierarchical)

            // Show countdown in menu bar if enabled and timer is active
            if container.settings.showMenuBarCountdown,
               container.appState.isActive,
               let remaining = container.appState.remainingSeconds {
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
