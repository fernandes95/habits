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

    func notificationsAuth(delegate: NotificationService.NotificationDelegate) async throws -> Bool {
        do {
            var hasAuthorization: Bool = false
            hasAuthorization = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            UNUserNotificationCenter.current().delegate = delegate

            return hasAuthorization
        } catch {
            return false
        }
    }
}
