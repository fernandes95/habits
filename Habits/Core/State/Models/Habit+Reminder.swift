//
//  Habit+Reminder.swift
//  Habits
//
//  Created by Tiago Fernandes on 29/10/2026.
//

import Foundation

// MARK: Reminder
extension Habit {
    /// Hours the habit reminds at, sorted by time of day.
    /// Empty while the reminder is off, the hours stay saved so turning it back on brings them back
    var reminderHours: [Hour] {
        guard self.hasAlarm else { return [] }
        return self.schedule.sorted { $0.minutesOfDay < $1.minutesOfDay }
    }
}

extension Hour {
    /// Minutes since midnight, to sort hours by time of day whatever day they were picked on
    var minutesOfDay: Int {
        let time = Calendar.current.dateComponents([.hour, .minute], from: self.date)
        return (time.hour ?? 0) * 60 + (time.minute ?? 0)
    }

    /// This hour on `day`, only the hour and minute of `date` are used
    func date(on day: Date, calendar: Calendar = .current) -> Date? {
        let time = calendar.dateComponents([.hour, .minute], from: self.date)
        return calendar.date(
            bySettingHour: time.hour ?? 0,
            minute: time.minute ?? 0,
            second: 0,
            of: day
        )
    }
}
