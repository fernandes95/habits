//
//  HabitHoursTests.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 30/10/2026.
//

@testable import Habits
import XCTest

/// Habits with reminder hours are done one hour at a time, the habit is checked once every hour is done.
internal final class HabitHoursTests: XCTestCase {
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

    // MARK: Hour states

    internal func test_first_hour_is_selected_before_any_hour_passes() {
        let habit: Habit = self.makeHabit(hours: [9, 13, 19])
        let states = self.states(of: habit, at: 8)

        XCTAssertEqual(states, [.selected, .upcoming, .upcoming])
    }

    internal func test_hour_is_missed_once_the_next_hour_arrives() {
        let habit: Habit = self.makeHabit(hours: [9, 13, 19])

        XCTAssertEqual(self.states(of: habit, at: 12), [.selected, .upcoming, .upcoming], "Missed before the next hour")
        XCTAssertEqual(self.states(of: habit, at: 14), [.missed, .selected, .upcoming])
    }

    internal func test_last_hour_is_missed_an_hour_after_its_time() {
        let habit: Habit = self.makeHabit(hours: [9, 13])

        XCTAssertEqual(self.states(of: habit, at: 13, minute: 59), [.missed, .selected])
        XCTAssertEqual(self.states(of: habit, at: 14), [.missed, .missed])
    }

    internal func test_done_hours_skip_to_the_next_one() {
        var habit: Habit = self.makeHabit(hours: [9, 13, 19])
        habit.checkedHours[habit.reminderHours[0].id] = .now

        XCTAssertEqual(self.states(of: habit, at: 8), [.done, .selected, .upcoming])
    }

    internal func test_picked_missed_hour_is_selected_instead_of_the_next_one() {
        let habit: Habit = self.makeHabit(hours: [9, 13, 19])
        let missedHourId: UUID = habit.reminderHours[0].id

        let states = self.states(of: habit, at: 14, selectedHourId: missedHourId)

        XCTAssertEqual(states, [.selected, .upcoming, .upcoming])
    }

    internal func test_picking_an_hour_that_isnt_missed_changes_nothing() {
        let habit: Habit = self.makeHabit(hours: [9, 13, 19])
        let upcomingHourId: UUID = habit.reminderHours[2].id

        let states = self.states(of: habit, at: 14, selectedHourId: upcomingHourId)

        XCTAssertEqual(states, [.missed, .selected, .upcoming])
    }

    internal func test_habit_without_reminder_has_no_hours() {
        var habit: Habit = self.makeHabit(hours: [9, 13])
        habit.hasAlarm = false

        XCTAssertTrue(self.states(of: habit, at: 8).isEmpty)
    }

    // MARK: Doing hours

    internal func test_habit_without_goal_is_checked_once_every_hour_is_done() async throws {
        let habit: Habit = Habit.make(.daily, hasSchedule: true)
        let day: Date = habit.startDate
        let habitId: UUID = try await self.sut.addHabit(habit)
        let hours: [Hour] = try await self.listedHabit(habitId, on: day).reminderHours

        var listedHabit: Habit = try await self.toggle(habitId, hour: hours[0], on: day)
        XCTAssertFalse(listedHabit.isChecked, "Checked with an hour still to do")
        XCTAssertNotNil(listedHabit.checkedHours[hours[0].id])
        XCTAssertEqual(listedHabit.dayProgress, 0.5)

        listedHabit = try await self.toggle(habitId, hour: hours[1], on: day)
        XCTAssertTrue(listedHabit.isChecked)
        XCTAssertEqual(listedHabit.dayProgress, 1)
    }

    internal func test_undoing_an_hour_unchecks_the_habit() async throws {
        let habit: Habit = Habit.make(.daily, hasSchedule: true)
        let day: Date = habit.startDate
        let habitId: UUID = try await self.sut.addHabit(habit)
        let hours: [Hour] = try await self.listedHabit(habitId, on: day).reminderHours
        _ = try await self.toggle(habitId, hour: hours[0], on: day)
        _ = try await self.toggle(habitId, hour: hours[1], on: day)

        let listedHabit: Habit = try await self.toggle(habitId, hour: hours[0], on: day)

        XCTAssertFalse(listedHabit.isChecked)
        XCTAssertNil(listedHabit.checkedHours[hours[0].id])
        XCTAssertNotNil(listedHabit.checkedHours[hours[1].id], "The other hour was undone too")
    }

    internal func test_hour_with_goal_is_done_once_the_goal_is_reached_and_steps_start_again() async throws {
        let habit: Habit = Habit.make(.daily, hasSchedule: true, hasGoal: true)
        let day: Date = habit.startDate
        let habitId: UUID = try await self.sut.addHabit(habit)
        let hours: [Hour] = try await self.listedHabit(habitId, on: day).reminderHours

        var listedHabit: Habit = try await self.listedHabit(habitId, on: day)
        for step in 1..<Habit.testGoal.value {
            listedHabit = try await self.toggle(habitId, hour: hours[0], on: day)
            XCTAssertEqual(listedHabit.completedCount, step)
            XCTAssertNil(listedHabit.checkedHours[hours[0].id], "Hour done before reaching the goal")
        }

        listedHabit = try await self.toggle(habitId, hour: hours[0], on: day)
        XCTAssertNotNil(listedHabit.checkedHours[hours[0].id])
        XCTAssertEqual(listedHabit.completedCount, 0, "Steps didn't start again for the next hour")
        XCTAssertFalse(listedHabit.isChecked)

        for _ in 0..<Habit.testGoal.value {
            listedHabit = try await self.toggle(habitId, hour: hours[1], on: day)
        }
        XCTAssertTrue(listedHabit.isChecked)
        XCTAssertEqual(listedHabit.completedCount, Habit.testGoal.value, "The last hour lost its steps")
    }

    internal func test_goal_progress_counts_the_steps_of_every_hour() async throws {
        let habit: Habit = Habit.make(.daily, hasSchedule: true, hasGoal: true)
        let day: Date = habit.startDate
        let habitId: UUID = try await self.sut.addHabit(habit)
        let hours: [Hour] = try await self.listedHabit(habitId, on: day).reminderHours
        let total: Int = Habit.testGoal.value * hours.count

        var listedHabit: Habit = try await self.listedHabit(habitId, on: day)
        XCTAssertEqual(listedHabit.hoursGoalProgress?.completed, 0)
        XCTAssertEqual(listedHabit.hoursGoalProgress?.total, total)

        for _ in 0..<Habit.testGoal.value {
            listedHabit = try await self.toggle(habitId, hour: hours[0], on: day)
        }
        listedHabit = try await self.toggle(habitId, hour: hours[1], on: day)
        XCTAssertEqual(listedHabit.hoursGoalProgress?.completed, Habit.testGoal.value + 1)

        for _ in 1..<Habit.testGoal.value {
            listedHabit = try await self.toggle(habitId, hour: hours[1], on: day)
        }
        XCTAssertTrue(listedHabit.isChecked)
        XCTAssertEqual(listedHabit.hoursGoalProgress?.completed, total, "Counted the last hour twice")
    }

    internal func test_undoing_the_last_step_of_a_done_habit_undoes_its_last_hour() async throws {
        let habit: Habit = Habit.make(.daily, hasSchedule: true, hasGoal: true)
        let day: Date = habit.startDate
        let habitId: UUID = try await self.sut.addHabit(habit)
        let hours: [Hour] = try await self.listedHabit(habitId, on: day).reminderHours
        var doneHabit: Habit = try await self.listedHabit(habitId, on: day)
        for hour in hours {
            for _ in 0..<Habit.testGoal.value {
                doneHabit = try await self.toggle(habitId, hour: hour, on: day)
            }
        }

        try await self.sut.undoLastStep(doneHabit, selectedDate: day)
        let listedHabit: Habit = try await self.listedHabit(habitId, on: day)

        XCTAssertFalse(listedHabit.isChecked)
        XCTAssertEqual(listedHabit.completedCount, Habit.testGoal.value - 1)
        XCTAssertNotNil(listedHabit.checkedHours[hours[0].id])
        XCTAssertNil(listedHabit.checkedHours[hours[1].id], "The last hour is still done")
    }

    internal func test_day_with_hours_shows_the_hours_done_in_history() async throws {
        let habit: Habit = Habit.make(.daily, hasSchedule: true)
        let day: Date = habit.startDate
        let habitId: UUID = try await self.sut.addHabit(habit)
        let hours: [Hour] = try await self.listedHabit(habitId, on: day).reminderHours

        let listedHabit: Habit = try await self.toggle(habitId, hour: hours[0], on: day)
        let record: Habit.DayRecord = try XCTUnwrap(listedHabit.history.first)

        XCTAssertEqual(record.count, 1)
        XCTAssertEqual(record.requiredCount, 2)
        XCTAssertFalse(record.isChecked)
    }

    // MARK: ABSTRACTIONS

    private func makeHabit(hours: [Int]) -> Habit {
        var habit: Habit = Habit.make(.daily)
        habit.schedule = hours.map { Habit.testHour($0, on: habit.startDate) }
        habit.hasAlarm = true
        return habit
    }

    private func states(of habit: Habit, at hour: Int, minute: Int = 0, selectedHourId: UUID? = nil) -> [Habit.HourState] {
        let day: Date = habit.startDate
        let now: Date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
        return habit.hourChips(on: day, now: now, selectedHourId: selectedHourId).map(\.state)
    }

    /// Does or undoes `hour` on `day` like the habits list does and returns the habit listed afterwards
    private func toggle(_ habitId: UUID, hour: Hour, on day: Date) async throws -> Habit {
        let habit: Habit = try await self.listedHabit(habitId, on: day)
        try await self.sut.toggleHour(habit, hourId: hour.id, selectedDate: day)
        return try await self.listedHabit(habitId, on: day)
    }

    private func listedHabit(
        _ habitId: UUID,
        on day: Date,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> Habit {
        let habitsByDay: [Date: [Habit]] = try await self.sut.loadHabits(days: [day])
        return try XCTUnwrap(
            habitsByDay[day.startOfDay]?.first(where: { $0.id == habitId }),
            "The habit isn't listed", file: file, line: line
        )
    }
}
