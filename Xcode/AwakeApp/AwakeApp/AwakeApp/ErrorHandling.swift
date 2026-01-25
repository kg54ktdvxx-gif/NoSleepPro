//
//  ErrorHandling.swift
//  AwakeApp
//
//  Centralized error handling and user feedback
//

import Foundation
import Combine
import os.log

private let logger = Logger(subsystem: "com.awakeapp", category: "Error")

// MARK: - App Error Types

/// Errors related to WiFi monitoring
enum WiFiError: LocalizedError, Equatable {
    case noInterface
    case monitoringFailed(underlying: Error?)
    case ssidUnavailable

    static func == (lhs: WiFiError, rhs: WiFiError) -> Bool {
        switch (lhs, rhs) {
        case (.noInterface, .noInterface):
            return true
        case (.ssidUnavailable, .ssidUnavailable):
            return true
        case (.monitoringFailed, .monitoringFailed):
            return true
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .noInterface:
            return "No Wi-Fi interface available"
        case .monitoringFailed(let error):
            if let error = error {
                return "Wi-Fi monitoring failed: \(error.localizedDescription)"
            }
            return "Wi-Fi monitoring failed"
        case .ssidUnavailable:
            return "Unable to read current network name"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noInterface:
            return "Make sure Wi-Fi is enabled on your Mac."
        case .monitoringFailed:
            return "Try disabling and re-enabling Wi-Fi triggers."
        case .ssidUnavailable:
            return "Grant location permission to access Wi-Fi network information."
        }
    }
}

/// Errors related to mouse jiggler
enum MouseJigglerError: LocalizedError {
    case noAccessibilityPermission
    case eventCreationFailed
    case positionUnavailable

    var errorDescription: String? {
        switch self {
        case .noAccessibilityPermission:
            return "Accessibility permission required"
        case .eventCreationFailed:
            return "Failed to create mouse movement event"
        case .positionUnavailable:
            return "Unable to get current mouse position"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noAccessibilityPermission:
            return "Open System Settings > Privacy & Security > Accessibility and enable AwakeApp."
        case .eventCreationFailed, .positionUnavailable:
            return "Try restarting the app."
        }
    }
}

/// Errors related to keyboard shortcuts
enum KeyboardShortcutError: LocalizedError {
    case monitoringFailed
    case invalidShortcut
    case shortcutConflict(existingApp: String?)

    var errorDescription: String? {
        switch self {
        case .monitoringFailed:
            return "Failed to monitor keyboard events"
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
        case .monitoringFailed:
            return "Grant accessibility permission in System Settings."
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

// MARK: - Safe Execution

/// Execute a throwing closure and handle errors gracefully
@MainActor
func safeExecute<T>(
    _ operation: () throws -> T,
    onError: ((Error) -> Void)? = nil,
    defaultValue: T? = nil
) -> T? {
    do {
        return try operation()
    } catch let error as any LocalizedError {
        ErrorHandler.shared.handle(error)
        onError?(error)
        return defaultValue
    } catch {
        logger.error("Unexpected error: \(error.localizedDescription)")
        onError?(error)
        return defaultValue
    }
}

/// Execute an async throwing closure and handle errors gracefully
@MainActor
func safeExecuteAsync<T>(
    _ operation: () async throws -> T,
    onError: ((Error) -> Void)? = nil,
    defaultValue: T? = nil
) async -> T? {
    do {
        return try await operation()
    } catch let error as any LocalizedError {
        ErrorHandler.shared.handle(error)
        onError?(error)
        return defaultValue
    } catch {
        logger.error("Unexpected error: \(error.localizedDescription)")
        onError?(error)
        return defaultValue
    }
}
