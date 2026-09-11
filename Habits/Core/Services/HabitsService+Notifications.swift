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
}
