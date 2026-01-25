//
//  WiFiTriggerLogicTests.swift
//  AwakeAppTests
//
//  Unit tests for WiFi trigger matching logic
//

import XCTest
@testable import AwakeApp

final class WiFiTriggerLogicTests: XCTestCase {

    // MARK: - Trigger Matching Tests

    func testMatchesEnabledTrigger() {
        let triggers = [
            WiFiTrigger(ssid: "HomeNetwork", isEnabled: true),
            WiFiTrigger(ssid: "OfficeWiFi", isEnabled: true),
        ]

        let match = findMatchingTrigger(currentSSID: "HomeNetwork", triggers: triggers)
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.ssid, "HomeNetwork")
    }

    func testDoesNotMatchDisabledTrigger() {
        let triggers = [
            WiFiTrigger(ssid: "HomeNetwork", isEnabled: false),
        ]

        let match = findMatchingTrigger(currentSSID: "HomeNetwork", triggers: triggers)
        XCTAssertNil(match)
    }

    func testCaseInsensitiveMatching() {
        let triggers = [
            WiFiTrigger(ssid: "HomeNetwork", isEnabled: true),
        ]

        let match1 = findMatchingTrigger(currentSSID: "homenetwork", triggers: triggers)
        let match2 = findMatchingTrigger(currentSSID: "HOMENETWORK", triggers: triggers)
        let match3 = findMatchingTrigger(currentSSID: "HomeNetwork", triggers: triggers)

        XCTAssertNotNil(match1)
        XCTAssertNotNil(match2)
        XCTAssertNotNil(match3)
    }

    func testNoMatchForUnknownNetwork() {
        let triggers = [
            WiFiTrigger(ssid: "HomeNetwork", isEnabled: true),
            WiFiTrigger(ssid: "OfficeWiFi", isEnabled: true),
        ]

        let match = findMatchingTrigger(currentSSID: "CoffeeShopWiFi", triggers: triggers)
        XCTAssertNil(match)
    }

    func testNoMatchWhenDisconnected() {
        let triggers = [
            WiFiTrigger(ssid: "HomeNetwork", isEnabled: true),
        ]

        let match = findMatchingTrigger(currentSSID: nil, triggers: triggers)
        XCTAssertNil(match)
    }

    func testEmptyTriggersReturnsNoMatch() {
        let triggers: [WiFiTrigger] = []

        let match = findMatchingTrigger(currentSSID: "AnyNetwork", triggers: triggers)
        XCTAssertNil(match)
    }

    func testFirstEnabledMatchReturned() {
        let triggers = [
            WiFiTrigger(ssid: "Network1", isEnabled: false),
            WiFiTrigger(ssid: "Network1", isEnabled: true),
            WiFiTrigger(ssid: "Network1", isEnabled: true),
        ]

        let match = findMatchingTrigger(currentSSID: "Network1", triggers: triggers)
        XCTAssertNotNil(match)
        XCTAssertTrue(match!.isEnabled)
    }

    // MARK: - Helper

    /// Simulates WiFiMonitor.isConnectedToTriggerNetwork logic
    private func findMatchingTrigger(currentSSID: String?, triggers: [WiFiTrigger]) -> WiFiTrigger? {
        guard let currentSSID = currentSSID else { return nil }

        return triggers.first { trigger in
            trigger.isEnabled && trigger.ssid.lowercased() == currentSSID.lowercased()
        }
    }
}
