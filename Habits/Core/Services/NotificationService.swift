//
//  NotificationService.swift
//  Habits
//
//  Created by Tiago Fernandes on 24/03/2024.
//

import Foundation
import UserNotifications

struct NotificationService {
    private let notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()

    func sendNotification(subTitle: String, date: Date, identifier: String? = nil) async throws {
        let notificationContent = UNMutableNotificationContent()
        let requestIndentifer = identifier ?? UUID().uuidString
        let dateComponents = Calendar.current.dateComponents(
            [.day, .month, .year, .hour, .minute],
            from: date
        )

        notificationContent.title = "Habits"
        notificationContent.subtitle = subTitle
        notificationContent.sound = UNNotificationSound.default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: requestIndentifer,
            content: notificationContent,
            trigger: trigger
        )

        // TODO: MANAGE ERRORS IN THE FUTURE
        try await notificationCenter.add(request)
    }
}
