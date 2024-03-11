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
    
    func deleteEventById(eventId: String) {
        if let eventToDelete = self.eventStore.event(withIdentifier: eventId) {
            do {
                try  self.eventStore.remove(eventToDelete, span: .thisEvent)
            } catch {
                print("Error deleting event: \(error.localizedDescription)")
            }
        }
    }
    
    func getEventById(eventId: String) -> EKEvent? {
          return self.eventStore.event(withIdentifier: eventId)
    }
    
    func editEventById(evendId: String) {
    }
}
