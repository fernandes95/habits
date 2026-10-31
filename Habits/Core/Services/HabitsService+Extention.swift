//
//  HabitsService+Extention.swift
//  Habits
//
//  Created by Tiago Fernandes on 10/10/2026.
//

import Foundation

extension HabitsService {
    /// Copies the settings of `habit` into the stored entity at `index` and syncs calendar events.
    internal func applySettings(of habit: Habit, at index: Int) async throws -> HabitEntity {
        let oldHabit: Habit = Habit(habitEntity: self.habits[index])
        let eventsHabit: Habit = try await manageUpdateEvents(habit: habit, oldHabit: oldHabit)
        var updatedHabit: HabitEntity = self.habits[index].with(
            eventId: eventsHabit.eventId,
            name: eventsHabit.name,
            endDate: eventsHabit.endDate,
            hasNoEndDate: eventsHabit.hasNoEndDate,
            frequency: eventsHabit.frequency.rawValue,
            frequencyType: eventsHabit.frequencyType,
            category: eventsHabit.category.rawValue,
            schedule: eventsHabit.schedule.map { hour in
                // Same id, so the hour keeps its reminders and day statuses
                return Hour(
                    id: hour.id,
                    eventId: hour.eventId,
                    notificationId: hour.notificationId,
                    date: hour.date
                )
            },
            hasAlarm: eventsHabit.hasAlarm,
            hasLocationReminder: eventsHabit.hasLocationReminder
        )

        /// Making sure the values are overridden
        updatedHabit.scheduleInterval = eventsHabit.scheduleInterval
        updatedHabit.location = eventsHabit.location?.entity
        updatedHabit.goal = eventsHabit.goal

        /// Statuses saved before `requiredCount` existed have no target. Stamp the previous target
        /// on them while it's still known, so the history keeps its colors after a type/target change.
        if let previousTarget: Int = oldHabit.goal?.value {
            for statusIndex in updatedHabit.statusList.indices
            where updatedHabit.statusList[statusIndex].requiredCount == nil {
                updatedHabit.statusList[statusIndex].requiredCount = previousTarget
            }
        }

        self.refreshHourStatuses(of: &updatedHabit)

        return updatedHabit
    }

    /// Hours added or removed change which days are done. From today on, every day with done hours
    /// drops the hours that were removed and is checked only when every current hour is done.
    /// Past days keep their history.
    internal func refreshHourStatuses(of habitEntity: inout HabitEntity, now: Date = .now) {
        let habit: Habit = Habit(habitEntity: habitEntity)
        let hourIds: Set<UUID> = Set(habit.reminderHours.map(\.id))
        guard !hourIds.isEmpty else { return }

        for statusIndex in habitEntity.statusList.indices
        where habitEntity.statusList[statusIndex].date.startOfDay >= now.startOfDay {
            var status: HabitEntity.Status = habitEntity.statusList[statusIndex]
            guard var hours = status.hours else { continue }

            hours.removeAll { !hourIds.contains($0.hourId) }
            let isChecked: Bool = hourIds.isSubset(of: Set(hours.map(\.hourId)))
            // A done day keeps the last hour's steps, a day still going starts the next hour from zero
            if let goal = habit.goal, isChecked != status.isChecked {
                status.count = isChecked ? goal.value : 0
            }

            status.hours = hours
            status.isChecked = isChecked
            habitEntity.statusList[statusIndex] = status
        }
    }

    /// If status exists updates based on `habit` else will create new status based on `habit`
    internal func updateStatus(of habitEntity: inout HabitEntity, with habit: Habit, selectedDate: Date) {
        let statusIndex: Int? = habitEntity.statusList.firstIndex(where: {
            $0.date.startOfDay == selectedDate.startOfDay
        })
        var status: HabitEntity.Status = statusIndex.map { habitEntity.statusList[$0] }
            ?? HabitEntity.Status(date: selectedDate)

        // Habits with a goal are checked once they're done `goal.value` times in the day
        if let goal = habit.goal {
            if status.isChecked {
                status.count = 0
                status.isChecked = false
            } else {
                status.count += 1
                status.isChecked = status.count == goal.value
            }
            status.requiredCount = goal.value
        } else {
            status.isChecked = habit.isChecked
        }
        status.updatedDate = .now

        if let statusIndex {
            habitEntity.statusList[statusIndex] = status
        } else {
            habitEntity.statusList.append(status)
        }
    }

    /// Does one reminder hour of `habit` on `selectedDate`.
    /// Without a goal the hour is done with one tap. With a goal each tap is a step, the hour is done
    /// once the goal is reached and the steps start again for the next hour.
    /// The habit is checked once every reminder hour is done. An hour already done stays as it is,
    /// so a quick second tap aimed at the same hour never undoes it.
    ///
    /// - Parameters:
    ///   - habit: Habit with reminder hours
    ///   - hourId: Hour to do
    ///   - selectedDate: Day of the status to change
    func checkHour(_ habit: Habit, hourId: UUID, selectedDate: Date) async throws {
        try await self.changeHours(of: habit, on: selectedDate) { status, hours, hourIds, goal in
            guard hourIds.contains(hourId), !hours.contains(where: { $0.hourId == hourId }) else { return }

            var isHourDone = true
            if let goal {
                status.count += 1
                status.requiredCount = goal.value
                isHourDone = status.count >= goal.value
            }

            if isHourDone {
                hours.append(HabitEntity.HourCheck(hourId: hourId, date: .now))
                status.isChecked = hourIds.isSubset(of: Set(hours.map(\.hourId)))
                // Steps start again for the next hour, the last hour keeps them so the day shows the goal reached
                if !status.isChecked { status.count = 0 }
            }
        }
    }

    /// Undoes one done reminder hour of `habit` on `selectedDate`, the habit isn't checked anymore.
    /// An hour that isn't done stays as it is, so a repeated undo never does it again.
    ///
    /// - Parameters:
    ///   - habit: Habit with reminder hours
    ///   - hourId: Hour to undo
    ///   - selectedDate: Day of the status to change
    func uncheckHour(_ habit: Habit, hourId: UUID, selectedDate: Date) async throws {
        try await self.changeHours(of: habit, on: selectedDate) { status, hours, _, goal in
            guard let doneIndex = hours.firstIndex(where: { $0.hourId == hourId }) else { return }

            hours.remove(at: doneIndex)
            // The steps of a done day belong to its last hour
            if status.isChecked && goal != nil { status.count = 0 }
            status.isChecked = false
        }
    }

    /// Applies `change` to the status and done hours of `habit` on `date` and saves it,
    /// the status is created when the day has none.
    /// `change` gets the ids of the current reminder hours and the goal of the stored habit
    private func changeHours(
        of habit: Habit,
        on date: Date,
        _ change: (inout HabitEntity.Status, inout [HabitEntity.HourCheck], Set<UUID>, Goal?) -> Void
    ) async throws {
        guard let index: Int = self.store.habits.firstIndex(where: { $0.id == habit.id }) else { return }

        var habitEntity: HabitEntity = self.store.habits[index]
        let storedHabit: Habit = Habit(habitEntity: habitEntity)
        let hourIds: Set<UUID> = Set(storedHabit.reminderHours.map(\.id))
        let statusIndex: Int? = habitEntity.statusList.firstIndex(where: {
            $0.date.startOfDay == date.startOfDay
        })
        var status: HabitEntity.Status = statusIndex.map { habitEntity.statusList[$0] }
            ?? HabitEntity.Status(date: date)

        // Days checked before hours could be done count every hour as done
        var hours: [HabitEntity.HourCheck] = status.hours
            ?? (status.isChecked ? hourIds.map { HabitEntity.HourCheck(hourId: $0, date: status.updatedDate) } : [])

        change(&status, &hours, hourIds, storedHabit.goal)

        status.hours = hours
        status.updatedDate = .now

        if let statusIndex {
            habitEntity.statusList[statusIndex] = status
        } else {
            habitEntity.statusList.append(status)
        }
        habitEntity.updatedDate = .now

        self.store.habits[index] = habitEntity
        try await self.save()
    }

    /// Applies `change` to the status of `habit` on `date` and saves it, nothing happens if the day has no status
    internal func changeStatus(
        of habit: Habit,
        on date: Date,
        _ change: (inout HabitEntity.Status) -> Void
    ) async throws {
        guard let index: Int = self.store.habits.firstIndex(where: { $0.id == habit.id }),
              let statusIndex: Int = self.store.habits[index].statusList.firstIndex(where: {
                  $0.date.startOfDay == date.startOfDay
              })
        else { return }

        change(&self.store.habits[index].statusList[statusIndex])
        self.store.habits[index].statusList[statusIndex].updatedDate = .now
        self.store.habits[index].updatedDate = .now
        try await self.save()
    }

    internal func manageUpdateEvents(habit: Habit, oldHabit: Habit) async throws -> Habit {
        var habitUpdated: Habit = habit

        // TODO REWIEW THIS
        /* if habit.schedule.count > 0 || oldHabit.schedule.count > 0 {
            habitUpdated.schedule = try await self.calendarService.manageScheduleEvents(habit, oldHabit: oldHabit)
        }

        if habitUpdated.eventId.isEmpty && habitUpdated.schedule.isEmpty {
            let eventId: String = try await self.calendarService.createCalendarEvent(habitUpdated)
            habitUpdated.eventId = eventId
        } else if !habitUpdated.eventId.isEmpty && !habitUpdated.schedule.isEmpty && oldHabit.schedule.isEmpty {
            self.calendarService.deleteEventById(eventId: habitUpdated.eventId)
            habitUpdated.eventId = ""
        } else {
            self.calendarService.editEvent(habitUpdated)
        }*/

        return habitUpdated
    }
}
