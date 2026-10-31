//
//  HabitEditTests.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 24/10/2026.
//

@testable import Habits
import XCTest

/// Changes a habit from each frequency to every other one and checks the habits list follows the new frequency.
/// Goals are edited on their own and stay when the frequency changes.
internal final class HabitEditTests: XCTestCase {
    private var sut: HabitsService!

    override internal func setUp() async throws {
        try await super.setUp()
        self.sut = HabitsService(storeService: .tests())
    }

    override internal func tearDown() async throws {
        self.sut = nil
        try await DefaultStoreService.tests().save(
            StoreEntity(habits: [], habitsArchived: [], habitsNotified: [], appConfigs: AppConfig.empty)
        )
        try await super.tearDown()
    }

    // MARK: From Daily

    internal func test_edit_daily_habit_to_weekly() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.daily))

        try await self.editHabit(habitId, to: .weekly)

        try await self.assertListed(habitId, as: .weekly)
    }

    internal func test_edit_daily_habit_to_interval() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.daily))

        try await self.editHabit(habitId, to: .interval)

        try await self.assertListed(habitId, as: .interval)
    }

    internal func test_edit_daily_habit_to_min_days() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.daily))

        try await self.editHabit(habitId, to: .minDays)

        try await self.assertListed(habitId, as: .minDays)
    }

    // MARK: From Weekly

    internal func test_edit_weekly_habit_to_daily() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.weekly))

        try await self.editHabit(habitId, to: .daily)

        try await self.assertListed(habitId, as: .daily)
    }

    internal func test_edit_weekly_habit_to_interval() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.weekly))

        try await self.editHabit(habitId, to: .interval)

        try await self.assertListed(habitId, as: .interval)
    }

    internal func test_edit_weekly_habit_to_min_days() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.weekly))

        try await self.editHabit(habitId, to: .minDays)

        try await self.assertListed(habitId, as: .minDays)
    }

    // MARK: From Interval

    internal func test_edit_interval_habit_to_daily() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.interval))

        try await self.editHabit(habitId, to: .daily)

        try await self.assertListed(habitId, as: .daily)
    }

    internal func test_edit_interval_habit_to_weekly() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.interval))

        try await self.editHabit(habitId, to: .weekly)

        try await self.assertListed(habitId, as: .weekly)
    }

    internal func test_edit_interval_habit_to_min_days() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.interval))

        try await self.editHabit(habitId, to: .minDays)

        try await self.assertListed(habitId, as: .minDays)
    }

    // MARK: From Minimum Days

    internal func test_edit_min_days_habit_to_daily() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.minDays))

        try await self.editHabit(habitId, to: .daily)

        try await self.assertListed(habitId, as: .daily)
    }

    internal func test_edit_min_days_habit_to_weekly() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.minDays))

        try await self.editHabit(habitId, to: .weekly)

        try await self.assertListed(habitId, as: .weekly)
    }

    internal func test_edit_min_days_habit_to_interval() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.minDays))

        try await self.editHabit(habitId, to: .interval)

        try await self.assertListed(habitId, as: .interval)
    }

    // MARK: Goal

    internal func test_add_goal_to_weekly_habit_keeps_its_week_days() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.weekly))

        try await self.editHabit(habitId) { $0.goal = Habit.testGoal }

        try await self.assertListed(habitId, as: .weekly, goal: Habit.testGoal)
    }

    internal func test_remove_goal_from_daily_habit() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.daily, hasGoal: true))

        try await self.editHabit(habitId) { $0.goal = nil }

        try await self.assertListed(habitId, as: .daily, goal: nil)
    }

    internal func test_change_goal_value() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.daily, hasGoal: true))

        try await self.editHabit(habitId) { $0.goal?.value = 8 }

        try await self.assertListed(habitId, as: .daily, goal: Goal(type: .times, value: 8))
    }

    internal func test_edit_frequency_of_habit_with_goal_keeps_the_goal() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.daily, hasGoal: true))

        try await self.editHabit(habitId, to: .interval)

        try await self.assertListed(habitId, as: .interval, goal: Habit.testGoal)
    }

    // MARK: Reminder

    /// Reminders and day statuses are tied to the hour id, editing the habit must not change it
    internal func test_edit_habit_keeps_the_reminder_hour_ids() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.daily, hasSchedule: true))
        let storedAddedHabit: HabitEntity? = try await self.sut.getHabit(id: habitId)
        let addedHabit: HabitEntity = try XCTUnwrap(storedAddedHabit)

        try await self.editHabit(habitId) { $0.name = "Renamed" }

        let storedEditedHabit: HabitEntity? = try await self.sut.getHabit(id: habitId)
        let editedHabit: HabitEntity = try XCTUnwrap(storedEditedHabit)
        XCTAssertEqual(editedHabit.schedule.map(\.id), addedHabit.schedule.map(\.id))
    }

    internal func test_turn_reminder_off_keeps_the_hours() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.daily, hasSchedule: true))

        try await self.editHabit(habitId) { $0.hasAlarm = false }

        let storedEditedHabit: HabitEntity? = try await self.sut.getHabit(id: habitId)
        let editedHabit: HabitEntity = try XCTUnwrap(storedEditedHabit)
        XCTAssertFalse(editedHabit.hasAlarm)
        XCTAssertEqual(editedHabit.schedule.count, 2)
    }

        // MARK: ABSTRACTIONS

    /// Edits the stored habit like the habit detail screen does, changing only its frequency.
    private func editHabit(
        _ habitId: UUID,
        to frequency: Habit.Frequency,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        try await self.editHabit(habitId, file: file, line: line) { $0 = $0.changingFrequency(to: frequency) }
    }

    /// Edits the stored habit like the habit detail screen does, with the changes made by `change`.
    private func editHabit(
        _ habitId: UUID,
        file: StaticString = #filePath,
        line: UInt = #line,
        change: (inout Habit) -> Void
    ) async throws {
        let storedHabit: HabitEntity? = try await self.sut.getHabit(id: habitId)
        let habitEntity: HabitEntity = try XCTUnwrap(storedHabit, "The habit wasn't added", file: file, line: line)
        var editedHabit: Habit = Habit(habitEntity: habitEntity)
        change(&editedHabit)
        XCTAssertTrue(editedHabit.isValid, "The done button would be disabled", file: file, line: line)

        try await self.sut.editHabit(editedHabit)
    }

    /// Checks the habit keeps only the settings of `frequency`, has `goal`
    /// and is listed exactly on the days that frequency allows.
    private func assertListed(
        _ habitId: UUID,
        as frequency: Habit.Frequency,
        goal: Goal? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let startDate: Date = Habit.testStartDate
        let expected: Habit = Habit.make(frequency, startDate: startDate)

        // Days after the start date where the habit must and must not be listed
        let (listedDays, hiddenDays): ([Int], [Int]) = switch frequency {
        case .daily, .minDays: ([0, 1, 2], [])
        // Picked week day is the day after the start date
        case .weekly: ([1], [2])
        case .interval: ([0, Habit.testInterval], Array(1..<Habit.testInterval))
        }

        let days: [Date] = (listedDays + hiddenDays).map { startDate.adding(days: $0) }
        let habitsByDay: [Date: [Habit]] = try await self.sut.loadHabits(days: days)

        for offset in listedDays {
            let day: Date = startDate.adding(days: offset)
            let listedHabit: Habit = try XCTUnwrap(
                habitsByDay[day]?.first(where: { $0.id == habitId }),
                "The habit isn't listed \(offset) day(s) after the start date", file: file, line: line
            )

            XCTAssertEqual(listedHabit.frequency, frequency, file: file, line: line)
            XCTAssertEqual(listedHabit.frequencyType, expected.frequencyType, file: file, line: line)
            XCTAssertEqual(listedHabit.scheduleInterval, expected.scheduleInterval, file: file, line: line)
            XCTAssertEqual(listedHabit.goal, goal, file: file, line: line)
        }

        for offset in hiddenDays {
            let day: Date = startDate.adding(days: offset)
            XCTAssertNil(
                habitsByDay[day]?.first(where: { $0.id == habitId }),
                "The habit is listed \(offset) day(s) after the start date", file: file, line: line
            )
        }
    }
}
