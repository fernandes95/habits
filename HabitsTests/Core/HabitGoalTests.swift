//
//  HabitGoalTests.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 28/10/2026.
//

@testable import Habits
import XCTest

/// Habits with a goal are checked once they're done the goal times in a day, whatever their frequency.
internal final class HabitGoalTests: XCTestCase {
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

    // MARK: Counting

    internal func test_weekly_habit_with_goal_is_checked_once_the_goal_is_reached() async throws {
        let habit: Habit = Habit.make(.weekly, hasGoal: true)
        // Weekly test habits repeat on the day after the start date
        let day: Date = habit.startDate.adding(days: 1)
        let habitId: UUID = try await self.sut.addHabit(habit)

        for count in 1..<Habit.testGoal.value {
            let listedHabit: Habit = try await self.tap(habitId, on: day)
            XCTAssertEqual(listedHabit.completedCount, count)
            XCTAssertFalse(listedHabit.isChecked, "Checked before reaching the goal")
        }

        let listedHabit: Habit = try await self.tap(habitId, on: day)
        XCTAssertEqual(listedHabit.completedCount, Habit.testGoal.value)
        XCTAssertTrue(listedHabit.isChecked)
        XCTAssertEqual(listedHabit.dayProgress, 1)
    }

    internal func test_tapping_a_checked_habit_with_goal_starts_counting_again() async throws {
        let habit: Habit = Habit.make(.daily, hasGoal: true)
        let day: Date = habit.startDate
        let habitId: UUID = try await self.sut.addHabit(habit)

        for _ in 0..<Habit.testGoal.value {
            _ = try await self.tap(habitId, on: day)
        }
        let listedHabit: Habit = try await self.tap(habitId, on: day)

        XCTAssertEqual(listedHabit.completedCount, 0)
        XCTAssertFalse(listedHabit.isChecked)
    }

    internal func test_habit_without_goal_is_checked_with_one_tap() async throws {
        let habit: Habit = Habit.make(.weekly)
        let day: Date = habit.startDate.adding(days: 1)
        let habitId: UUID = try await self.sut.addHabit(habit)

        let listedHabit: Habit = try await self.tap(habitId, on: day)

        XCTAssertTrue(listedHabit.isChecked)
    }

    // MARK: Saving

    internal func test_habit_with_goal_is_saved_and_loaded_with_its_goal() throws {
        let habitEntity: HabitEntity = HabitEntity(
            eventId: "",
            name: "Test habit",
            startDate: Habit.testStartDate,
            endDate: Habit.testStartDate.adding(days: 30),
            hasNoEndDate: false,
            frequency: Habit.Frequency.weekly.rawValue,
            frequencyType: Ocurrence(weekFrequency: [.monday]),
            category: Habit.Category.new.rawValue,
            goal: Habit.testGoal
        )

        let data: Data = try JSONEncoder().encode(habitEntity)
        let decoded: HabitEntity = try JSONDecoder().decode(HabitEntity.self, from: data)

        XCTAssertEqual(decoded.frequency, Habit.Frequency.weekly.rawValue)
        XCTAssertEqual(decoded.frequencyType, habitEntity.frequencyType)
        XCTAssertEqual(decoded.goal, Habit.testGoal)
    }

    // MARK: ABSTRACTIONS

    /// Taps the habit status on `day` like the habits list does and returns the habit listed afterwards.
    private func tap(_ habitId: UUID, on day: Date, file: StaticString = #filePath, line: UInt = #line) async throws -> Habit {
        let habit: Habit = try await self.listedHabit(habitId, on: day, file: file, line: line)
        try await self.sut.updateHabit(habit.with(isChecked: !habit.isChecked), selectedDate: day)
        return try await self.listedHabit(habitId, on: day, file: file, line: line)
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
