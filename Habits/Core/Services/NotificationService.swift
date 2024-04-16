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
    private let authorizationService: AuthorizationService = AuthorizationService()
    private let notificationDelegate: NotificationDelegate = NotificationDelegate()

    func notificationAuthorization() async throws -> Bool {
        return try await authorizationService.notificationsAuth(delegate: self.notificationDelegate)
    }

    private func notificationContent(subTitle: String, date: Date?, identifier: String? = nil) async throws {
        let notificationContent = UNMutableNotificationContent()
        let requestIndentifer = identifier ?? UUID().uuidString

        notificationContent.title = "Habits"
        notificationContent.subtitle = subTitle
        notificationContent.sound = UNNotificationSound.default

        var trigger: UNNotificationTrigger {
            if let date {
                let dateComponents = Calendar.current.dateComponents(
                    [.day, .month, .year, .hour, .minute],
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

        // TODO: MANAGE ERRORS IN THE FUTURE
        try await notificationCenter.add(request)
    }

    func requestNotification(subTitle: String, date: Date, identifier: String? = nil) async throws {
        try await notificationContent(subTitle: subTitle, date: date, identifier: identifier)
    }

    func requestInstantNotification(subTitle: String, identifier: String? = nil) async throws {
        try await notificationContent(subTitle: subTitle, date: nil, identifier: identifier)
    }

    func removePendingNotification(identifer: String?) {
        guard identifer != nil else { return }

        let identifiers: [String] = [identifer!]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func manageLocalNotifications(habit: Habit) async throws -> [Habit.Hour] {
        guard try await self.notificationAuthorization() else {
            return habit.schedule
        }

        var newSchedule = habit.schedule
        for hour in habit.schedule {
            let requestId = UUID().uuidString

            try await self.requestNotification(
                subTitle: habit.name,
                date: hour.date, identifier: requestId)

            if let index = newSchedule.firstIndex(of: hour) {
                newSchedule[index].notificationId = requestId
            }
        }

        return newSchedule
    }

    private func removeNotifications(habit: Habit, schedule: [Habit.Hour]) {
        for hour in schedule {
            // swiftlint:disable:next for_where
            if !habit.schedule.contains(where: {$0.id == hour.id}) {
                self.removePendingNotification(identifer: hour.notificationId)
            }
        }
    }

    func manageScheduledNotifications(_ habit: Habit, oldHabit: Habit) async throws -> [Habit.Hour] {
        guard try await self.notificationAuthorization() else {
            return habit.schedule
        }

        var newSchedule: [Habit.Hour] = habit.schedule

        // REMOVE NOTIFICATIONS FROM SCHEDULE THAT WERE DELETED
        self.removeNotifications(habit: habit, schedule: oldHabit.schedule)

        // MANAGE EDITED AND NEW HOURS IN SCHEDULE
        for hour in habit.schedule {
            let newRequestId = UUID().uuidString
            var canRequestNotification: Bool = true

            if hour.notificationId != nil {
                if let oldHourIndex = oldHabit.schedule.firstIndex(of: hour) {
                    let oldHour = oldHabit.schedule[oldHourIndex]
                    canRequestNotification = hour.date != oldHour.date
                }

                if canRequestNotification {
                    self.removePendingNotification(identifer: hour.notificationId)
                }
            }

            if canRequestNotification {
                try await self.requestNotification(
                    subTitle: habit.name,
                    date: hour.date,
                    identifier: newRequestId)

                if let index = newSchedule.firstIndex(of: hour) {
                    newSchedule[index].notificationId = newRequestId
                }
            }
        }

        return newSchedule
    }

}

extension NotificationService {
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
