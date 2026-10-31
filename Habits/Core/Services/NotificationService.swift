//
//  NotificationService.swift
//  Habits
//
//  Created by Tiago Fernandes on 24/03/2024.
//

import Foundation
import UserNotifications

class NotificationService {
    private let notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()
    private let notificationDelegate: NotificationDelegate = NotificationDelegate()

    init() {
        self.notificationCenter.delegate = self.notificationDelegate
    }

    func getNotificationStatus() async -> UNAuthorizationStatus {
        let settings: UNNotificationSettings =
        await UNUserNotificationCenter.current().notificationSettings()

        return settings.authorizationStatus
    }

    /// Request notification Authorizatoion
    func notificationAuthorization() async throws -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    /// Creates notification
    ///
    /// If no set date, the notification will be scheduled to 5 seconds later
    ///
    /// - Parameter subTitle: Notification content text
    /// - Parameter date: Date when the notification will me shown
    /// - Parameter identifier: Notification identifier
    private func notificationContent(subTitle: String, date: Date?, identifier: String? = nil) async throws {
        let notificationContent = UNMutableNotificationContent()
        let requestIndentifer = identifier ?? UUID().uuidString

        // Same name as under the app icon, "World of habits"
        notificationContent.title = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? "World of habits"
        notificationContent.subtitle = subTitle
        notificationContent.sound = UNNotificationSound.default

        var trigger: UNNotificationTrigger {
            if let date {
                let dateComponents = Calendar.current.dateComponents(
                    [.day, .month, .year, .hour, .minute, .second],
                    from: date
                )

                return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            }

            return UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: requestIndentifer,
            content: notificationContent,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch let error as LocalizedError {
            print(error)
        }
    }

    /// Creates notification
    ///
    /// - Parameter subTitle: Notification content text
    /// - Parameter date: Date when the notification will me shown
    /// - Parameter identifier: Notification identifier
    private func requestNotification(subTitle: String, date: Date, identifier: String? = nil) async throws {
        try await notificationContent(subTitle: subTitle, date: date, identifier: identifier)
    }

    /// Creates a notification to sent in 5 seconds
    ///
    /// - Parameter subTitle: Notification contente text
    /// - Parameter identifier: Notification identifier
    func requestInstantNotification(subTitle: String, identifier: String? = nil) async throws {
        try await notificationContent(subTitle: subTitle, date: nil, identifier: identifier)
    }

    /// Remove pending notification by identifier
    ///
    /// - Parameter identifier: Notification identifier
    func removePendingNotification(identifer: String?) {
        guard identifer != nil else { return }

        let identifiers: [String] = [identifer!]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Replaces every pending habit reminder with `reminders`, other notifications are left untouched.
    ///
    /// Reminders are one-off notifications for a single day, so a checked hour can drop its reminder
    /// without touching the other days.
    ///
    /// - Parameter reminders: Reminders to schedule, iOS keeps at most 64 pending notifications
    func replaceReminders(_ reminders: [Reminder]) async {
        let pending: [UNNotificationRequest] = await self.notificationCenter.pendingNotificationRequests()
        let oldIdentifiers: [String] = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Reminder.identifierPrefix) }
        self.notificationCenter.removePendingNotificationRequests(withIdentifiers: oldIdentifiers)

        for reminder in reminders {
            do {
                try await self.requestNotification(
                    subTitle: reminder.title,
                    date: reminder.date,
                    identifier: reminder.identifier
                )
            } catch { print(error.localizedDescription) }
        }
    }
}

extension NotificationService {
    /// Notification of a habit hour on one day
    struct Reminder: Equatable {
        static let identifierPrefix: String = "habit_reminder_"

        let habitId: UUID
        let hourId: UUID
        let title: String
        let date: Date

        /// Same habit, hour and day always get the same identifier
        var identifier: String {
            let day = self.date.formatted(.iso8601.year().month().day())
            return "\(Self.identifierPrefix)\(self.habitId.uuidString)_\(self.hourId.uuidString)_\(day)"
        }
    }
}

extension NotificationService {
    /// Delegate so that app can receive notifications while app’s life cycle on FOREGROUND ACTIVE
    class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            completionHandler([.badge, .banner, .sound])
        }
    }
}
