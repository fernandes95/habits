//
//  CalendarService.swift
//  Habits
//
//  Created by Tiago Fernandes on 11/03/2024.
//

import Foundation
import EventKit
import SwiftUI

class CalendarService {
    private let eventStore: EKEventStore = EKEventStore()
    private let authService: AuthorizationService = AuthorizationService()
    private let notificationService: NotificationService = NotificationService()

    private func verifyAuthStatus() async throws -> Bool {
        let status = try await authService.eventStoreAuth()

        return switch status {
        case .notDetermined:
            if #available(iOS 17.0, *) {
                try await self.eventStore.requestFullAccessToEvents()
            } else {
                try await self.eventStore.requestAccess(to: .event)
            }
        case .fullAccess,
             .restricted,
             .writeOnly:
            true
        default:
            false
        }
    }

    func createCalendarEvent(_ habit: Habit) async throws -> String {
        guard try await verifyAuthStatus() else { return "" }

        let newEvent: EKEvent = habit.getCalendarEvent(store: self.eventStore)

        do {
            try self.eventStore.save(newEvent, span: .thisEvent)
            return newEvent.eventIdentifier
        } catch {
            print("ERROR CREATING CALENDAR EVENT")
            return ""
        }
    }

    func createScheduleCalendarEvents(_ habit: Habit) async throws -> [Habit.Hour] {
        guard try await verifyAuthStatus() else {
            return try await notificationService.manageLocalNotifications(habit: habit)
        }

        var newSchedule: [Habit.Hour] = habit.schedule

        for hour in habit.schedule {
            var components: DateComponents = DateComponents()
            components.minute = 30
            let newEndDate = Calendar.current.date(byAdding: components, to: hour.date)
            let newEvent: EKEvent = habit.getCalendarEvent(
                store: self.eventStore,
                startDate: hour.date,
                endDate: newEndDate,
                alarmHour: hour.date
            )

            do {
                try self.eventStore.save(newEvent, span: .thisEvent)

                if let index = newSchedule.firstIndex(of: hour) {
                    newSchedule[index].eventId = newEvent.eventIdentifier
                }
            } catch {
                print("ERROR CREATING CALENDAR EVENT")
            }
        }

        return newSchedule
    }

    private func removeEvents(habit: Habit, schedule: [Habit.Hour]) {
        for hour in schedule {
            // swiftlint:disable:next for_where
            if !habit.schedule.contains(where: {$0.id == hour.id}) {
                deleteEventById(eventId: hour.eventId)
            }
        }
    }

    func manageScheduleEvents(_ habit: Habit, oldHabit: Habit) async throws -> [Habit.Hour] {
        guard try await verifyAuthStatus() else {
            return try await notificationService.manageScheduledNotifications(habit, oldHabit: oldHabit)
        }

        var newSchedule: [Habit.Hour] = habit.schedule
        var components: DateComponents = DateComponents()
        components.minute = 30

        // REMOVE HOURS FROM SCHEDULE THAT WERE DELETED
        removeEvents(habit: habit, schedule: oldHabit.schedule)

        // MANAGE EDITED AND NEW HOURS IN SCHEDULE
        for hour in habit.schedule {
            let newEndDate: Date? = Calendar.current.date(byAdding: components, to: hour.date)

            if hour.eventId.isEmpty {
                // creating new calendar event
                let newEvent: EKEvent = habit.getCalendarEvent(
                    store: self.eventStore,
                    startDate: hour.date,
                    endDate: newEndDate,
                    alarmHour: habit.hasAlarm ? hour.date : nil
                )

                do {
                    try self.eventStore.save(newEvent, span: .thisEvent)

                    if let index: Int = newSchedule.firstIndex(of: hour) {
                        newSchedule[index].eventId = newEvent.eventIdentifier
                    }
                } catch {
                    print("ERROR CREATING CALENDAR EVENT")
                }
            } else {
                // getting existing calendar event
                if let event: EKEvent = self.getEventById(eventId: hour.eventId) {
                    let recurrenceRule: EKRecurrenceRule = habit.getEKRecurrenceRule()
                    event.title = habit.name
                    event.startDate = hour.date
                    event.endDate = newEndDate
                    event.recurrenceRules = [recurrenceRule]

                    // removing all alarms in calendar event
                    if let alarms = event.alarms {
                        for alarm in alarms {
                            event.removeAlarm(alarm)
                        }
                    }

                    // adding new alarm in calendar event
                    if habit.hasAlarm {
                        event.addAlarm(EKAlarm(absoluteDate: hour.date))
                    }

                    do {
                        try self.eventStore.save(event, span: .futureEvents)
                    } catch {
                        print("ERROR CREATING CALENDAR EVENT")
                    }
                }
            }
        }

        return newSchedule
    }

    func getEventById(eventId: String) -> EKEvent? {
          return self.eventStore.event(withIdentifier: eventId)
    }

    func deleteEventById(eventId: String) {
        if let eventToDelete: EKEvent = self.getEventById(eventId: eventId) {
            do {
                try self.eventStore.remove(eventToDelete, span: .futureEvents)
            } catch {
                print("Error deleting event: \(error.localizedDescription)")
            }
        }
    }

    func editEvent(_ habit: Habit) {
        if let eventToEdit: EKEvent = self.getEventById(eventId: habit.eventId) {
            do {
                let recurrenceRule: EKRecurrenceRule = habit.getEKRecurrenceRule()
                eventToEdit.title = habit.name
                eventToEdit.recurrenceRules = [recurrenceRule]

                try self.eventStore.save(eventToEdit, span: .futureEvents)
            } catch {
                print("Error editing event: \(error.localizedDescription)")
            }
        }
    }
}
