//
//  ScenarioPresetTests.swift
//  AwakeAppTests
//
//  Unit tests for ScenarioPreset enum
//

import XCTest
@testable import AwakeApp

final class ScenarioPresetTests: XCTestCase {

    // MARK: - CaseIterable

    func testAllCasesContainsBothPresets() {
        XCTAssertEqual(ScenarioPreset.allCases.count, 2)
        XCTAssertTrue(ScenarioPreset.allCases.contains(.claudeCode))
        XCTAssertTrue(ScenarioPreset.allCases.contains(.browserActive))
    }

    // MARK: - Display Names

    func testClaudeCodeDisplayName() {
        XCTAssertEqual(ScenarioPreset.claudeCode.displayName, "Claude Code")
    }

    func testBrowserActiveDisplayName() {
        XCTAssertEqual(ScenarioPreset.browserActive.displayName, "Browser Active")
    }

    // MARK: - Subtitles

    func testClaudeCodeSubtitle() {
        XCTAssertEqual(ScenarioPreset.claudeCode.subtitle, "System awake, display sleeps")
    }

    func testBrowserActiveSubtitle() {
        XCTAssertEqual(ScenarioPreset.browserActive.subtitle, "Display & system stay awake")
    }

    // MARK: - Icon Names

    func testClaudeCodeIconName() {
        XCTAssertEqual(ScenarioPreset.claudeCode.iconName, "terminal")
    }

    func testBrowserActiveIconName() {
        XCTAssertEqual(ScenarioPreset.browserActive.iconName, "globe")
    }

    // MARK: - Allow Display Sleep

    func testClaudeCodeAllowsDisplaySleep() {
        XCTAssertTrue(ScenarioPreset.claudeCode.allowDisplaySleep)
    }

    func testBrowserActiveDoesNotAllowDisplaySleep() {
        XCTAssertFalse(ScenarioPreset.browserActive.allowDisplaySleep)
    }

    // MARK: - Assertion Types

    func testClaudeCodeAssertionType() {
        XCTAssertEqual(ScenarioPreset.claudeCode.assertionType, kIOPMAssertionTypeNoIdleSleep as String)
    }

    func testBrowserActiveAssertionType() {
        XCTAssertEqual(ScenarioPreset.browserActive.assertionType, kIOPMAssertionTypeNoDisplaySleep as String)
    }

    // MARK: - Identifiable

    func testIdentifiable() {
        XCTAssertEqual(ScenarioPreset.claudeCode.id, "claudeCode")
        XCTAssertEqual(ScenarioPreset.browserActive.id, "browserActive")
        XCTAssertNotEqual(ScenarioPreset.claudeCode.id, ScenarioPreset.browserActive.id)
    }

    // MARK: - Equatable

    func testEquatable() {
        XCTAssertEqual(ScenarioPreset.claudeCode, ScenarioPreset.claudeCode)
        XCTAssertEqual(ScenarioPreset.browserActive, ScenarioPreset.browserActive)
        XCTAssertNotEqual(ScenarioPreset.claudeCode, ScenarioPreset.browserActive)
    }
}
