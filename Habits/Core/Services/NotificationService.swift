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

        notificationContent.title = "Habits"
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

    /// Creates notifications from Schedule in Habit
    ///
    /// Creates notification for each item in Schedule with the Habit name as Notification Content Title
    ///
    /// - Parameter habit: Habit populate notification
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

    /// Removes pending notifications where items from `Old Schedule` aren't in the `New Schedule`
    ///
    /// - Parameter newSchedule: New Habit Schedule
    /// - Parameter oldSchedule: Old Habit Schedule
    private func removeNotifications(newSchedule: [Habit.Hour], oldSchedule: [Habit.Hour]) {
        for hour in oldSchedule {
            // swiftlint:disable:next for_where
            if !newSchedule.contains(where: {$0.id == hour.id}) {
                self.removePendingNotification(identifer: hour.notificationId)
            }
        }
    }

    /// Managing Pending Notifications 
    ///
    /// First: Removes pending notification that where removed from `Old Habit`
    /// Second: Verifies if hours in `New Habit` Schedule where updated, if true removes pending notification
    /// Third: Creates new notifications
    ///
    /// - Parameter habit: New habit
    /// - Parameter oldHabit: Old habit
    func manageScheduledNotifications(_ habit: Habit, oldHabit: Habit) async throws -> [Habit.Hour] {
        guard try await self.notificationAuthorization() else {
            return habit.schedule
        }

        var newSchedule: [Habit.Hour] = habit.schedule

        // REMOVE NOTIFICATIONS FROM SCHEDULE THAT WERE DELETED
        self.removeNotifications(newSchedule: habit.schedule, oldSchedule: oldHabit.schedule)

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
