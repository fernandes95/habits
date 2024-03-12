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
      
    func createCalendarEvents(_ habit: Habit, schedule: [Habit.Hour]) async throws -> [Habit.Hour] {
        guard try await verifyAuthStatus() else { return schedule }
        var newSchedule = schedule
        
        for hour in schedule {
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
