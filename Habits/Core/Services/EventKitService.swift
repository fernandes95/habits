//
//  EventKitService.swift
//  Habits
//
//  Created by Tiago Fernandes on 11/03/2024.
//

import Foundation
import EventKit

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
                eventToEdit.title = habit.name
                eventToEdit.recurrenceRules = [
                    EKRecurrenceRule(
                        recurrenceWith: EKRecurrenceFrequency.daily,
                        interval: 1,
                        end: EKRecurrenceEnd.init(end: habit.endDate.endOfDay)
                    )
                ]
                
                try self.eventStore.save(eventToEdit, span: .futureEvents)
            } catch {
                print("Error editing event: \(error.localizedDescription)")
            }
        }
    }
}
