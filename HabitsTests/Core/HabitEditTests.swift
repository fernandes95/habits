//
//  HabitEditTests.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 24/10/2026.
//

@testable import Habits
import XCTest

/// Changes a habit from each frequency to every other one and checks the habits list follows the new frequency.
internal final class HabitEditTests: XCTestCase {
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

    internal func test_edit_daily_habit_to_min_times() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.daily))

        try await self.editHabit(habitId, to: .minTimes)

        try await self.assertListed(habitId, as: .minTimes)
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

    internal func test_edit_weekly_habit_to_min_times() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.weekly))

        try await self.editHabit(habitId, to: .minTimes)

        try await self.assertListed(habitId, as: .minTimes)
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

    internal func test_edit_interval_habit_to_min_times() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.interval))

        try await self.editHabit(habitId, to: .minTimes)

        try await self.assertListed(habitId, as: .minTimes)
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

    internal func test_edit_min_days_habit_to_min_times() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.minDays))

        try await self.editHabit(habitId, to: .minTimes)

        try await self.assertListed(habitId, as: .minTimes)
    }

    // MARK: From Minimum Times

    internal func test_edit_min_times_habit_to_daily() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.minTimes))

        try await self.editHabit(habitId, to: .daily)

        try await self.assertListed(habitId, as: .daily)
    }

    internal func test_edit_min_times_habit_to_weekly() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.minTimes))

        try await self.editHabit(habitId, to: .weekly)

        try await self.assertListed(habitId, as: .weekly)
    }

    internal func test_edit_min_times_habit_to_interval() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.minTimes))

        try await self.editHabit(habitId, to: .interval)

        try await self.assertListed(habitId, as: .interval)
    }

    internal func test_edit_min_times_habit_to_min_days() async throws {
        let habitId: UUID = try await self.sut.addHabit(Habit.make(.minTimes))

        try await self.editHabit(habitId, to: .minDays)

        try await self.assertListed(habitId, as: .minDays)
    }

    // MARK: ABSTRACTIONS

    /// Edits the stored habit like the habit detail screen does, changing only its frequency.
    private func editHabit(
        _ habitId: UUID,
        to frequency: Habit.Frequency,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let storedHabit: HabitEntity? = try await self.sut.getHabit(id: habitId)
        let habitEntity: HabitEntity = try XCTUnwrap(storedHabit, "The habit wasn't added", file: file, line: line)
        let editedHabit: Habit = Habit(habitEntity: habitEntity).changingFrequency(to: frequency)
        XCTAssertTrue(editedHabit.isValid, "The done button would be disabled", file: file, line: line)

        try await self.sut.editHabit(editedHabit)
    }

    /// Checks the habit keeps only the settings of `frequency`
    /// and is listed exactly on the days that frequency allows.
    private func assertListed(
        _ habitId: UUID,
        as frequency: Habit.Frequency,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let startDate: Date = Habit.testStartDate
        let expected: Habit = Habit.make(frequency, startDate: startDate)

        // Days after the start date where the habit must and must not be listed
        let (listedDays, hiddenDays): ([Int], [Int]) = switch frequency {
        case .daily, .minDays, .minTimes: ([0, 1, 2], [])
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
