//
//  TimerPresetTests.swift
//  AwakeAppTests
//
//  Unit tests for TimerPreset enum
//

import XCTest
@testable import AwakeApp

final class TimerPresetTests: XCTestCase {

    // MARK: - Seconds Tests

    func testFifteenMinutesReturnsCorrectSeconds() {
        XCTAssertEqual(TimerPreset.fifteenMinutes.seconds, 15 * 60)
    }

    func testThirtyMinutesReturnsCorrectSeconds() {
        XCTAssertEqual(TimerPreset.thirtyMinutes.seconds, 30 * 60)
    }

    func testOneHourReturnsCorrectSeconds() {
        XCTAssertEqual(TimerPreset.oneHour.seconds, 60 * 60)
    }

    func testTwoHoursReturnsCorrectSeconds() {
        XCTAssertEqual(TimerPreset.twoHours.seconds, 2 * 60 * 60)
    }

    func testFiveHoursReturnsCorrectSeconds() {
        XCTAssertEqual(TimerPreset.fiveHours.seconds, 5 * 60 * 60)
    }

    func testIndefiniteReturnsNil() {
        XCTAssertNil(TimerPreset.indefinite.seconds)
    }

    func testCustomReturnsCorrectSeconds() {
        XCTAssertEqual(TimerPreset.custom(minutes: 45).seconds, 45 * 60)
        XCTAssertEqual(TimerPreset.custom(minutes: 90).seconds, 90 * 60)
        XCTAssertEqual(TimerPreset.custom(minutes: 1).seconds, 60)
    }

    // MARK: - Minutes Tests

    func testMinutesProperty() {
        XCTAssertEqual(TimerPreset.fifteenMinutes.minutes, 15)
        XCTAssertEqual(TimerPreset.thirtyMinutes.minutes, 30)
        XCTAssertEqual(TimerPreset.oneHour.minutes, 60)
        XCTAssertEqual(TimerPreset.twoHours.minutes, 120)
        XCTAssertEqual(TimerPreset.fiveHours.minutes, 300)
        XCTAssertNil(TimerPreset.indefinite.minutes)
        XCTAssertEqual(TimerPreset.custom(minutes: 45).minutes, 45)
    }

    // MARK: - Display Name Tests

    func testDisplayNames() {
        XCTAssertEqual(TimerPreset.fifteenMinutes.displayName, "15 minutes")
        XCTAssertEqual(TimerPreset.thirtyMinutes.displayName, "30 minutes")
        XCTAssertEqual(TimerPreset.oneHour.displayName, "1 hour")
        XCTAssertEqual(TimerPreset.twoHours.displayName, "2 hours")
        XCTAssertEqual(TimerPreset.fiveHours.displayName, "5 hours")
        XCTAssertEqual(TimerPreset.indefinite.displayName, "Indefinite")
    }

    func testCustomDisplayNames() {
        XCTAssertEqual(TimerPreset.custom(minutes: 45).displayName, "45 minutes")
        XCTAssertEqual(TimerPreset.custom(minutes: 60).displayName, "1 hour")
        XCTAssertEqual(TimerPreset.custom(minutes: 90).displayName, "1h 30m")
        XCTAssertEqual(TimerPreset.custom(minutes: 120).displayName, "2 hours")
    }

    // MARK: - Short Display Name Tests

    func testShortDisplayNames() {
        XCTAssertEqual(TimerPreset.fifteenMinutes.shortDisplayName, "15m")
        XCTAssertEqual(TimerPreset.thirtyMinutes.shortDisplayName, "30m")
        XCTAssertEqual(TimerPreset.oneHour.shortDisplayName, "1h")
        XCTAssertEqual(TimerPreset.twoHours.shortDisplayName, "2h")
        XCTAssertEqual(TimerPreset.fiveHours.shortDisplayName, "5h")
        XCTAssertEqual(TimerPreset.indefinite.shortDisplayName, "∞")
    }

    func testCustomShortDisplayNames() {
        XCTAssertEqual(TimerPreset.custom(minutes: 45).shortDisplayName, "45m")
        XCTAssertEqual(TimerPreset.custom(minutes: 60).shortDisplayName, "1h")
        XCTAssertEqual(TimerPreset.custom(minutes: 90).shortDisplayName, "1h30m")
    }

    // MARK: - ID Tests

    func testUniqueIds() {
        let allPresets: [TimerPreset] = [
            .fifteenMinutes, .thirtyMinutes, .oneHour,
            .twoHours, .fiveHours, .indefinite
        ]

        let ids = allPresets.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All preset IDs should be unique")
    }

    func testCustomIdIncludesMinutes() {
        XCTAssertEqual(TimerPreset.custom(minutes: 45).id, "custom-45")
        XCTAssertEqual(TimerPreset.custom(minutes: 100).id, "custom-100")
    }

    // MARK: - isCustom Tests

    func testIsCustomProperty() {
        XCTAssertFalse(TimerPreset.fifteenMinutes.isCustom)
        XCTAssertFalse(TimerPreset.thirtyMinutes.isCustom)
        XCTAssertFalse(TimerPreset.oneHour.isCustom)
        XCTAssertFalse(TimerPreset.twoHours.isCustom)
        XCTAssertFalse(TimerPreset.fiveHours.isCustom)
        XCTAssertFalse(TimerPreset.indefinite.isCustom)
        XCTAssertTrue(TimerPreset.custom(minutes: 45).isCustom)
    }

    // MARK: - Equatable Tests

    func testEquatable() {
        XCTAssertEqual(TimerPreset.oneHour, TimerPreset.oneHour)
        XCTAssertNotEqual(TimerPreset.oneHour, TimerPreset.twoHours)
        XCTAssertEqual(TimerPreset.custom(minutes: 45), TimerPreset.custom(minutes: 45))
        XCTAssertNotEqual(TimerPreset.custom(minutes: 45), TimerPreset.custom(minutes: 46))
    }

    // MARK: - Hashable Tests

    func testHashable() {
        var set = Set<TimerPreset>()
        set.insert(.oneHour)
        set.insert(.oneHour)
        set.insert(.twoHours)
        set.insert(.custom(minutes: 45))
        set.insert(.custom(minutes: 45))

        XCTAssertEqual(set.count, 3)
    }

    // MARK: - allCases Tests

    func testAllCasesDoesNotIncludeCustom() {
        let allCases = TimerPreset.allCases
        XCTAssertEqual(allCases.count, 6)
        XCTAssertFalse(allCases.contains(where: { $0.isCustom }))
    }
}
