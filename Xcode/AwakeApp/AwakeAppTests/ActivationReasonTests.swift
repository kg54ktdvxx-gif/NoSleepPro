//
//  ActivationReasonTests.swift
//  AwakeAppTests
//
//  Unit tests for ActivationReason enum
//

import XCTest
@testable import AwakeApp

final class ActivationReasonTests: XCTestCase {

    // MARK: - Description Tests

    func testManualDescription() {
        XCTAssertEqual(ActivationReason.manual.description, "Manual")
    }

    func testScheduleDescription() {
        XCTAssertEqual(ActivationReason.schedule.description, "Schedule")
    }

    func testAppTriggerDescription() {
        let reason = ActivationReason.appTrigger(appName: "Zoom")
        XCTAssertEqual(reason.description, "App: Zoom")
    }

    func testKeyboardShortcutDescription() {
        XCTAssertEqual(ActivationReason.keyboardShortcut.description, "Shortcut")
    }

    func testWifiTriggerDescription() {
        let reason = ActivationReason.wifiTrigger(ssid: "HomeNetwork")
        XCTAssertEqual(reason.description, "Wi-Fi: HomeNetwork")
    }

    func testHardwareTriggerDescription() {
        let reason = ActivationReason.hardwareTrigger(type: "Power connected")
        XCTAssertEqual(reason.description, "Hardware: Power connected")
    }

    // MARK: - Equatable Tests

    func testEquatable() {
        XCTAssertEqual(ActivationReason.manual, ActivationReason.manual)
        XCTAssertEqual(ActivationReason.schedule, ActivationReason.schedule)
        XCTAssertNotEqual(ActivationReason.manual, ActivationReason.schedule)

        XCTAssertEqual(
            ActivationReason.appTrigger(appName: "Zoom"),
            ActivationReason.appTrigger(appName: "Zoom")
        )
        XCTAssertNotEqual(
            ActivationReason.appTrigger(appName: "Zoom"),
            ActivationReason.appTrigger(appName: "Teams")
        )

        XCTAssertEqual(
            ActivationReason.wifiTrigger(ssid: "Home"),
            ActivationReason.wifiTrigger(ssid: "Home")
        )
        XCTAssertNotEqual(
            ActivationReason.wifiTrigger(ssid: "Home"),
            ActivationReason.wifiTrigger(ssid: "Office")
        )

        XCTAssertEqual(
            ActivationReason.hardwareTrigger(type: "Power"),
            ActivationReason.hardwareTrigger(type: "Power")
        )
        XCTAssertNotEqual(
            ActivationReason.hardwareTrigger(type: "Power"),
            ActivationReason.hardwareTrigger(type: "Display")
        )
    }

    // MARK: - Pattern Matching Tests

    func testPatternMatching() {
        let reason = ActivationReason.appTrigger(appName: "Keynote")

        if case .appTrigger(let appName) = reason {
            XCTAssertEqual(appName, "Keynote")
        } else {
            XCTFail("Should match appTrigger case")
        }
    }
}
