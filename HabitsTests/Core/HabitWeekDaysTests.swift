//
//  HabitWeekDaysTests.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 28/10/2026.
//

@testable import Habits
import XCTest

/// Week days picked in the habit frequency: every day selected is a daily habit,
/// only some of them is a weekly habit and no day can't be added.
/// A goal is separate and stays when the days change.
internal final class HabitWeekDaysTests: XCTestCase {
    // MARK: Daily

    internal func test_daily_habit_repeats_on_every_week_day() {
        let habit: Habit = Habit.make(.daily)

        XCTAssertEqual(habit.repeatWeekDays, Set(WeekDay.allCases))
    }

    internal func test_skipping_a_day_of_a_daily_habit_makes_it_weekly() {
        var habit: Habit = Habit.make(.daily)

        habit.toggleWeekDay(.sunday)

        XCTAssertEqual(habit.frequency, .weekly)
        XCTAssertEqual(habit.frequencyType.weekFrequency, [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday])
        XCTAssertTrue(habit.isValid)
    }

    // MARK: Goal

    internal func test_skipping_a_day_of_a_habit_with_goal_keeps_the_goal() {
        var habit: Habit = Habit.make(.daily, hasGoal: true)

        habit.toggleWeekDay(.sunday)

        XCTAssertEqual(habit.frequency, .weekly)
        XCTAssertEqual(habit.goal, Habit.testGoal)
        XCTAssertTrue(habit.isValid)
    }

    // MARK: Weekly

    internal func test_weekly_habit_repeats_on_its_week_days() {
        let habit: Habit = Habit.make(.weekly)

        XCTAssertEqual(habit.repeatWeekDays, [Habit.testWeekDay(startDate: habit.startDate)])
    }

    internal func test_selecting_a_day_of_a_weekly_habit_keeps_it_weekly() {
        var habit: Habit = Habit.make(.weekly).withWeekDays([.monday])

        habit.toggleWeekDay(.friday)

        XCTAssertEqual(habit.frequency, .weekly)
        XCTAssertEqual(habit.frequencyType.weekFrequency, [.monday, .friday])
    }

    internal func test_week_days_are_saved_in_week_order() {
        var habit: Habit = Habit.make(.weekly).withWeekDays([.friday])

        habit.toggleWeekDay(.wednesday)
        habit.toggleWeekDay(.monday)

        XCTAssertEqual(habit.frequencyType.weekFrequency, [.monday, .wednesday, .friday])
    }

    internal func test_selecting_every_day_of_a_weekly_habit_makes_it_daily() {
        var habit: Habit = Habit.make(.weekly).withWeekDays([.monday])

        for day in WeekDay.allCases where day != .monday {
            habit.toggleWeekDay(day)
        }

        XCTAssertEqual(habit.frequency, .daily)
        XCTAssertTrue(habit.frequencyType.weekFrequency.isEmpty, "Daily habits are saved without week days")
        XCTAssertTrue(habit.isValid)
    }

    internal func test_skipping_the_last_day_of_a_weekly_habit_makes_it_invalid() {
        var habit: Habit = Habit.make(.weekly).withWeekDays([.monday])

        habit.toggleWeekDay(.monday)

        XCTAssertEqual(habit.frequency, .weekly)
        XCTAssertTrue(habit.repeatWeekDays.isEmpty)
        XCTAssertFalse(habit.isValid, "The add button would be enabled")
    }

    internal func test_skipping_and_selecting_a_day_again_makes_it_daily_again() {
        var habit: Habit = Habit.make(.daily)

        habit.toggleWeekDay(.wednesday)
        habit.toggleWeekDay(.wednesday)

        XCTAssertEqual(habit.frequency, .daily)
        XCTAssertEqual(habit.repeatWeekDays, Set(WeekDay.allCases))
    }
}

private extension Habit {
    func withWeekDays(_ days: [WeekDay]) -> Habit {
        var habit: Habit = self
        habit.frequencyType.weekFrequency = days
        return habit
    }
}
