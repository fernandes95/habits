//
//  AuthService.swift
//  Habits
//
//  Created by Tiago Fernandes on 21/03/2024.
//

import Foundation
import EventKit
import UserNotifications

struct AuthorizationService {

    func eventStoreAuth() async throws -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }

    func notificationsAuth() async throws -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }
}
