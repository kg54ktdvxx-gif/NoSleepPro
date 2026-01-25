//
//  WiFiMonitor.swift
//  AwakeApp
//
//  Monitors Wi-Fi network connections for trigger-based activation
//

import Foundation
import Combine
import CoreWLAN
import os.log

private let logger = Logger(subsystem: "com.awakeapp", category: "WiFi")

/// Wi-Fi network trigger configuration
struct WiFiTrigger: Codable, Identifiable, Equatable {
    var id = UUID()
    var ssid: String
    var isEnabled: Bool = true
}

@MainActor
class WiFiMonitor: ObservableObject {
    static let shared = WiFiMonitor()

    @Published var currentSSID: String?
    @Published var isConnected: Bool = false
    @Published var lastError: WiFiError?

    private var timer: Timer?
    private let wifiClient = CWWiFiClient.shared()
    private var previousSSID: String?

    private init() {
        updateCurrentNetwork()
    }

    func startMonitoring() {
        lastError = nil
        updateCurrentNetwork()

        // Check every 10 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCurrentNetwork()
            }
        }

        logger.info("Wi-Fi monitoring started")
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        logger.info("Wi-Fi monitoring stopped")
    }

    private func updateCurrentNetwork() {
        guard let interface = wifiClient.interface() else {
            if currentSSID != nil {
                // Only log/error if we were previously connected
                lastError = .noInterface
                logger.warning("No Wi-Fi interface available")
            }
            currentSSID = nil
            isConnected = false
            return
        }

        // Clear any previous interface errors
        if lastError == .noInterface {
            lastError = nil
        }

        let ssid = interface.ssid()
        let wasConnected = isConnected

        currentSSID = ssid
        isConnected = ssid != nil

        // Log state changes
        if previousSSID != ssid {
            if let newSSID = ssid {
                if previousSSID == nil {
                    logger.info("Connected to Wi-Fi: \(newSSID)")
                } else {
                    logger.info("Wi-Fi changed to: \(newSSID)")
                }
            } else if previousSSID != nil {
                logger.info("Disconnected from Wi-Fi")
            }
            previousSSID = ssid
        }
    }

    /// Check if currently connected to a trigger network
    func isConnectedToTriggerNetwork(triggers: [WiFiTrigger]) -> WiFiTrigger? {
        guard let currentSSID = currentSSID else { return nil }

        return triggers.first { trigger in
            trigger.isEnabled && trigger.ssid.lowercased() == currentSSID.lowercased()
        }
    }

    /// Get list of known/saved networks (if available)
    func getKnownNetworks() -> [String] {
        // Note: Getting saved networks requires additional entitlements
        // For now, just return current network if connected
        if let ssid = currentSSID {
            return [ssid]
        }
        return []
    }

    /// Force refresh network status
    func refresh() {
        updateCurrentNetwork()
    }
}
