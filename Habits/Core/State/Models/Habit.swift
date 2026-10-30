//
//  Habit.swift
//  Habits
//
//  Created by Tiago Fernandes on 27/02/2024.
//

import Foundation
import EventKit
import MapKit

// swiftlint:disable:next type_body_length
struct Habit: Identifiable, Equatable {
    var id: UUID
    var eventId: String
    var name: String
    var startDate: Date
    var endDate: Date
    var hasNoEndDate: Bool
    var frequency: Frequency
    var frequencyType: Ocurrence
    var goal: Goal?
    var completedCount: Int
    var category: Category
    var scheduleInterval: Int?
    var schedule: [Hour]
    var isChecked: Bool
    var history: [DayRecord]
    var hasAlarm: Bool
    let createdDate: Date
    var updatedDate: Date
    var hasLocationReminder: Bool
    var location: Location?
    /// Reminder hours done on the date the habit was loaded for, with when they were done
    var checkedHours: [UUID: Date] = [:]

    init(
        id: UUID,
        eventId: String,
        name: String,
        startDate: Date,
        endDate: Date,
        hasNoEndDate: Bool,
        frequency: String,
        frequencyType: Ocurrence,
        completedCount: Int,
        category: String,
        schedule: [Hour],
        isChecked: Bool,
        history: [DayRecord],
        hasAlarm: Bool,
        createdDate: Date,
        updatedDate: Date,
        hasLocationReminder: Bool = false,
        location: Location? = nil,
        scheduleInterval: Int? = nil,
        goal: Goal? = nil
    ) {
        self.id = id
        self.eventId = eventId
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.hasNoEndDate = hasNoEndDate
        self.frequency = getFrequency(frequency)
        self.frequencyType = frequencyType
        self.completedCount = completedCount
        self.category = getCategory(category)
        self.isChecked = isChecked
        self.history = history
        self.hasAlarm = hasAlarm
        self.createdDate = createdDate
        self.updatedDate = updatedDate
        self.schedule = schedule
        self.hasLocationReminder = hasLocationReminder
        self.location = location
        self.scheduleInterval = scheduleInterval
        self.goal = goal
    }

    internal func with(
        eventId: String? = nil,
        name: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        hasNoEndDate: Bool? = nil,
        frequency: String? = nil,
        frequencyType: Ocurrence? = nil,
        completedCount: Int? = nil,
        category: String? = nil,
        scheduleInterval: Int? = nil,
        schedule: [Hour]? = nil,
        isChecked: Bool? = nil,
        history: [DayRecord]? = nil,
        hasAlarm: Bool? = nil,
        createdDate: Date? = nil,
        updatedDate: Date? = nil,
        hasLocationReminder: Bool? = nil,
        location: Location? = nil,
        goal: Goal? = nil
    ) -> Self {
        var habit = Self(
            id: self.id,
            eventId: eventId ?? self.eventId,
            name: name ?? self.name,
            startDate: startDate ?? self.startDate,
            endDate: endDate ?? self.endDate,
            hasNoEndDate: hasNoEndDate ?? self.hasNoEndDate,
            frequency: frequency ?? self.frequency.rawValue,
            frequencyType: frequencyType ?? self.frequencyType,
            completedCount: completedCount ?? self.completedCount,
            category: category ?? self.category.rawValue,
            schedule: schedule ?? self.schedule,
            isChecked: isChecked ?? self.isChecked,
            history: history ?? self.history,
            hasAlarm: hasAlarm ?? self.hasAlarm,
            createdDate: createdDate ?? self.createdDate,
            updatedDate: updatedDate ?? self.updatedDate,
            hasLocationReminder: hasLocationReminder ?? self.hasLocationReminder,
            location: location ?? self.location,
            scheduleInterval: scheduleInterval ?? self.scheduleInterval,
            goal: goal ?? self.goal
        )
        habit.checkedHours = self.checkedHours
        return habit
    }

    init(habitEntity: HabitEntity, selectedDate: Date? = nil) {
        self.id = habitEntity.id
        self.eventId = habitEntity.eventId
        self.name = habitEntity.name
        self.startDate = habitEntity.startDate
        self.endDate = habitEntity.endDate
        self.hasNoEndDate = habitEntity.hasNoEndDate
        self.frequency = getFrequency(habitEntity.frequency)
        self.frequencyType = habitEntity.frequencyType
        self.category = getCategory(habitEntity.category)
        self.scheduleInterval = habitEntity.scheduleInterval
        self.goal = habitEntity.goal

        self.schedule = habitEntity.schedule.map { hourEntity in
            return Hour(
                id: hourEntity.id,
                eventId: hourEntity.eventId,
                notificationId: hourEntity.notificationId,
                date: hourEntity.date
            )
        }

        self.isChecked = false
        let currentTarget: Int? = habitEntity.goal?.value
        let hoursCount: Int = habitEntity.hasAlarm ? habitEntity.schedule.count : 0
        self.history = habitEntity.statusList.map { status in
            // Days with reminder hours count the hours done, so a day with missed hours is partly done
            if let hours = status.hours, hoursCount > 0 {
                return DayRecord(date: status.date, count: hours.count, requiredCount: hoursCount, isChecked: status.isChecked)
            }
            return DayRecord(
                date: status.date,
                count: status.count,
                // Older statuses were saved without a target, fall back to the current one.
                requiredCount: status.requiredCount ?? currentTarget,
                isChecked: status.isChecked
            )
        }

        self.hasAlarm = habitEntity.hasAlarm
        self.hasLocationReminder = habitEntity.hasLocationReminder
        self.location = getLocation(location: habitEntity.location)
        self.createdDate = habitEntity.createdDate
        self.updatedDate = habitEntity.updatedDate
        self.isChecked = false
        self.completedCount = 0

        if let selectedDate,
           let status: HabitEntity.Status = habitEntity.statusList.first(
                where: { $0.date.formatDate() == selectedDate.formatDate() }
            ) {
                self.isChecked = status.isChecked
                self.completedCount = status.count
                self.updatedDate = status.updatedDate
                self.checkedHours = Dictionary(
                    (status.hours ?? []).map { ($0.hourId, $0.date) },
                    uniquingKeysWith: { first, _ in first }
                )
            }
    }

    /// Progress of this habit on the date it was loaded for, between 0 and 1.
    /// Habits with a goal count partial progress, every other habit is either done or not.
    var dayProgress: Double {
        if self.isChecked { return 1 }

        let goalProgress: Double = if let goal = self.goal, goal.value > 0 {
            min(Double(self.completedCount) / Double(goal.value), 1)
        } else {
            0
        }

        // Each reminder hour is an equal part of the day, the steps fill the hour being done
        let hours = self.reminderHours
        if !hours.isEmpty {
            let doneHours = hours.filter { self.checkedHours[$0.id] != nil }.count
            return min((Double(doneHours) + goalProgress) / Double(hours.count), 1)
        }

        return goalProgress
    }

    /// Number of different days this habit was checked during the week of `date`.
    /// The week boundaries come from `calendar`, so they follow the start of the week setting.
    func checkedDays(inWeekOf date: Date, calendar: Calendar) -> Int {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else { return 0 }

        let days = self.history
            .filter { $0.isChecked && $0.date >= week.start && $0.date < week.end }
            .map { calendar.startOfDay(for: $0.date) }

        return Set(days).count
    }

    /// True when a `.minDays` habit was checked on at least `minimumDays` days in the week of `date`.
    func hasReachedMinDays(inWeekOf date: Date, calendar: Calendar) -> Bool {
        guard self.frequency == .minDays, self.frequencyType.minimumDays > 0 else { return false }
        return self.checkedDays(inWeekOf: date, calendar: calendar) >= self.frequencyType.minimumDays
    }

    private func getEKRecurrenceDaysOfWeek() -> [EKRecurrenceDayOfWeek] {
        return self.frequencyType.weekFrequency.map { EKRecurrenceDayOfWeek($0.ekWeekday) }
    }

    func getEKRecurrenceRule() -> EKRecurrenceRule {
        let daysOfTheWeek: [EKRecurrenceDayOfWeek] = getEKRecurrenceDaysOfWeek()
        let recurrenceEnd: EKRecurrenceEnd = EKRecurrenceEnd.init(end: self.endDate.endOfDay)
        return if self.frequency == .weekly {
            EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 1,
                daysOfTheWeek: daysOfTheWeek,
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: recurrenceEnd
            )
        } else {
            EKRecurrenceRule(
                recurrenceWith: .daily,
                interval: self.scheduleInterval ?? 1,
                end: recurrenceEnd
            )
        }
    }

    func getCalendarEvent(
        store: EKEventStore,
        startDate: Date? = nil,
        endDate: Date? = nil,
        alarmHour: Date? = nil) -> EKEvent {
        let event: EKEvent = EKEvent(eventStore: store)
        let recurrenceRule: EKRecurrenceRule = getEKRecurrenceRule()

        event.title = self.name
        event.startDate = startDate
        event.endDate = endDate

        if let alarmHour {
            event.addAlarm(EKAlarm(absoluteDate: alarmHour))
        }

        if self.schedule.isEmpty {
            event.isAllDay = true
        }

        event.calendar = store.defaultCalendarForNewEvents
        event.recurrenceRules = [recurrenceRule]

        return event
    }

    enum Category: String, Identifiable, CaseIterable {
        case new = "New habit"
        case maintain = "Keep habit"
        case bad = "Bad habit"

        var id: String {
            rawValue.capitalized
        }

        /// Name shown to the user, `rawValue` is what gets saved
        var title: LocalizedStringResource {
            switch self {
            case .new: "habit_category_new"
            case .maintain: "habit_category_maintain"
            case .bad: "habit_category_bad"
            }
        }
    }

    enum Frequency: String, Identifiable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case interval = "Interval"
        case minDays = "Minimum Days"

        var id: String {
            rawValue.capitalized
        }

        /// Name shown to the user, `rawValue` is what gets saved
        var title: LocalizedStringResource {
            switch self {
            case .daily: "habit_frequency_daily"
            case .weekly: "habit_frequency_weekly"
            case .interval: "habit_frequency_interval"
            case .minDays: "habit_frequency_min_days"
            }
        }
    }

    struct Location: Equatable {
        static func == (lhs: Habit.Location, rhs: Habit.Location) -> Bool {
            return lhs.locationCoordinate.latitude == rhs.locationCoordinate.latitude &&
            lhs.locationCoordinate.longitude == rhs.locationCoordinate.longitude &&
            lhs.region.center.latitude == rhs.region.center.latitude &&
            lhs.region.center.longitude == rhs.region.center.longitude &&
            lhs.place == rhs.place
        }

        var latitude: CLLocationDegrees
        var longitude: CLLocationDegrees
        var locationCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        var region: MKCoordinateRegion
        /// Place picked in the location search, nil when the pin was dropped by hand
        var place: LocationPlaceDetails?

        init(latitude: Double, longitude: Double, region: MKCoordinateRegion, place: LocationPlaceDetails? = nil) {
            self.latitude = latitude
            self.longitude = longitude
            self.locationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.region = region
            self.place = place
        }

        /// Stored version of this location, keeping the picked place name and address
        var entity: HabitEntity.Location {
            HabitEntity.Location(
                latitude: self.latitude,
                longitude: self.longitude,
                name: self.place?.name,
                address: self.place?.address
            )
        }
    }

    struct DayRecord: Equatable {
        let date: Date
        let count: Int
        let requiredCount: Int?
        let isChecked: Bool
    }
}

// MARK: Validation
extension Habit {
    /// True when the habit can be added or saved from the add and edit habit forms.
    var isValid: Bool {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !self.hasDuplicatedScheduleHours else { return false }

        if let goal = self.goal, !goal.isValid { return false }

        switch self.frequency {
        case .daily: return true
        case .interval: return (self.scheduleInterval ?? 0) > 2
        case .weekly: return !self.frequencyType.weekFrequency.isEmpty
        case .minDays: return (1...6).contains(self.frequencyType.minimumDays)
        }
    }

    /// True when two reminder hours fire at the same hour and minute.
    /// Hours kept while the reminder is off are hidden, so they don't count.
    var hasDuplicatedScheduleHours: Bool {
        let hours = self.reminderHours.map(\.minutesOfDay)
        return Set(hours).count != hours.count
    }
}

// MARK: Week days
extension Habit {
    /// Days the habit repeats on, every day for `.daily` habits
    var repeatWeekDays: Set<WeekDay> {
        self.frequency == .daily ? Set(WeekDay.allCases) : Set(self.frequencyType.weekFrequency)
    }

    /// Selects or skips `day`. Every day selected is a `.daily` habit, only some of them is `.weekly`
    mutating func toggleWeekDay(_ day: WeekDay) {
        var days = self.repeatWeekDays
        if days.contains(day) {
            days.remove(day)
        } else {
            days.insert(day)
        }

        if days.count == WeekDay.allCases.count {
            self.frequency = .daily
            self.frequencyType.weekFrequency.removeAll()
        } else {
            self.frequency = .weekly
            self.frequencyType.weekFrequency = WeekDay.allCases.filter { days.contains($0) }
        }
    }
}

func getFrequency(_ frequency: String) -> Habit.Frequency {
    return switch frequency {
    case Habit.Frequency.weekly.rawValue:
        .weekly
    case Habit.Frequency.interval.rawValue:
        .interval
    case Habit.Frequency.minDays.rawValue:
        .minDays
    default:
        .daily
    }
}

func getCategory(_ category: String) -> Habit.Category {
    return switch category {
    case Habit.Category.maintain.rawValue:
        .maintain
    case Habit.Category.bad.rawValue:
        .bad
    default:
        .new
    }
}

func getLocation(location: HabitEntity.Location?) -> Habit.Location? {
    guard location != nil else { return nil }

    return Habit.Location(
        latitude: location!.latitude,
        longitude: location!.longitude,
        region: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: location!.latitude, longitude: location!.longitude),
            latitudinalMeters: .mapDistance,
            longitudinalMeters: .mapDistance),
        place: location!.name.map { LocationPlaceDetails(name: $0, address: location!.address) }
    )
}
