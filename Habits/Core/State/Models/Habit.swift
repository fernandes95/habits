//
//  Habit.swift
//  Habits
//
//  Created by Tiago Fernandes on 27/02/2024.
//

import Foundation
import EventKit

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
    var successRate: String
    let createdDate: Date
    var updatedDate: Date

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
        successRate: String,
        createdDate: Date,
        updatedDate: Date
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
        self.successRate = successRate
        self.createdDate = createdDate
        self.updatedDate = updatedDate
        self.schedule = schedule
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
            return Hour(id: hourEntity.id, eventId: hourEntity.eventId, date: hourEntity.date)
        }

        self.isChecked = false
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
        let list = self.frequencyType.weekFrequency
        var weekDays: [EKRecurrenceDayOfWeek] = []

        for day in list {
            let weekDay: EKWeekday = switch day {
            case WeekDay.monday:
                EKWeekday.monday
            case WeekDay.tuesday:
                EKWeekday.tuesday
            case WeekDay.wednesday:
                EKWeekday.wednesday
            case WeekDay.thursday:
                EKWeekday.thursday
            case WeekDay.friday:
                EKWeekday.friday
            case WeekDay.saturday:
                EKWeekday.saturday
            default:
                EKWeekday.sunday
            }
            weekDays.append(EKRecurrenceDayOfWeek(weekDay))
        }
        return weekDays
    }

    func getEKRecurrenceRule() -> EKRecurrenceRule {
        let daysOfTheWeek = getEKRecurrenceDaysOfWeek()
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
        let event = EKEvent(eventStore: store)
        let recurrenceRule = getEKRecurrenceRule()

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
        case monthly = "Monthly"
        case yearly = "Yearly"
//        case Custom

        var id: String {
            rawValue.capitalized
        }
    }

    struct Hour: Identifiable, Equatable {
        let id: UUID
        var eventId: String
        var date: Date
        var hour: String

        init(id: UUID = UUID(), eventId: String, date: Date) {
            self.id = id
            self.eventId = eventId
            self.date = date
            self.hour = date.getHourAndMinutes()
        }
    }
}

func getFrequency(_ frequency: String) -> Habit.Frequency {
    return switch frequency {
    case Habit.Frequency.weekly.rawValue:
        .weekly
    case Habit.Frequency.monthly.rawValue:
        .monthly
    case Habit.Frequency.yearly.rawValue:
        .yearly
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
