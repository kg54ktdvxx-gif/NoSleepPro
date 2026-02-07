//
//  TriggerModelsTests.swift
//  AwakeAppTests
//
//  Unit tests for AppTrigger model
//

import XCTest
@testable import AwakeApp

final class TriggerModelsTests: XCTestCase {

    // MARK: - AppTrigger Tests

    func testAppTriggerDefaults() {
        let trigger = AppTrigger(bundleIdentifier: "com.example.app", appName: "Example")

        XCTAssertEqual(trigger.bundleIdentifier, "com.example.app")
        XCTAssertEqual(trigger.appName, "Example")
        XCTAssertTrue(trigger.isEnabled)
        XCTAssertNotNil(trigger.id)
    }

    func testAppTriggerEquatable() {
        let trigger1 = AppTrigger(bundleIdentifier: "com.example.app", appName: "Example")
        var trigger2 = trigger1

        XCTAssertEqual(trigger1, trigger2)

        trigger2.isEnabled = false
        XCTAssertNotEqual(trigger1, trigger2)
    }

    func testAppTriggerCodable() throws {
        let trigger = AppTrigger(bundleIdentifier: "com.zoom.xos", appName: "Zoom", isEnabled: false)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(trigger)
        let decoded = try decoder.decode(AppTrigger.self, from: data)

        XCTAssertEqual(trigger.id, decoded.id)
        XCTAssertEqual(trigger.bundleIdentifier, decoded.bundleIdentifier)
        XCTAssertEqual(trigger.appName, decoded.appName)
        XCTAssertEqual(trigger.isEnabled, decoded.isEnabled)
    }

    func testAppTriggerIdentifiable() {
        let trigger = AppTrigger(bundleIdentifier: "com.example.app", appName: "Example")
        XCTAssertNotNil(trigger.id)
    }

    // MARK: - Array Operations Tests

    func testAppTriggerArrayContains() {
        let triggers = [
            AppTrigger(bundleIdentifier: "com.zoom.xos", appName: "Zoom"),
            AppTrigger(bundleIdentifier: "com.apple.Keynote", appName: "Keynote")
        ]

        let hasZoom = triggers.contains { $0.bundleIdentifier == "com.zoom.xos" }
        let hasTeams = triggers.contains { $0.bundleIdentifier == "com.microsoft.teams" }

        XCTAssertTrue(hasZoom)
        XCTAssertFalse(hasTeams)
    }
}
