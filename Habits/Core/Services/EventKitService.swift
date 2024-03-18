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
        let status = EKEventStore.authorizationStatus(for: .event)
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

        let newEvent = habit.getEKEvent(store: self.eventStore)

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
        var newSchedule = habit.schedule

        for hour in habit.schedule {
            let calendar = Calendar.current
            let newEvent = habit.getEKEvent(store: self.eventStore)
            newEvent.startDate = hour.date

            var components = DateComponents()
            components.minute = 30
            let newEndDate = calendar.date(byAdding: components, to: hour.date)
            newEvent.endDate = newEndDate

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

    func manageScheduleEvents(_ habit: Habit, oldHabit: Habit) async throws -> [Habit.Hour] {
        guard try await verifyAuthStatus() else { return habit.schedule }
        var newSchedule = habit.schedule
        let calendar = Calendar.current
        var components = DateComponents()
        components.minute = 30

        // REMOVE HOURS FROM SCHEDULE THAT WERE DELETED
        for hour in oldHabit.schedule {
            // swiftlint:disable:next for_where
            if !habit.schedule.contains(where: {$0.id == hour.id}) {
                deleteEventById(eventId: hour.eventId)
            }
        }

        // MANAGE EDITED AND NEW HOURS IN SCHEDULE
        for hour in habit.schedule {
            let newEndDate = calendar.date(byAdding: components, to: hour.date)

            if hour.eventId.isEmpty {
                let newEvent = habit.getEKEvent(store: self.eventStore)
                newEvent.startDate = hour.date
                newEvent.endDate = newEndDate

                do {
                    try self.eventStore.save(newEvent, span: .thisEvent)

                    if let index = newSchedule.firstIndex(of: hour) {
                        newSchedule[index].eventId = newEvent.eventIdentifier
                    }
                } catch {
                    print("ERROR CREATING CALENDAR EVENT")
                }
            } else {
                if let event = self.getEventById(eventId: hour.eventId) {
                    let recurrenceRule = habit.getEKRecurrenceRule()
                    event.title = habit.name
                    event.startDate = hour.date
                    event.endDate = newEndDate
                    event.recurrenceRules = [recurrenceRule]

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
        if let eventToDelete = self.getEventById(eventId: eventId) {
            do {
                try self.eventStore.remove(eventToDelete, span: .futureEvents)
            } catch {
                print("Error deleting event: \(error.localizedDescription)")
            }
        }
    }

    func editEvent(_ habit: Habit) {
        if let eventToEdit = self.getEventById(eventId: habit.eventId) {
            do {
                let recurrenceRule = habit.getEKRecurrenceRule()
                eventToEdit.title = habit.name
                eventToEdit.recurrenceRules = [recurrenceRule]

                try self.eventStore.save(eventToEdit, span: .futureEvents)
            } catch {
                print("Error editing event: \(error.localizedDescription)")
            }
        }
    }
}
