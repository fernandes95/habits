//
//  HabitsService+Notifications.swift
//  Habits
//
//  Created by Tiago Fernandes on 20/09/2025.
//

import Foundation

extension HabitsService {
    func verifyHabitWasNotified(habitId: UUID) async throws -> Bool {
        return try await self.storeService.didNotifyHabit(id: habitId)
    }

    func notifiedHabit(habitId: UUID) async throws {
        try await storeService.appendNotifiedHabit(
            HabitNotificationEntity(habitId: habitId, date: .now)
        )

        // local storing //TODO check if this is really needed on further development
        self.store.habitsNotified.append(
            HabitNotificationEntity(habitId: habitId, date: .now)
        )
    }

    /// Days ahead reminders are scheduled for, the list is refreshed every time the habits are loaded
    static let reminderDays: Int = 7

    /// iOS keeps at most 64 pending notifications, a few are left for the location reminders
    static let maxReminders: Int = 60

    /// Schedules the reminders of the next `reminderDays` days, every older pending reminder is replaced.
    /// Hours already passed or done, and days the habit is already done, get no reminder.
    ///
    /// - Parameter now: Current date, reminders before it are skipped
    func syncReminders(now: Date = .now) async throws {
        let status = await self.notificationService.getNotificationStatus()
        guard [.authorized, .provisional, .ephemeral].contains(status) else { return }

        let days: [Date] = (0..<Self.reminderDays).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: now.startOfDay)
        }
        let habitsByDay: [Date: [Habit]] = try await self.loadHabits(days: days)

        var reminders: [NotificationService.Reminder] = []
        for day in days {
            for habit in habitsByDay[day] ?? [] where !habit.isChecked {
                // An hour done before its time doesn't remind anymore
                for hour in habit.reminderHours where habit.checkedHours[hour.id] == nil {
                    guard let date = hour.date(on: day), date > now else { continue }
                    reminders.append(
                        NotificationService.Reminder(habitId: habit.id, hourId: hour.id, title: habit.name, date: date)
                    )
                }
            }
        }

        let nextReminders = reminders
            .sorted { $0.date < $1.date }
            .prefix(Self.maxReminders)
        await self.notificationService.replaceReminders(Array(nextReminders))
    }
}
