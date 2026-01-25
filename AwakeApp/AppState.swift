//
//  AppState.swift
//  AwakeApp
//
//  Observable state management for sleep prevention status and timer
//

import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isActive: Bool = false
    @Published var currentPreset: TimerPreset?
    @Published var remainingSeconds: Int?

    private var timer: Timer?
    private var expirationDate: Date?

    /// Activate sleep prevention with a timer preset
    func activate(with preset: TimerPreset) {
        self.currentPreset = preset
        self.isActive = true

        if let seconds = preset.seconds {
            self.remainingSeconds = seconds
            self.expirationDate = Date().addingTimeInterval(TimeInterval(seconds))
            startCountdownTimer()
        } else {
            // Indefinite mode - no timer
            self.remainingSeconds = nil
            self.expirationDate = nil
        }
    }

    /// Deactivate sleep prevention
    func deactivate() {
        self.isActive = false
        self.currentPreset = nil
        self.remainingSeconds = nil
        self.expirationDate = nil
        stopCountdownTimer()
    }

    /// Start countdown timer for timed presets
    private func startCountdownTimer() {
        stopCountdownTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self,
                      let expiration = self.expirationDate else { return }

                let remaining = Int(expiration.timeIntervalSinceNow)

                if remaining <= 0 {
                    self.deactivate()
                } else {
                    self.remainingSeconds = remaining
                }
            }
        }
    }

    /// Stop countdown timer
    private func stopCountdownTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// Formatted status text for display
    var statusText: String {
        if !isActive {
            return "Inactive"
        }

        guard let remaining = remainingSeconds else {
            return "Active (Indefinite)"
        }

        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60

        if hours > 0 {
            return String(format: "Active (%02d:%02d:%02d)", hours, minutes, seconds)
        } else {
            return String(format: "Active (%02d:%02d)", minutes, seconds)
        }
    }
}
