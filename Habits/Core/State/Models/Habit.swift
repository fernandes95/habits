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
    var category: Category
    var schedule: [Hour]
    var isChecked: Bool
    var successRate: String
    let createdDate: Date
    var updatedDate: Date
    
    init(id: UUID, eventId: String, name: String, startDate: Date, endDate: Date, frequency: String, category: String, schedule: [Hour], isChecked: Bool, successRate: String, createdDate: Date, updatedDate: Date) {
        self.id = id
        self.eventId = eventId
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.frequency = getFrequency(frequency)
        self.category = getCategory(category)
        self.isChecked = isChecked
        self.successRate = successRate
        self.createdDate = createdDate
        self.updatedDate = updatedDate
        self.schedule = schedule
    }
    
    init(habitEntity: HabitEntity, selectedDate: Date) {
        self.id = habitEntity.id
        self.eventId = habitEntity.eventId
        self.name = habitEntity.name
        self.startDate = habitEntity.startDate
        self.endDate = habitEntity.endDate
        self.frequency = getFrequency(habitEntity.frequency)
        self.category = getCategory(habitEntity.category)
        
        self.schedule = habitEntity.schedule.map { hourEntity in
            return Hour(id: hourEntity.id, date: hourEntity.date)
        }
        
        self.isChecked = false
        self.successRate = "\(habitEntity.successRate)%"
        self.createdDate = habitEntity.createdDate
        self.updatedDate = habitEntity.updatedDate
        
        if let status: HabitEntity.Status = habitEntity.statusList.first(
            where: { $0.date.formatDate() == selectedDate.formatDate()}
        ) {
            self.isChecked = status.isChecked
            self.updatedDate = status.updatedDate
        }
    }
    
    func getEKEvent(store: EKEventStore) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = self.name
        event.startDate = self.startDate
        event.endDate = self.startDate
        event.calendar = store.defaultCalendarForNewEvents
        event.recurrenceRules = [
            EKRecurrenceRule(
                recurrenceWith: EKRecurrenceFrequency.daily,
                interval: 1,
                end: EKRecurrenceEnd.init(end: self.endDate)
            )
        ]
        
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
        var date: Date
        var hour: String
        
        init(id: UUID = UUID(), date: Date) {
            self.id = id
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
    case Habit.Frequency.monthly.rawValue:
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
