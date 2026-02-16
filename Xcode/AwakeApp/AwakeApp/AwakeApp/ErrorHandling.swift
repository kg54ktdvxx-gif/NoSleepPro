//
//  ErrorHandling.swift
//  AwakeApp
//
//  Centralized error handling and user feedback
//

import Foundation
import Combine
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "thisisvision.AwakeApp", category: "Error")

// MARK: - App Error Types

/// Errors related to keyboard shortcuts
enum KeyboardShortcutError: LocalizedError {
    case registrationFailed
    case invalidShortcut
    case shortcutConflict(existingApp: String?)

    var errorDescription: String? {
        switch self {
        case .registrationFailed:
            return "Failed to register keyboard shortcut"
        case .invalidShortcut:
            return "Invalid keyboard shortcut"
        case .shortcutConflict(let app):
            if let app = app {
                return "Shortcut conflicts with \(app)"
            }
            return "Shortcut conflicts with another app"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .registrationFailed:
            return "The shortcut may conflict with another app. Try a different key combination."
        case .invalidShortcut:
            return "Choose a different key combination with Command or Control."
        case .shortcutConflict:
            return "Choose a different keyboard shortcut."
        }
    }
}

/// Errors related to hardware monitoring
enum HardwareMonitorError: LocalizedError {
    case batteryInfoUnavailable
    case displayInfoUnavailable
    case powerSourceUnknown

    var errorDescription: String? {
        switch self {
        case .batteryInfoUnavailable:
            return "Unable to read battery information"
        case .displayInfoUnavailable:
            return "Unable to detect connected displays"
        case .powerSourceUnknown:
            return "Unable to determine power source"
        }
    }
}

// MARK: - Error Handler

/// Centralized error handler for logging and user feedback
@MainActor
final class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()

    /// Current error to display to user (if any)
    @Published var currentError: (any LocalizedError)?

    /// Whether to show error alert
    @Published var showingError: Bool = false

    private init() {}

    /// Log and optionally display an error
    func handle(_ error: any LocalizedError, display: Bool = false) {
        logger.error("Error: \(error.localizedDescription)")

        if let recovery = error.recoverySuggestion {
            logger.info("Recovery suggestion: \(recovery)")
        }

        if display {
            currentError = error
            showingError = true
        }
    }

    /// Log a non-fatal warning
    func warn(_ message: String) {
        logger.warning("\(message)")
    }

    /// Log debug information
    func debug(_ message: String) {
        logger.debug("\(message)")
    }

    /// Dismiss current error
    func dismissError() {
        currentError = nil
        showingError = false
    }
}

// MARK: - Result Extension

extension Result where Failure: LocalizedError {
    /// Handle result with error handler
    @MainActor
    func handleError(display: Bool = false) {
        if case .failure(let error) = self {
            ErrorHandler.shared.handle(error, display: display)
        }
    }
}

