//
//  MouseJiggler.swift
//  AwakeApp
//
//  Periodically moves the mouse cursor to prevent "Away" status in chat apps
//  Requires Accessibility permission
//

import Foundation
import Combine
import CoreGraphics
import AppKit
import os.log

private let logger = Logger(subsystem: "com.awakeapp", category: "MouseJiggler")

@MainActor
class MouseJiggler: ObservableObject {
    static let shared = MouseJiggler()

    @Published var isRunning = false
    @Published var hasAccessibilityPermission = false
    @Published var lastError: MouseJigglerError?

    private var timer: Timer?
    private var jiggleDirection: CGFloat = 1
    private var consecutiveFailures = 0
    private let maxConsecutiveFailures = 3

    private init() {
        checkAccessibilityPermission()
    }

    /// Check if we have accessibility permission
    func checkAccessibilityPermission() {
        hasAccessibilityPermission = AXIsProcessTrusted()
        if hasAccessibilityPermission {
            lastError = nil
        }
    }

    /// Request accessibility permission (opens System Preferences)
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        // Check again after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.checkAccessibilityPermission()
        }
    }

    /// Start the mouse jiggler
    /// - Parameter intervalSeconds: How often to jiggle (default 60 seconds)
    /// - Returns: Result indicating success or failure
    @discardableResult
    func start(intervalSeconds: Double = 60) -> Result<Void, MouseJigglerError> {
        // Check permission first
        checkAccessibilityPermission()

        guard hasAccessibilityPermission else {
            let error = MouseJigglerError.noAccessibilityPermission
            lastError = error
            logger.warning("Cannot start mouse jiggler: no accessibility permission")
            requestAccessibilityPermission()
            return .failure(error)
        }

        stop()
        lastError = nil
        consecutiveFailures = 0

        timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.jiggle()
            }
        }

        isRunning = true
        logger.info("Mouse jiggler started (interval: \(intervalSeconds)s)")
        return .success(())
    }

    /// Stop the mouse jiggler
    func stop() {
        timer?.invalidate()
        timer = nil
        if isRunning {
            isRunning = false
            logger.info("Mouse jiggler stopped")
        }
        consecutiveFailures = 0
    }

    /// Perform a single jiggle (move 1 pixel and back)
    private func jiggle() {
        guard let currentPosition = CGEvent(source: nil)?.location else {
            handleJiggleFailure(.positionUnavailable)
            return
        }

        // Move 1 pixel in alternating direction
        let newPosition = CGPoint(
            x: currentPosition.x + jiggleDirection,
            y: currentPosition.y
        )

        // Create and post the move event
        guard let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: newPosition,
            mouseButton: .left
        ) else {
            handleJiggleFailure(.eventCreationFailed)
            return
        }

        moveEvent.post(tap: .cghidEventTap)

        // Move back after a tiny delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let moveBack = CGEvent(
                mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: currentPosition,
                mouseButton: .left
            ) else {
                return // Don't fail on return movement
            }

            moveBack.post(tap: .cghidEventTap)

            // Alternate direction for next jiggle
            self?.jiggleDirection *= -1
        }

        // Success - reset failure counter
        consecutiveFailures = 0
        lastError = nil
        logger.debug("Mouse jiggled")
    }

    private func handleJiggleFailure(_ error: MouseJigglerError) {
        consecutiveFailures += 1
        lastError = error
        logger.error("Jiggle failed: \(error.localizedDescription)")

        // Stop after too many consecutive failures
        if consecutiveFailures >= maxConsecutiveFailures {
            logger.error("Too many consecutive jiggle failures, stopping")
            stop()
            ErrorHandler.shared.handle(error, display: true)
        }
    }

    /// Jiggle intervals available to users
    static let availableIntervals: [(label: String, seconds: Double)] = [
        ("30 seconds", 30),
        ("1 minute", 60),
        ("2 minutes", 120),
        ("5 minutes", 300)
    ]
}
