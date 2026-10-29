//
//  AppConfig.swift
//  Habits
//
//  Created by Tiago Fernandes on 19/10/2026.
//

import Foundation

struct AppConfig: Codable {
    var startOfWeek: WeekDay
    /// Start of the day the app was installed, or of the oldest habit when it's older.
    /// Nil in data saved before it existed, until `HabitsService.updateInstallDate()` sets it
    var installDate: Date?

    internal func with(
        startOfWeek: WeekDay? = nil,
        installDate: Date? = nil
    ) -> Self {
        return Self(
            startOfWeek: startOfWeek ?? self.startOfWeek,
            installDate: installDate ?? self.installDate
        )
    }

    /// Calendar whose weeks start on the configured `startOfWeek`
    var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = self.startOfWeek.rawValue
        return calendar
    }

    /// First day the user can go back to, today until `installDate` is set
    var earliestDate: Date {
        self.installDate ?? Date.now.startOfDay
    }

    static var empty: Self {
        return AppConfig(
            startOfWeek: WeekDay.sunday
        )
    }
}
