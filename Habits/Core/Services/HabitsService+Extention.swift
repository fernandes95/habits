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
            scheduleInterval: eventsHabit.scheduleInterval,
            schedule: eventsHabit.schedule.map { hour in
                return Hour(
                    eventId: hour.eventId,
                    notificationId: hour.notificationId,
                    date: hour.date
                )
            },
            hasAlarm: eventsHabit.hasAlarm,
            hasLocationReminder: eventsHabit.hasLocationReminder,
            location: eventsHabit.location != nil
            ? HabitEntity.Location(
                latitude: eventsHabit.location!.latitude,
                longitude: eventsHabit.location!.longitude
                )
            : nil
        )

        /// Statuses saved before `requiredCount` existed have no target. Stamp the previous target
        /// on them while it's still known, so the history keeps its colors after a type/target change.
        if oldHabit.frequency == .minTimes {
            let previousTarget: Int = oldHabit.frequencyType.minimumTimes
            for statusIndex in updatedHabit.statusList.indices
            where updatedHabit.statusList[statusIndex].requiredCount == nil {
                updatedHabit.statusList[statusIndex].requiredCount = previousTarget
            }
        }

        return updatedHabit
    }

    /// If status exists updates based on `habit` else will create new status based on `habit`
    internal func updateStatus(of habitEntity: inout HabitEntity, with habit: Habit, selectedDate: Date) {
        let statusIndex: Int? = habitEntity.statusList.firstIndex(where: {
            $0.date.startOfDay == selectedDate.startOfDay
        })
        var status: HabitEntity.Status = statusIndex.map { habitEntity.statusList[$0] }
            ?? HabitEntity.Status(date: selectedDate)

        if habit.frequency == .minTimes {
            if status.isChecked {
                status.count = 0
                status.isChecked = false
            } else {
                status.count += 1
                status.isChecked = status.count == habit.frequencyType.minimumTimes
            }
            status.requiredCount = habit.frequencyType.minimumTimes
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

    internal func manageUpdateEvents(habit: Habit, oldHabit: Habit) async throws -> Habit {
        var habitUpdated: Habit = habit

        if habit.schedule.count > 0 || oldHabit.schedule.count > 0 {
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
        }

        return habitUpdated
    }
}
