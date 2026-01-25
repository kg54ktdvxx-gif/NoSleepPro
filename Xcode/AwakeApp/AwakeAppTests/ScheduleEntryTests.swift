//
//  ScheduleEntryTests.swift
//  AwakeAppTests
//
//  Unit tests for ScheduleEntry and Weekday
//

import XCTest
@testable import AwakeApp

final class ScheduleEntryTests: XCTestCase {

    // MARK: - Weekday Tests

    func testWeekdayRawValues() {
        XCTAssertEqual(ScheduleEntry.Weekday.sunday.rawValue, 1)
        XCTAssertEqual(ScheduleEntry.Weekday.monday.rawValue, 2)
        XCTAssertEqual(ScheduleEntry.Weekday.tuesday.rawValue, 3)
        XCTAssertEqual(ScheduleEntry.Weekday.wednesday.rawValue, 4)
        XCTAssertEqual(ScheduleEntry.Weekday.thursday.rawValue, 5)
        XCTAssertEqual(ScheduleEntry.Weekday.friday.rawValue, 6)
        XCTAssertEqual(ScheduleEntry.Weekday.saturday.rawValue, 7)
    }

    func testWeekdayShortNames() {
        XCTAssertEqual(ScheduleEntry.Weekday.sunday.shortName, "Sun")
        XCTAssertEqual(ScheduleEntry.Weekday.monday.shortName, "Mon")
        XCTAssertEqual(ScheduleEntry.Weekday.tuesday.shortName, "Tue")
        XCTAssertEqual(ScheduleEntry.Weekday.wednesday.shortName, "Wed")
        XCTAssertEqual(ScheduleEntry.Weekday.thursday.shortName, "Thu")
        XCTAssertEqual(ScheduleEntry.Weekday.friday.shortName, "Fri")
        XCTAssertEqual(ScheduleEntry.Weekday.saturday.shortName, "Sat")
    }

    func testWeekdayInitials() {
        XCTAssertEqual(ScheduleEntry.Weekday.sunday.initial, "S")
        XCTAssertEqual(ScheduleEntry.Weekday.monday.initial, "M")
        XCTAssertEqual(ScheduleEntry.Weekday.tuesday.initial, "T")
        XCTAssertEqual(ScheduleEntry.Weekday.wednesday.initial, "W")
        XCTAssertEqual(ScheduleEntry.Weekday.thursday.initial, "T")
        XCTAssertEqual(ScheduleEntry.Weekday.friday.initial, "F")
        XCTAssertEqual(ScheduleEntry.Weekday.saturday.initial, "S")
    }

    func testWeekdayAllCases() {
        XCTAssertEqual(ScheduleEntry.Weekday.allCases.count, 7)
    }

    func testWeekdayIdentifiable() {
        let monday = ScheduleEntry.Weekday.monday
        XCTAssertEqual(monday.id, monday.rawValue)
    }

    // MARK: - ScheduleEntry Tests

    func testDefaultScheduleEntry() {
        let entry = ScheduleEntry()

        XCTAssertTrue(entry.isEnabled)
        XCTAssertEqual(entry.days, [.monday, .tuesday, .wednesday, .thursday, .friday])
        XCTAssertNotNil(entry.id)
    }

    func testScheduleEntryEquatable() {
        var entry1 = ScheduleEntry()
        var entry2 = entry1

        XCTAssertEqual(entry1, entry2)

        entry2.isEnabled = false
        XCTAssertNotEqual(entry1, entry2)
    }

    func testScheduleEntryIdentifiable() {
        let entry = ScheduleEntry()
        XCTAssertNotNil(entry.id)
    }

    func testScheduleEntryCodable() throws {
        let entry = ScheduleEntry()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(entry)
        let decoded = try decoder.decode(ScheduleEntry.self, from: data)

        XCTAssertEqual(entry.id, decoded.id)
        XCTAssertEqual(entry.isEnabled, decoded.isEnabled)
        XCTAssertEqual(entry.days, decoded.days)
    }

    func testWeekdaySetOperations() {
        var days: Set<ScheduleEntry.Weekday> = [.monday, .wednesday, .friday]

        XCTAssertTrue(days.contains(.monday))
        XCTAssertFalse(days.contains(.tuesday))

        days.insert(.tuesday)
        XCTAssertTrue(days.contains(.tuesday))

        days.remove(.monday)
        XCTAssertFalse(days.contains(.monday))
    }
}
