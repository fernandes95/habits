//
//  Habit+TestFactory.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 24/10/2026.
//

@testable import Habits
import Foundation
import MapKit

/// Builds habits the way the add and edit habit forms fill them, with valid values by default.
extension Habit {
    static let testInterval: Int = 3
    static let testMinimumDays: Int = 3
    static let testGoal: Goal = Goal(type: .times, value: 5)

    /// Day every test habit starts on.
    static var testStartDate: Date {
        Date.now.startOfDay
    }

    static var testLocation: Habit.Location {
        Habit.Location(
            latitude: 38.722252,
            longitude: -9.139337,
            region: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 38.722252, longitude: -9.139337),
                latitudinalMeters: 3000,
                longitudinalMeters: 3000
            )
        )
    }

    /// Day picked for weekly habits, the day after `startDate`.
    static func testWeekDay(startDate: Date) -> WeekDay {
        WeekDay(date: startDate.adding(days: 1))
    }

    static func testHour(_ hour: Int, on date: Date) -> Hour {
        Hour(eventId: "", date: Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date)!)
    }

    /// - Parameters:
    ///   - frequency: Frequency of the habit, filled with a valid value
    ///   - hasSchedule: Adds two schedule hours, 09:00 and 10:00
    ///   - hasEndDate: Ends 30 days after the start date, otherwise it has no end date
    ///   - hasLocation: Adds a location with the location reminder on
    ///   - hasGoal: Adds `testGoal`, done 5 times a day
    static func make(
        _ frequency: Frequency,
        name: String = "Test habit",
        startDate: Date = Habit.testStartDate,
        hasSchedule: Bool = false,
        hasEndDate: Bool = false,
        hasLocation: Bool = false,
        hasGoal: Bool = false
    ) -> Habit {
        let endDate: Date = hasEndDate
            ? startDate.adding(days: 30)
            : Calendar.current.date(byAdding: .year, value: 100, to: startDate)!

        var habit: Habit = Habit.empty.with(
            name: name,
            startDate: startDate,
            endDate: endDate,
            hasNoEndDate: !hasEndDate
        )
        habit.applyValidSettings(for: frequency)

        if hasSchedule {
            habit.schedule = [Self.testHour(9, on: startDate), Self.testHour(10, on: startDate)]
            habit.hasAlarm = true
        }

        if hasLocation {
            habit.location = Self.testLocation
            habit.hasLocationReminder = true
        }

        if hasGoal {
            habit.goal = Self.testGoal
        }

        return habit
    }

    /// Changes the frequency like `HabitFrequencyView` does: the values of the other
    /// frequencies are cleared and the new one is filled with a valid value.
    /// Daily and weekly come from the picked week days, every day or only `testWeekDay`.
    /// The goal is kept, it's separate from the frequency.
    func changingFrequency(to frequency: Frequency) -> Habit {
        var habit: Habit = self
        habit.applyValidSettings(for: frequency)
        return habit
    }

    private mutating func applyValidSettings(for frequency: Frequency) {
        self.frequency = frequency
        self.frequencyType = Ocurrence()
        self.scheduleInterval = nil

        switch frequency {
        case .daily: break
        case .weekly: self.frequencyType.weekFrequency = [Self.testWeekDay(startDate: self.startDate)]
        case .interval: self.scheduleInterval = Self.testInterval
        case .minDays: self.frequencyType.minimumDays = Self.testMinimumDays
        }
    }
}

extension Date {
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }
}
