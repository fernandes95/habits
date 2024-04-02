//
//  Habit.swift
//  Habits
//
//  Created by Tiago Fernandes on 27/02/2024.
//

import Foundation
import EventKit
import MapKit

struct Habit: Identifiable, Equatable {
    var id: UUID
    var eventId: String
    var name: String
    var startDate: Date
    var endDate: Date
    var frequency: Frequency
    var frequencyType: Ocurrence
    var category: Category
    var schedule: [Hour]
    var isChecked: Bool
    var hasAlarm: Bool
    var successRate: String
    let createdDate: Date
    var updatedDate: Date
    var hasLocationReminder: Bool
    var location: Location?

    init(
        id: UUID,
        eventId: String,
        name: String,
        startDate: Date,
        endDate: Date,
        frequency: String,
        frequencyType: Ocurrence,
        category: String,
        schedule: [Hour],
        isChecked: Bool,
        hasAlarm: Bool,
        successRate: String,
        createdDate: Date,
        updatedDate: Date,
        hasLocationReminder: Bool = false,
        location: Location? = nil
    ) {
        self.id = id
        self.eventId = eventId
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.frequency = getFrequency(frequency)
        self.frequencyType = frequencyType
        self.category = getCategory(category)
        self.isChecked = isChecked
        self.hasAlarm = hasAlarm
        self.successRate = successRate
        self.createdDate = createdDate
        self.updatedDate = updatedDate
        self.schedule = schedule
        self.hasLocationReminder = hasLocationReminder
        self.location = location
    }

    init(habitEntity: HabitEntity, selectedDate: Date? = nil) {
        self.id = habitEntity.id
        self.eventId = habitEntity.eventId
        self.name = habitEntity.name
        self.startDate = habitEntity.startDate
        self.endDate = habitEntity.endDate
        self.frequency = getFrequency(habitEntity.frequency)
        self.frequencyType = habitEntity.frequencyType
        self.category = getCategory(habitEntity.category)

        self.schedule = habitEntity.schedule.map { hourEntity in
            return Hour(
                id: hourEntity.id,
                eventId: hourEntity.eventId,
                notificationId: hourEntity.notificationId,
                date: hourEntity.date
            )
        }

        self.isChecked = false
        self.hasAlarm = habitEntity.hasAlarm
        self.hasLocationReminder = habitEntity.hasLocationReminder
        self.location = getLocation(location: habitEntity.location)
        self.successRate = "\(habitEntity.successRate)%"
        self.createdDate = habitEntity.createdDate
        self.updatedDate = habitEntity.updatedDate

        if selectedDate != nil {
            if let status: HabitEntity.Status = habitEntity.statusList.first(
                where: { $0.date.formatDate() == selectedDate!.formatDate()}
            ) {
                self.isChecked = status.isChecked
                self.updatedDate = status.updatedDate
            }
        }
    }

    private func getEKRecurrenceDaysOfWeek() -> [EKRecurrenceDayOfWeek] {
        let list: [WeekDay] = self.frequencyType.weekFrequency
        var weekDays: [EKRecurrenceDayOfWeek] = []

        for day in list {
            let weekDay: EKWeekday = switch day {
            case WeekDay.monday:
                .monday
            case WeekDay.tuesday:
                .tuesday
            case WeekDay.wednesday:
                .wednesday
            case WeekDay.thursday:
                .thursday
            case WeekDay.friday:
                .friday
            case WeekDay.saturday:
                .saturday
            default:
                .sunday
            }
            weekDays.append(EKRecurrenceDayOfWeek(weekDay))
        }
        return weekDays
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
                interval: 1,
                end: recurrenceEnd
            )
        }
    }

    func getEKEvent(store: EKEventStore) -> EKEvent {
        let event: EKEvent = EKEvent(eventStore: store)
        let recurrenceRule: EKRecurrenceRule = getEKRecurrenceRule()

        event.title = self.name
        event.startDate = self.startDate
        event.endDate = self.startDate

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
    }

    enum Frequency: String, Identifiable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
//        case monthly = "Monthly"
//        case yearly = "Yearly"
//        case Custom

        var id: String {
            rawValue.capitalized
        }
    }

    struct Hour: Identifiable, Equatable {
        let id: UUID
        var eventId: String
        var notificationId: String?
        var date: Date
        var hour: String

        init(id: UUID = UUID(), eventId: String, notificationId: String? = nil, date: Date) {
            self.id = id
            self.eventId = eventId
            self.notificationId = notificationId
            self.date = date
            self.hour = date.getHourAndMinutes()
        }
    }

    struct Location: Equatable {
        static func == (lhs: Habit.Location, rhs: Habit.Location) -> Bool {
            return lhs.locationCoordinate.latitude == rhs.locationCoordinate.latitude &&
            lhs.locationCoordinate.longitude == rhs.locationCoordinate.longitude &&
            lhs.region.center.latitude == rhs.region.center.latitude &&
            lhs.region.center.longitude == rhs.region.center.longitude
        }

        var latitude: CLLocationDegrees
        var longitude: CLLocationDegrees
        var locationCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        var region: MKCoordinateRegion

        init(latitude: Double, longitude: Double, region: MKCoordinateRegion) {
            self.latitude = latitude
            self.longitude = longitude
            self.locationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.region = region
        }
    }
}

func getFrequency(_ frequency: String) -> Habit.Frequency {
    return switch frequency {
    case Habit.Frequency.weekly.rawValue:
        .weekly
//    case Habit.Frequency.monthly.rawValue:
//        .monthly
//    case Habit.Frequency.yearly.rawValue:
//        .yearly
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
            longitudinalMeters: .mapDistance)
    )
}
