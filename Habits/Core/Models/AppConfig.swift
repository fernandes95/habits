//
//  AppConfig.swift
//  Habits
//
//  Created by Tiago Fernandes on 19/10/2026.
//

import Foundation

struct AppConfig: Codable {
    var startOfWeek: WeekDay

    internal func with(
        startOfWeek: WeekDay? = nil
    ) -> Self {
        return Self(
            startOfWeek: startOfWeek ?? self.startOfWeek
        )
    }

    /// Calendar whose weeks start on the configured `startOfWeek`
    var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = self.startOfWeek.rawValue
        return calendar
    }

    static var empty: Self {
        return AppConfig(
            startOfWeek: WeekDay.sunday
        )
    }
}
