//
//  HabitAddTests.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 24/10/2026.
//

@testable import Habits
import XCTest

/// Every combination of frequency, schedule, end date and location the add habit form accepts.
internal final class HabitAddTests: XCTestCase {
    private var sut: HabitsService!

    override internal func setUp() async throws {
        try await super.setUp()
        self.sut = HabitsService()
    }

    override internal func tearDown() async throws {
        self.sut = nil
        try await DefaultStoreService().save(
            StoreEntity(habits: [], habitsArchived: [], habitsNotified: [], appConfigs: AppConfig.empty)
        )
        try await super.tearDown()
    }

    // MARK: Daily

    internal func test_add_daily_habit() async throws {
        try await self.assertAdded(Habit.make(.daily))
    }

    internal func test_add_daily_habit_with_schedule() async throws {
        try await self.assertAdded(Habit.make(.daily, hasSchedule: true))
    }

    internal func test_add_daily_habit_with_end_date() async throws {
        try await self.assertAdded(Habit.make(.daily, hasEndDate: true))
    }

    internal func test_add_daily_habit_with_location() async throws {
        try await self.assertAdded(Habit.make(.daily, hasLocation: true))
    }

    internal func test_add_daily_habit_with_schedule_and_end_date() async throws {
        try await self.assertAdded(Habit.make(.daily, hasSchedule: true, hasEndDate: true))
    }

    internal func test_add_daily_habit_with_schedule_and_location() async throws {
        try await self.assertAdded(Habit.make(.daily, hasSchedule: true, hasLocation: true))
    }

    internal func test_add_daily_habit_with_end_date_and_location() async throws {
        try await self.assertAdded(Habit.make(.daily, hasEndDate: true, hasLocation: true))
    }

    internal func test_add_daily_habit_with_schedule_end_date_and_location() async throws {
        try await self.assertAdded(Habit.make(.daily, hasSchedule: true, hasEndDate: true, hasLocation: true))
    }

    // MARK: Weekly

    internal func test_add_weekly_habit() async throws {
        try await self.assertAdded(Habit.make(.weekly))
    }

    internal func test_add_weekly_habit_with_schedule() async throws {
        try await self.assertAdded(Habit.make(.weekly, hasSchedule: true))
    }

    internal func test_add_weekly_habit_with_end_date() async throws {
        try await self.assertAdded(Habit.make(.weekly, hasEndDate: true))
    }

    internal func test_add_weekly_habit_with_location() async throws {
        try await self.assertAdded(Habit.make(.weekly, hasLocation: true))
    }

    internal func test_add_weekly_habit_with_schedule_and_end_date() async throws {
        try await self.assertAdded(Habit.make(.weekly, hasSchedule: true, hasEndDate: true))
    }

    internal func test_add_weekly_habit_with_schedule_and_location() async throws {
        try await self.assertAdded(Habit.make(.weekly, hasSchedule: true, hasLocation: true))
    }

    internal func test_add_weekly_habit_with_end_date_and_location() async throws {
        try await self.assertAdded(Habit.make(.weekly, hasEndDate: true, hasLocation: true))
    }

    internal func test_add_weekly_habit_with_schedule_end_date_and_location() async throws {
        try await self.assertAdded(Habit.make(.weekly, hasSchedule: true, hasEndDate: true, hasLocation: true))
    }

    // MARK: Interval

    internal func test_add_interval_habit() async throws {
        try await self.assertAdded(Habit.make(.interval))
    }

    internal func test_add_interval_habit_with_schedule() async throws {
        try await self.assertAdded(Habit.make(.interval, hasSchedule: true))
    }

    internal func test_add_interval_habit_with_end_date() async throws {
        try await self.assertAdded(Habit.make(.interval, hasEndDate: true))
    }

    internal func test_add_interval_habit_with_location() async throws {
        try await self.assertAdded(Habit.make(.interval, hasLocation: true))
    }

    internal func test_add_interval_habit_with_schedule_and_end_date() async throws {
        try await self.assertAdded(Habit.make(.interval, hasSchedule: true, hasEndDate: true))
    }

    internal func test_add_interval_habit_with_schedule_and_location() async throws {
        try await self.assertAdded(Habit.make(.interval, hasSchedule: true, hasLocation: true))
    }

    internal func test_add_interval_habit_with_end_date_and_location() async throws {
        try await self.assertAdded(Habit.make(.interval, hasEndDate: true, hasLocation: true))
    }

    internal func test_add_interval_habit_with_schedule_end_date_and_location() async throws {
        try await self.assertAdded(Habit.make(.interval, hasSchedule: true, hasEndDate: true, hasLocation: true))
    }

    // MARK: Minimum Days

    internal func test_add_min_days_habit() async throws {
        try await self.assertAdded(Habit.make(.minDays))
    }

    internal func test_add_min_days_habit_with_schedule() async throws {
        try await self.assertAdded(Habit.make(.minDays, hasSchedule: true))
    }

    internal func test_add_min_days_habit_with_end_date() async throws {
        try await self.assertAdded(Habit.make(.minDays, hasEndDate: true))
    }

    internal func test_add_min_days_habit_with_location() async throws {
        try await self.assertAdded(Habit.make(.minDays, hasLocation: true))
    }

    internal func test_add_min_days_habit_with_schedule_and_end_date() async throws {
        try await self.assertAdded(Habit.make(.minDays, hasSchedule: true, hasEndDate: true))
    }

    internal func test_add_min_days_habit_with_schedule_and_location() async throws {
        try await self.assertAdded(Habit.make(.minDays, hasSchedule: true, hasLocation: true))
    }

    internal func test_add_min_days_habit_with_end_date_and_location() async throws {
        try await self.assertAdded(Habit.make(.minDays, hasEndDate: true, hasLocation: true))
    }

    internal func test_add_min_days_habit_with_schedule_end_date_and_location() async throws {
        try await self.assertAdded(Habit.make(.minDays, hasSchedule: true, hasEndDate: true, hasLocation: true))
    }

    // MARK: Minimum Times

    internal func test_add_min_times_habit() async throws {
        try await self.assertAdded(Habit.make(.minTimes))
    }

    internal func test_add_min_times_habit_with_schedule() async throws {
        try await self.assertAdded(Habit.make(.minTimes, hasSchedule: true))
    }

    internal func test_add_min_times_habit_with_end_date() async throws {
        try await self.assertAdded(Habit.make(.minTimes, hasEndDate: true))
    }

    internal func test_add_min_times_habit_with_location() async throws {
        try await self.assertAdded(Habit.make(.minTimes, hasLocation: true))
    }

    internal func test_add_min_times_habit_with_schedule_and_end_date() async throws {
        try await self.assertAdded(Habit.make(.minTimes, hasSchedule: true, hasEndDate: true))
    }

    internal func test_add_min_times_habit_with_schedule_and_location() async throws {
        try await self.assertAdded(Habit.make(.minTimes, hasSchedule: true, hasLocation: true))
    }

    internal func test_add_min_times_habit_with_end_date_and_location() async throws {
        try await self.assertAdded(Habit.make(.minTimes, hasEndDate: true, hasLocation: true))
    }

    internal func test_add_min_times_habit_with_schedule_end_date_and_location() async throws {
        try await self.assertAdded(Habit.make(.minTimes, hasSchedule: true, hasEndDate: true, hasLocation: true))
    }

    // MARK: Limits

    internal func test_add_weekly_habit_with_every_week_day() async throws {
        var habit: Habit = Habit.make(.weekly)
        habit.frequencyType.weekFrequency = WeekDay.allCases

        try await self.assertAdded(habit)
    }

    internal func test_add_interval_habit_with_lowest_interval() async throws {
        var habit: Habit = Habit.make(.interval)
        habit.scheduleInterval = 3

        try await self.assertAdded(habit)
    }

    internal func test_add_min_days_habit_with_lowest_minimum_days() async throws {
        var habit: Habit = Habit.make(.minDays)
        habit.frequencyType.minimumDays = 1

        try await self.assertAdded(habit)
    }

    internal func test_add_min_days_habit_with_highest_minimum_days() async throws {
        var habit: Habit = Habit.make(.minDays)
        habit.frequencyType.minimumDays = 6

        try await self.assertAdded(habit)
    }

    internal func test_add_min_times_habit_with_lowest_minimum_times() async throws {
        var habit: Habit = Habit.make(.minTimes)
        habit.frequencyType.minimumTimes = 3

        try await self.assertAdded(habit)
    }

    internal func test_add_min_times_habit_with_highest_minimum_times() async throws {
        var habit: Habit = Habit.make(.minTimes)
        habit.frequencyType.minimumTimes = 100

        try await self.assertAdded(habit)
    }

    // MARK: ABSTRACTIONS

    /// Checks the add button would be enabled for `habit`, adds it
    /// and checks it's listed on its start date with the same settings.
    private func assertAdded(_ habit: Habit, file: StaticString = #filePath, line: UInt = #line) async throws {
        XCTAssertTrue(habit.isValid, "The add button would be disabled", file: file, line: line)

        let habitId: UUID = try await self.sut.addHabit(habit)
        let day: Date = habit.startDate.startOfDay
        let habitsOfDay: [Habit] = try await self.sut.loadHabits(days: [day])[day] ?? []
        let listedHabit: Habit = try XCTUnwrap(
            habitsOfDay.first(where: { $0.id == habitId }),
            "The habit isn't listed on its start date", file: file, line: line
        )

        XCTAssertEqual(listedHabit.name, habit.name, file: file, line: line)
        XCTAssertEqual(listedHabit.frequency, habit.frequency, file: file, line: line)
        XCTAssertEqual(listedHabit.frequencyType, habit.frequencyType, file: file, line: line)
        XCTAssertEqual(listedHabit.scheduleInterval, habit.scheduleInterval, file: file, line: line)
        XCTAssertEqual(listedHabit.startDate, habit.startDate, file: file, line: line)
        XCTAssertEqual(listedHabit.endDate, habit.endDate, file: file, line: line)
        XCTAssertEqual(listedHabit.hasNoEndDate, habit.hasNoEndDate, file: file, line: line)
        XCTAssertEqual(listedHabit.schedule.map(\.hour), habit.schedule.map(\.hour), file: file, line: line)
        XCTAssertEqual(listedHabit.hasAlarm, habit.hasAlarm, file: file, line: line)
        XCTAssertEqual(listedHabit.location, habit.location, file: file, line: line)
        XCTAssertEqual(listedHabit.hasLocationReminder, habit.hasLocationReminder, file: file, line: line)
    }
}
