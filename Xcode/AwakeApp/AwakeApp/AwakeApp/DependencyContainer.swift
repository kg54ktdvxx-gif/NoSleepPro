//
//  DependencyContainer.swift
//  AwakeApp
//
//  Centralized dependency container for the app
//  - Production: Use DependencyContainer.shared
//  - Testing: Create new instance with mock dependencies
//

import SwiftUI

/// Centralized dependency container for the app
/// Provides singleton access for production and test-friendly initialization for unit tests
@MainActor
final class DependencyContainer {

    // MARK: - Shared Instance (Production)

    static let shared = DependencyContainer()

    // MARK: - Core Services

    /// App state management
    let appState: AppState

    /// Power assertion management
    let caffeinateManager: CaffeinateManager

    /// App settings
    let settings: AppSettings

    // MARK: - Automation Services

    /// Automation manager (schedules, triggers, battery protection)
    let automationManager: AutomationManager

    // MARK: - Utility Services

    /// Mouse jiggler
    let mouseJiggler: MouseJiggler

    /// Notification manager
    let notificationManager: NotificationManager

    /// Keyboard shortcut manager
    let keyboardShortcutManager: KeyboardShortcutManager

    /// Window manager
    let windowManager: WindowManager

    /// Closed lid manager
    let closedLidManager: ClosedLidManager

    // MARK: - Initialization

    /// Production initializer - uses real implementations
    private init() {
        self.appState = AppState()
        self.caffeinateManager = CaffeinateManager()
        self.settings = AppSettings.shared
        self.mouseJiggler = MouseJiggler.shared
        self.notificationManager = NotificationManager.shared
        self.keyboardShortcutManager = KeyboardShortcutManager.shared
        self.windowManager = WindowManager.shared
        self.closedLidManager = ClosedLidManager.shared

        // AutomationManager needs core dependencies
        self.automationManager = AutomationManager(
            settings: settings,
            appState: appState,
            caffeinateManager: caffeinateManager
        )
    }

    /// Test-friendly initializer - accepts mock dependencies
    /// Use this for unit testing with mock implementations
    init(
        appState: AppState,
        caffeinateManager: CaffeinateManager,
        settings: AppSettings,
        mouseJiggler: MouseJiggler,
        notificationManager: NotificationManager,
        keyboardShortcutManager: KeyboardShortcutManager,
        windowManager: WindowManager,
        closedLidManager: ClosedLidManager,
        automationManager: AutomationManager
    ) {
        self.appState = appState
        self.caffeinateManager = caffeinateManager
        self.settings = settings
        self.mouseJiggler = mouseJiggler
        self.notificationManager = notificationManager
        self.keyboardShortcutManager = keyboardShortcutManager
        self.windowManager = windowManager
        self.closedLidManager = closedLidManager
        self.automationManager = automationManager
    }

    // MARK: - Lifecycle

    /// Start all monitoring services - call at app launch
    func startServices() {
        automationManager.startMonitoring()
    }

    /// Stop all monitoring services - call at app termination
    func stopServices() {
        automationManager.stopMonitoring()
    }
}
