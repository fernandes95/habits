//
//  EventKitService.swift
//  Habits
//
//  Created by Tiago Fernandes on 11/03/2024.
//

import Foundation
import EventKit
import SwiftUI

struct EventKitService {
    private let eventStore: EKEventStore = EKEventStore()

    private func verifyAuthStatus() async throws -> Bool {
        let status: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if status == .notDetermined {
            return if #available(iOS 17.0, *) {
                try await self.eventStore.requestFullAccessToEvents()
            } else {
                try await self.eventStore.requestAccess(to: .event)
            }
        }
        return true
    }

    func createCalendarEvent(_ habit: Habit) async throws -> String {
        guard try await verifyAuthStatus() else { return "" }

        let newEvent: EKEvent = habit.getEKEvent(store: self.eventStore)

        do {
            try self.eventStore.save(newEvent, span: .thisEvent)
            return newEvent.eventIdentifier
        } catch {
            print("ERROR CREATING CALENDAR EVENT")
            return ""
        }
    }

    func createScheduleCalendarEvents(_ habit: Habit) async throws -> [Habit.Hour] {
        guard try await verifyAuthStatus() else { return habit.schedule }
        var newSchedule: [Habit.Hour] = habit.schedule

        for hour in habit.schedule {
            let calendar: Calendar = Calendar.current
            let newEvent: EKEvent = habit.getEKEvent(store: self.eventStore)
            newEvent.startDate = hour.date

            var components: DateComponents = DateComponents()
            components.minute = 30
            let newEndDate = calendar.date(byAdding: components, to: hour.date)
            newEvent.endDate = newEndDate
            newEvent.addAlarm(EKAlarm(absoluteDate: hour.date))

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
        guard try await verifyAuthStatus() else { return habit.schedule }
        var newSchedule: [Habit.Hour] = habit.schedule
        let calendar: Calendar = Calendar.current
        var components: DateComponents = DateComponents()
        components.minute = 30

        // REMOVE HOURS FROM SCHEDULE THAT WERE DELETED
        removeEvents(habit: habit, schedule: oldHabit.schedule)

        // MANAGE EDITED AND NEW HOURS IN SCHEDULE
        for hour in habit.schedule {
            let newEndDate: Date? = calendar.date(byAdding: components, to: hour.date)

            if hour.eventId.isEmpty {
                let newEvent: EKEvent = habit.getEKEvent(store: self.eventStore)
                newEvent.startDate = hour.date
                newEvent.endDate = newEndDate

                if habit.hasAlarm {
                    newEvent.addAlarm(EKAlarm(absoluteDate: hour.date))
                }

                do {
                    try self.eventStore.save(newEvent, span: .thisEvent)

                    if let index: Int = newSchedule.firstIndex(of: hour) {
                        newSchedule[index].eventId = newEvent.eventIdentifier
                    }
                } catch {
                    print("ERROR CREATING CALENDAR EVENT")
                }
            } else {
                if let event: EKEvent = self.getEventById(eventId: hour.eventId) {
                    let recurrenceRule: EKRecurrenceRule = habit.getEKRecurrenceRule()
                    event.title = habit.name
                    event.startDate = hour.date
                    event.endDate = newEndDate
                    event.recurrenceRules = [recurrenceRule]

                    if let alarms = event.alarms {
                        for alarm in alarms {
                            event.removeAlarm(alarm)
                        }
                    }

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
