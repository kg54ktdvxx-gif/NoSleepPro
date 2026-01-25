//
//  ScheduleLogicTests.swift
//  AwakeAppTests
//
//  Unit tests for schedule matching logic
//

import XCTest
@testable import AwakeApp

final class ScheduleLogicTests: XCTestCase {

    // MARK: - Schedule Active Tests

    func testScheduleActiveWithinTimeRange() {
        let schedule = createSchedule(
            days: [.monday],
            startHour: 9,
            startMinute: 0,
            endHour: 17,
            endMinute: 0
        )

        // 10:00 AM on Monday should be active
        let isActive = isScheduleActive(
            schedule: schedule,
            currentWeekday: 2, // Monday
            currentHour: 10,
            currentMinute: 0
        )

        XCTAssertTrue(isActive)
    }

    func testScheduleNotActiveOutsideTimeRange() {
        let schedule = createSchedule(
            days: [.monday],
            startHour: 9,
            startMinute: 0,
            endHour: 17,
            endMinute: 0
        )

        // 8:00 AM (before start)
        let beforeStart = isScheduleActive(
            schedule: schedule,
            currentWeekday: 2,
            currentHour: 8,
            currentMinute: 0
        )
        XCTAssertFalse(beforeStart)

        // 6:00 PM (after end)
        let afterEnd = isScheduleActive(
            schedule: schedule,
            currentWeekday: 2,
            currentHour: 18,
            currentMinute: 0
        )
        XCTAssertFalse(afterEnd)
    }

    func testScheduleNotActiveOnWrongDay() {
        let schedule = createSchedule(
            days: [.monday, .wednesday, .friday],
            startHour: 9,
            startMinute: 0,
            endHour: 17,
            endMinute: 0
        )

        // Tuesday at 10:00 AM
        let isActive = isScheduleActive(
            schedule: schedule,
            currentWeekday: 3, // Tuesday
            currentHour: 10,
            currentMinute: 0
        )

        XCTAssertFalse(isActive)
    }

    func testScheduleDisabledNotActive() {
        var schedule = createSchedule(
            days: [.monday],
            startHour: 9,
            startMinute: 0,
            endHour: 17,
            endMinute: 0
        )
        schedule.isEnabled = false

        let isActive = isScheduleActive(
            schedule: schedule,
            currentWeekday: 2,
            currentHour: 10,
            currentMinute: 0
        )

        XCTAssertFalse(isActive)
    }

    func testScheduleAtExactStartTime() {
        let schedule = createSchedule(
            days: [.monday],
            startHour: 9,
            startMinute: 30,
            endHour: 17,
            endMinute: 0
        )

        let isActive = isScheduleActive(
            schedule: schedule,
            currentWeekday: 2,
            currentHour: 9,
            currentMinute: 30
        )

        XCTAssertTrue(isActive)
    }

    func testScheduleJustBeforeEndTime() {
        let schedule = createSchedule(
            days: [.monday],
            startHour: 9,
            startMinute: 0,
            endHour: 17,
            endMinute: 0
        )

        let isActive = isScheduleActive(
            schedule: schedule,
            currentWeekday: 2,
            currentHour: 16,
            currentMinute: 59
        )

        XCTAssertTrue(isActive)
    }

    func testScheduleAtExactEndTime() {
        let schedule = createSchedule(
            days: [.monday],
            startHour: 9,
            startMinute: 0,
            endHour: 17,
            endMinute: 0
        )

        // At exactly end time, should NOT be active (end is exclusive)
        let isActive = isScheduleActive(
            schedule: schedule,
            currentWeekday: 2,
            currentHour: 17,
            currentMinute: 0
        )

        XCTAssertFalse(isActive)
    }

    func testWeekendSchedule() {
        let schedule = createSchedule(
            days: [.saturday, .sunday],
            startHour: 10,
            startMinute: 0,
            endHour: 22,
            endMinute: 0
        )

        // Saturday at 3:00 PM
        let saturdayActive = isScheduleActive(
            schedule: schedule,
            currentWeekday: 7, // Saturday
            currentHour: 15,
            currentMinute: 0
        )
        XCTAssertTrue(saturdayActive)

        // Sunday at 3:00 PM
        let sundayActive = isScheduleActive(
            schedule: schedule,
            currentWeekday: 1, // Sunday
            currentHour: 15,
            currentMinute: 0
        )
        XCTAssertTrue(sundayActive)

        // Monday at 3:00 PM
        let mondayActive = isScheduleActive(
            schedule: schedule,
            currentWeekday: 2, // Monday
            currentHour: 15,
            currentMinute: 0
        )
        XCTAssertFalse(mondayActive)
    }

    // MARK: - Multiple Schedules Tests

    func testAnyMatchingScheduleActivates() {
        let schedules = [
            createSchedule(days: [.monday], startHour: 9, startMinute: 0, endHour: 12, endMinute: 0),
            createSchedule(days: [.monday], startHour: 13, startMinute: 0, endHour: 17, endMinute: 0),
        ]

        // Morning slot
        let morningActive = anyScheduleActive(
            schedules: schedules,
            currentWeekday: 2,
            currentHour: 10,
            currentMinute: 0
        )
        XCTAssertTrue(morningActive)

        // Afternoon slot
        let afternoonActive = anyScheduleActive(
            schedules: schedules,
            currentWeekday: 2,
            currentHour: 15,
            currentMinute: 0
        )
        XCTAssertTrue(afternoonActive)

        // Lunch gap
        let lunchActive = anyScheduleActive(
            schedules: schedules,
            currentWeekday: 2,
            currentHour: 12,
            currentMinute: 30
        )
        XCTAssertFalse(lunchActive)
    }

    // MARK: - Helpers

    private func createSchedule(
        days: Set<ScheduleEntry.Weekday>,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int
    ) -> ScheduleEntry {
        var schedule = ScheduleEntry()
        schedule.days = days
        schedule.startTime = Calendar.current.date(from: DateComponents(hour: startHour, minute: startMinute)) ?? Date()
        schedule.endTime = Calendar.current.date(from: DateComponents(hour: endHour, minute: endMinute)) ?? Date()
        return schedule
    }

    /// Simulates AutomationManager schedule checking logic
    private func isScheduleActive(
        schedule: ScheduleEntry,
        currentWeekday: Int,
        currentHour: Int,
        currentMinute: Int
    ) -> Bool {
        guard schedule.isEnabled else { return false }

        guard let weekday = ScheduleEntry.Weekday(rawValue: currentWeekday),
              schedule.days.contains(weekday) else { return false }

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: schedule.endTime)

        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)

        return currentMinutes >= startMinutes && currentMinutes < endMinutes
    }

    private func anyScheduleActive(
        schedules: [ScheduleEntry],
        currentWeekday: Int,
        currentHour: Int,
        currentMinute: Int
    ) -> Bool {
        schedules.contains { schedule in
            isScheduleActive(
                schedule: schedule,
                currentWeekday: currentWeekday,
                currentHour: currentHour,
                currentMinute: currentMinute
            )
        }
    }
}
