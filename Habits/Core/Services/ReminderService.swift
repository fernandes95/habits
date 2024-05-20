//
//  ReminderService.swift
//  Habits
//
//  Created by Tiago Fernandes on 20/05/2024.
//

import Foundation
import EventKit

class ReminderService {
    private let eventStore: EKEventStore = EKEventStore()
    private let notificationService: NotificationService = NotificationService()

    private func getEventStoreAuthStatus() async throws -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .reminder)
    }

    /// Verifies Reminder Authorization
    /// Requests Authorization if status is .notDetermined
    private func verifyAuthStatus() async throws -> Bool {
        let status = try await getEventStoreAuthStatus()

        return switch status {
        case .notDetermined:
            if #available(iOS 17.0, *) {
                try await self.eventStore.requestFullAccessToReminders()
            } else {
                try await self.eventStore.requestAccess(to: .reminder)
            }
        case .fullAccess,
             .restricted,
             .writeOnly:
            true
        default:
            false
        }
    }

    /// Creates new Reminder event
    ///
    /// - Parameters:
    ///   - habit: Habit to create reminder from
    ///
    func createReminder(_ habit: Habit) async throws -> String {
        guard try await verifyAuthStatus() else { return "" }

        let newReminder: EKReminder = habit.getReminder(store: self.eventStore)

        do {
            try self.eventStore.save(newReminder, commit: true)
            return newReminder.calendarItemIdentifier
        } catch {
            print("ERROR CREATING REMINDER")
            return ""
        }
    }
}
