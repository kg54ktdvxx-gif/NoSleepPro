//
//  MenuBarIconStyleTests.swift
//  AwakeAppTests
//
//  Unit tests for MenuBarIconStyle enum
//

import XCTest
@testable import AwakeApp

final class MenuBarIconStyleTests: XCTestCase {

    // MARK: - System Name Tests

    func testSystemNames() {
        XCTAssertEqual(MenuBarIconStyle.coffeeCup.systemName, "cup.and.saucer")
        XCTAssertEqual(MenuBarIconStyle.moon.systemName, "moon.zzz")
        XCTAssertEqual(MenuBarIconStyle.bolt.systemName, "bolt")
        XCTAssertEqual(MenuBarIconStyle.eye.systemName, "eye")
        XCTAssertEqual(MenuBarIconStyle.sun.systemName, "sun.max")
        XCTAssertEqual(MenuBarIconStyle.battery.systemName, "battery.100.bolt")
        XCTAssertEqual(MenuBarIconStyle.clock.systemName, "clock")
        XCTAssertEqual(MenuBarIconStyle.power.systemName, "power")
    }

    // MARK: - Filled System Name Tests

    func testFilledSystemNames() {
        XCTAssertEqual(MenuBarIconStyle.coffeeCup.filledSystemName, "cup.and.saucer.fill")
        XCTAssertEqual(MenuBarIconStyle.moon.filledSystemName, "moon.zzz.fill")
        XCTAssertEqual(MenuBarIconStyle.bolt.filledSystemName, "bolt.fill")
        XCTAssertEqual(MenuBarIconStyle.eye.filledSystemName, "eye.fill")
        XCTAssertEqual(MenuBarIconStyle.sun.filledSystemName, "sun.max.fill")
        XCTAssertEqual(MenuBarIconStyle.battery.filledSystemName, "battery.100.bolt")
        XCTAssertEqual(MenuBarIconStyle.clock.filledSystemName, "clock.fill")
        XCTAssertEqual(MenuBarIconStyle.power.filledSystemName, "power.circle.fill")
    }

    // MARK: - Display Name Tests

    func testDisplayNames() {
        XCTAssertEqual(MenuBarIconStyle.coffeeCup.displayName, "Coffee Cup")
        XCTAssertEqual(MenuBarIconStyle.moon.displayName, "Moon")
        XCTAssertEqual(MenuBarIconStyle.bolt.displayName, "Lightning Bolt")
        XCTAssertEqual(MenuBarIconStyle.eye.displayName, "Eye")
        XCTAssertEqual(MenuBarIconStyle.sun.displayName, "Sun")
        XCTAssertEqual(MenuBarIconStyle.battery.displayName, "Battery")
        XCTAssertEqual(MenuBarIconStyle.clock.displayName, "Clock")
        XCTAssertEqual(MenuBarIconStyle.power.displayName, "Power")
    }

    // MARK: - Raw Value Tests

    func testRawValues() {
        // Raw value should equal system name
        for style in MenuBarIconStyle.allCases {
            XCTAssertEqual(style.rawValue, style.systemName)
        }
    }

    func testInitFromRawValue() {
        XCTAssertEqual(MenuBarIconStyle(rawValue: "cup.and.saucer"), .coffeeCup)
        XCTAssertEqual(MenuBarIconStyle(rawValue: "moon.zzz"), .moon)
        XCTAssertEqual(MenuBarIconStyle(rawValue: "bolt"), .bolt)
        XCTAssertNil(MenuBarIconStyle(rawValue: "invalid"))
    }

    // MARK: - Identifiable Tests

    func testIdentifiable() {
        for style in MenuBarIconStyle.allCases {
            XCTAssertEqual(style.id, style.rawValue)
        }
    }

    // MARK: - All Cases Tests

    func testAllCasesCount() {
        XCTAssertEqual(MenuBarIconStyle.allCases.count, 8)
    }

    func testAllCasesUnique() {
        let ids = MenuBarIconStyle.allCases.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All icon style IDs should be unique")
    }

    // MARK: - Icon Pair Tests

    func testFilledDifferentFromRegular() {
        // Most icons should have different filled vs regular names
        // Exception: battery stays the same
        for style in MenuBarIconStyle.allCases where style != .battery {
            XCTAssertNotEqual(
                style.systemName,
                style.filledSystemName,
                "\(style) should have different regular and filled names"
            )
        }
    }

    func testBatteryIconsSame() {
        // Battery icon is the same filled and unfilled
        XCTAssertEqual(MenuBarIconStyle.battery.systemName, MenuBarIconStyle.battery.filledSystemName)
    }
}
