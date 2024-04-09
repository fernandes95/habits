//
//  HabitsService.swift
//  Habits
//
//  Created by Tiago Fernandes on 09/04/2024.
//

import Foundation
import EventKit

class HabitsService {
    private let storeService: DefaultStoreService = DefaultStoreService()
    private let eventKitService: EventKitService = EventKitService()
    private let notificationService: NotificationService = NotificationService()

    private func load() async throws -> StoreEntity {
        return try await storeService.load()
    }

    func getHabits() async throws -> [HabitEntity] {
        let store: StoreEntity = try await load()
        return store.habits
    }

    func getHabits(date: Date) async throws -> [Habit] {
        let habits: [HabitEntity] = try await getHabits()
        let habitsFilterted = habits
            .filter { ($0.startDate.startOfDay ... $0.endDate.endOfDay) ~= date }
            .map { habitEntity in
                let habit = Habit(habitEntity: habitEntity, selectedDate: date)
                return habit
            }

        return habitsFilterted
    }

    func getHabit(id: UUID) async throws -> HabitEntity? {
        let habits: [HabitEntity] = try await getHabits()
        return habits.first(where: { $0.id == id }) ?? nil
    }

    func addHabit(_ habit: Habit) async throws {
        var eventId: String = ""
        var schedule: [Habit.Hour] = habit.schedule
        var location: HabitEntity.Location?

        if habit.schedule.isEmpty {
            eventId = try await eventKitService.createCalendarEvent(habit)
        } else {
            schedule = try await eventKitService.createScheduleCalendarEvents(habit)
        }

        if habit.location != nil {
            location = HabitEntity.Location(
                latitude: habit.location!.latitude,
                longitude: habit.location!.longitude
            )
        }

        var store: StoreEntity = try await load()
        store.habits.append(
            HabitEntity(
                eventId: eventId,
                name: habit.name,
                startDate: habit.startDate,
                endDate: habit.endDate,
                frequency: habit.frequency.rawValue,
                frequencyType: habit.frequencyType,
                category: habit.category.rawValue,
                schedule: schedule.map { hour in
                    return HabitEntity.Hour(
                        date: hour.date,
                        eventId: hour.eventId,
                        notificationId: hour.notificationId
                    )
                },
                hasAlarm: habit.hasAlarm,
                hasLocationReminder: habit.hasLocationReminder,
                location: location
            )
        )

        try await storeService.save(store)
    }

    func updateHabit(_ habit: Habit, selectedDate: Date) async throws {
        var store: StoreEntity = try await load()
        if let index: Int = store.habits.firstIndex(where: { $0.id == habit.id}) {
            let oldHabit: Habit = Habit(habitEntity: store.habits[index])
            let eventsHabit: Habit = try await manageUpdateEvents(habit: habit, oldHabit: oldHabit)
            var updatedHabit: HabitEntity = store.habits[index].with(
                eventId: eventsHabit.eventId,
                name: eventsHabit.name,
                endDate: eventsHabit.endDate,
                frequency: eventsHabit.frequency.rawValue,
                frequencyType: eventsHabit.frequencyType,
                category: eventsHabit.category.rawValue,
                schedule: eventsHabit.schedule.map { hour in
                    return HabitEntity.Hour(
                        date: hour.date,
                        eventId: hour.eventId,
                        notificationId: hour.notificationId
                    )
                },
                hasAlarm: eventsHabit.hasAlarm,
                hasLocationReminder: eventsHabit.hasLocationReminder,
                location: eventsHabit.hasLocationReminder && eventsHabit.location != nil
                ? HabitEntity.Location(
                    latitude: eventsHabit.location!.latitude,
                    longitude: eventsHabit.location!.longitude
                    )
                : nil
            )

            if let statusIndex: Int = updatedHabit.statusList.firstIndex(where: {
                $0.date.startOfDay == selectedDate.startOfDay
            }) {
                var status = updatedHabit.statusList[statusIndex]
                status.isChecked = habit.isChecked
                status.updatedDate = Date.now

                updatedHabit.statusList[statusIndex] = status
            } else {
                let status = HabitEntity.Status(
                    date: selectedDate,
                    isChecked: habit.isChecked
                )
                updatedHabit.statusList.append(status)
            }

            updatedHabit.successRate = updatedHabit.getSuccessRate()

            store.habits[index] = updatedHabit
        }

        try await storeService.save(store)
    }

    private func manageUpdateEvents(habit: Habit, oldHabit: Habit) async throws -> Habit {
        var habitUpdated: Habit = habit
        habitUpdated.schedule = try await eventKitService.manageScheduleEvents(habit, oldHabit: oldHabit)

        if habitUpdated.eventId.isEmpty && habitUpdated.schedule.isEmpty {
            let eventId: String = try await eventKitService.createCalendarEvent(habitUpdated)
            habitUpdated.eventId = eventId
        } else if !habitUpdated.eventId.isEmpty && !habitUpdated.schedule.isEmpty && oldHabit.schedule.isEmpty {
            eventKitService.deleteEventById(eventId: habitUpdated.eventId)
            habitUpdated.eventId = ""
        } else {
            eventKitService.editEvent(habitUpdated)
        }

        return habitUpdated
    }

    func removeHabit(habitId: UUID) async throws {
        var store: StoreEntity = try await load()
        if let index: Int = store.habits.firstIndex(where: { $0.id == habitId }) {
            let deleteHabit: HabitEntity = store.habits[index]

            store.habitsArchived.append(deleteHabit)
            store.habits.remove(at: index)

            if deleteHabit.schedule.isEmpty {
                eventKitService.deleteEventById(eventId: deleteHabit.eventId)
            } else {
                for hour in deleteHabit.schedule {
                    eventKitService.deleteEventById(eventId: hour.eventId)
                    notificationService.removePendingNotification(identifer: hour.notificationId)
                }
            }

            try await storeService.save(store)
        }
    }

    private func getDailyHabits(date: Date, existingHabits: [Habit]?) async throws -> [Habit] {
        guard let habits: [Habit] = existingHabits != nil
                ? existingHabits
                : try await getHabits(date: date)
        else {
            return []
        }

        return habits.filter { $0.frequency == .daily }
    }

    private func getWeeklyHabits(date: Date, existingHabits: [Habit]?) async throws -> [Habit] {
        guard let habits: [Habit] = existingHabits != nil
                ? existingHabits
                : try await getHabits(date: date)
        else {
            return []
        }

        return habits.filter { $0.frequency == .weekly }
            .compactMap { habit in
                let weekDayRaw: Int = Calendar.current.component(.weekday, from: date)
                guard let ekWeekday: EKWeekday = EKWeekday(rawValue: weekDayRaw) else { return nil }
                let weekday: WeekDay = getWeekDay(ekWeekday: ekWeekday)

                return if habit.frequencyType.weekFrequency.contains(weekday) {
                    habit
                } else {
                    nil
                }
            }
    }

    func loadUncheckedHabits(date: Date) async throws -> [Habit] {
        let habits = try await getHabits(date: date)
        let habitsDaily: [Habit] = try await getDailyHabits(date: date, existingHabits: habits)
        let habitsWeekly: [Habit] = try await getWeeklyHabits(date: date, existingHabits: habits)

        let uncheckedDailyList: [Habit]  = habitsDaily
            .filter { !$0.isChecked }
        let uncheckedWeeklyList: [Habit]  = habitsWeekly
            .filter { !$0.isChecked }

        let uncheckedList: [Habit] = uncheckedDailyList + uncheckedWeeklyList

        return uncheckedList
    }

    func loadCheckedHabits(date: Date) async throws -> [Habit] {
        let habits = try await getHabits(date: date)
        let habitsDaily: [Habit] = try await getDailyHabits(date: date, existingHabits: habits)
        let habitsWeekly: [Habit] = try await getWeeklyHabits(date: date, existingHabits: habits)

        let checkedDailyList: [Habit]  = habitsDaily
          .filter { $0.isChecked }
          .sorted { (lhs: Habit, rhs: Habit) in
              return (lhs.updatedDate < rhs.updatedDate)
          }
        let checkedWeeklyList: [Habit]  = habitsWeekly
          .filter { $0.isChecked }
          .sorted { (lhs: Habit, rhs: Habit) in
              return (lhs.updatedDate < rhs.updatedDate)
          }

        let checkedList: [Habit]  = checkedDailyList + checkedWeeklyList

        return checkedList
    }
}
