//
//  WeekDay.swift
//  Habits
//
//  Created by Tiago Fernandes on 18/03/2024.
//

import Foundation
import EventKit

enum WeekDay: Int, Identifiable, CaseIterable, Codable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    init(date: Date, calendar: Calendar = .current) {
        self = WeekDay(rawValue: calendar.component(.weekday, from: date)) ?? .sunday
    }

    var ekWeekday: EKWeekday { EKWeekday(rawValue: rawValue) ?? .sunday }

    /// Weekday name in the language of `locale`, pass the app's locale so it follows the language setting
    func localizedName(locale: Locale = .current) -> String {
        var calendar = Calendar.current
        calendar.locale = locale
        return calendar.standaloneWeekdaySymbols[rawValue - 1].capitalized
    }
}
