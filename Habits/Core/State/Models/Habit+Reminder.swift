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

    /// Steps done on the loaded date across every reminder hour, out of the steps the whole day expects.
    /// With a goal of 5 and three hours the day expects 15. Nil without a goal or reminder hours
    var hoursGoalProgress: (completed: Int, total: Int)? {
        let hours = self.reminderHours
        guard let goal = self.goal, goal.value > 0, !hours.isEmpty else { return nil }

        let total: Int = goal.value * hours.count
        // The last hour keeps its steps once the day is done, they're already in the done hours
        guard !self.isChecked else { return (total, total) }

        let doneHours: Int = hours.filter { self.checkedHours[$0.id] != nil }.count
        return (min(doneHours * goal.value + self.completedCount, total), total)
    }

    /// Last reminder hour done on the loaded date, the last hour when the day was checked before hours could be
    var lastCheckedHourId: UUID? {
        if let last = self.checkedHours.max(by: { $0.value < $1.value }) { return last.key }
        return self.isChecked ? self.reminderHours.last?.id : nil
    }
}

// MARK: Hour states
extension Habit {
    enum HourState: Equatable {
        /// Done, or the whole day was checked
        case done
        /// Not done and the next hour already arrived, the last hour an hour after its time
        case missed
        /// The hour a tap on the checkbox goes to
        case selected
        /// Still to come after the selected hour
        case upcoming
    }

    struct HourChip: Identifiable, Equatable {
        let hour: Hour
        let state: HourState

        var id: UUID { self.hour.id }
    }

    /// One chip for each reminder hour of `day`, in time order.
    /// The selected hour is the first one neither done nor missed, or `selectedHourId` when that one is missed,
    /// a missed hour can still be done by selecting it.
    ///
    /// - Parameters:
    ///   - day: Day the habit was loaded for
    ///   - now: Current date, hours turn missed by it
    ///   - selectedHourId: Missed hour the user picked to do now
    func hourChips(
        on day: Date,
        now: Date = .now,
        selectedHourId: UUID? = nil,
        calendar: Calendar = .current
    ) -> [HourChip] {
        let hours = self.reminderHours
        let dates: [Date] = hours.map { $0.date(on: day, calendar: calendar) ?? day }

        var states: [HourState] = hours.indices.map { index in
            if self.isChecked || self.checkedHours[hours[index].id] != nil { return .done }

            let missedDate: Date = index + 1 < dates.count
                ? dates[index + 1]
                : calendar.date(byAdding: .hour, value: 1, to: dates[index]) ?? dates[index]
            return now >= missedDate ? .missed : .upcoming
        }

        if let selectedHourId,
           let index = hours.firstIndex(where: { $0.id == selectedHourId }),
           states[index] == .missed {
            states[index] = .selected
        } else if let index = states.firstIndex(of: .upcoming) {
            states[index] = .selected
        }

        return zip(hours, states).map { HourChip(hour: $0, state: $1) }
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
