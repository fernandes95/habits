//
//  HabitValidationTests.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 24/10/2026.
//

@testable import Habits
import XCTest

/// Habits the add and edit habit forms must refuse, each one with a single invalid field.
internal final class HabitValidationTests: XCTestCase {
    // MARK: Daily

    internal func test_daily_habit_with_empty_name_is_invalid() {
        self.assertInvalid(.daily) { $0.name = "" }
    }

    internal func test_daily_habit_with_blank_name_is_invalid() {
        self.assertInvalid(.daily) { $0.name = "   " }
    }

    internal func test_daily_habit_with_duplicated_schedule_hours_is_invalid() {
        self.assertInvalid(.daily) { $0.schedule.append(Habit.testHour(9, on: $0.startDate)) }
    }

    // MARK: Weekly

    internal func test_weekly_habit_with_empty_name_is_invalid() {
        self.assertInvalid(.weekly) { $0.name = "" }
    }

    internal func test_weekly_habit_with_blank_name_is_invalid() {
        self.assertInvalid(.weekly) { $0.name = "   " }
    }

    internal func test_weekly_habit_with_duplicated_schedule_hours_is_invalid() {
        self.assertInvalid(.weekly) { $0.schedule.append(Habit.testHour(9, on: $0.startDate)) }
    }

    internal func test_weekly_habit_without_week_days_is_invalid() {
        self.assertInvalid(.weekly) { $0.frequencyType.weekFrequency = [] }
    }

    // MARK: Interval

    internal func test_interval_habit_with_empty_name_is_invalid() {
        self.assertInvalid(.interval) { $0.name = "" }
    }

    internal func test_interval_habit_with_blank_name_is_invalid() {
        self.assertInvalid(.interval) { $0.name = "   " }
    }

    internal func test_interval_habit_with_duplicated_schedule_hours_is_invalid() {
        self.assertInvalid(.interval) { $0.schedule.append(Habit.testHour(9, on: $0.startDate)) }
    }

    internal func test_interval_habit_without_interval_is_invalid() {
        self.assertInvalid(.interval) { $0.scheduleInterval = nil }
    }

    internal func test_interval_habit_with_zero_interval_is_invalid() {
        self.assertInvalid(.interval) { $0.scheduleInterval = 0 }
    }

    internal func test_interval_habit_with_interval_of_two_is_invalid() {
        self.assertInvalid(.interval) { $0.scheduleInterval = 2 }
    }

    // MARK: Minimum Days

    internal func test_min_days_habit_with_empty_name_is_invalid() {
        self.assertInvalid(.minDays) { $0.name = "" }
    }

    internal func test_min_days_habit_with_blank_name_is_invalid() {
        self.assertInvalid(.minDays) { $0.name = "   " }
    }

    internal func test_min_days_habit_with_duplicated_schedule_hours_is_invalid() {
        self.assertInvalid(.minDays) { $0.schedule.append(Habit.testHour(9, on: $0.startDate)) }
    }

    internal func test_min_days_habit_with_zero_minimum_days_is_invalid() {
        self.assertInvalid(.minDays) { $0.frequencyType.minimumDays = 0 }
    }

    internal func test_min_days_habit_with_seven_minimum_days_is_invalid() {
        self.assertInvalid(.minDays) { $0.frequencyType.minimumDays = 7 }
    }

    // MARK: Goal

    internal func test_habit_with_zero_goal_is_invalid() {
        self.assertInvalid(.daily) { $0.goal = Goal(type: .times, value: 0) }
    }

    internal func test_habit_with_goal_of_one_is_invalid() {
        self.assertInvalid(.daily) { $0.goal = Goal(type: .times, value: 1) }
    }

    internal func test_habit_with_goal_of_101_is_invalid() {
        self.assertInvalid(.daily) { $0.goal = Goal(type: .times, value: 101) }
    }

    internal func test_weekly_habit_with_invalid_goal_is_invalid() {
        self.assertInvalid(.weekly) { $0.goal = Goal(type: .times, value: 1) }
    }

    // MARK: Reminder

    /// Hours kept while the reminder is off are hidden, the user couldn't fix them
    internal func test_habit_with_duplicated_hours_and_reminder_off_is_valid() {
        var habit: Habit = Habit.make(.daily, hasSchedule: true)
        habit.schedule.append(Habit.testHour(9, on: habit.startDate))
        habit.hasAlarm = false

        XCTAssertTrue(habit.isValid)
    }

    internal func test_reminder_hours_are_empty_with_reminder_off() {
        var habit: Habit = Habit.make(.daily, hasSchedule: true)
        habit.hasAlarm = false

        XCTAssertTrue(habit.reminderHours.isEmpty)
        XCTAssertEqual(habit.schedule.count, 2, "The hours stay saved for when the reminder is back on")
    }

    internal func test_reminder_hours_are_sorted_by_time_of_day() {
        var habit: Habit = Habit.make(.daily, hasSchedule: true)
        habit.schedule.insert(Habit.testHour(21, on: habit.startDate.adding(days: -3)), at: 0)

        XCTAssertEqual(habit.reminderHours.map(\.minutesOfDay), [9 * 60, 10 * 60, 21 * 60])
    }

        // MARK: ABSTRACTIONS

    /// Starts from a valid habit with a schedule, an end date and a location,
    /// breaks one field with `breakField` and checks the habit can't be added.
    private func assertInvalid(
        _ frequency: Habit.Frequency,
        file: StaticString = #filePath,
        line: UInt = #line,
        breakField: (inout Habit) -> Void
    ) {
        var habit: Habit = Habit.make(frequency, hasSchedule: true, hasEndDate: true, hasLocation: true)
        XCTAssertTrue(habit.isValid, "The habit must be valid before breaking the field", file: file, line: line)

        breakField(&habit)

        XCTAssertFalse(habit.isValid, "The add button would be enabled", file: file, line: line)
    }
}
