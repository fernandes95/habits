//
//  MainState.swift
//  Habits
//
//  Created by Tiago Fernandes on 26/02/2024.
//

import Foundation
import SwiftUI

@MainActor
class MainState: ObservableObject {

    @Published
    var habits: [Habit] = []

    @Published
    var selectedDate: Date = Date.now
    private let storeService = DefaultStoreService()
    private let eventKitService = EventKitService()

    private func load() async throws -> StoreEntity {
        return try await storeService.load()
    }

    func loadHabits(date: Date) async throws {
        self.habits = []
        self.selectedDate = date
        let store: StoreEntity = try await load()
        let habits: [Habit] = store.habits
            .filter { ($0.startDate.startOfDay ... $0.endDate.endOfDay) ~= date }
            .map { habitEntity in
                let habit = Habit(habitEntity: habitEntity, selectedDate: selectedDate)
                return habit
            }

        let habitsDaily: [Habit] = habits.filter { $0.frequency == .daily}
        let habitsWeekly: [Habit] = habits
            .filter { $0.frequency == .weekly }
            .compactMap { habit in
                let daysDiff = DateHelper.numberOfDaysBetween(habit.startDate, and: self.selectedDate)

                return if (daysDiff % 7) == 0 {
                    habit
                } else {
                    nil
                }
            }

        let uncheckedDailyList = habitsDaily
            .filter { !$0.isChecked }
        let uncheckedWeeklyList = habitsWeekly
            .filter { !$0.isChecked }

        let uncheckedList = uncheckedDailyList + uncheckedWeeklyList

        let checkedDailyList = habitsDaily
          .filter { $0.isChecked }
          .sorted { (lhs: Habit, rhs: Habit) in
              return (lhs.updatedDate < rhs.updatedDate)
          }
        let checkedWeeklyList = habitsWeekly
          .filter { $0.isChecked }
          .sorted { (lhs: Habit, rhs: Habit) in
              return (lhs.updatedDate < rhs.updatedDate)
          }

        let checkedList = checkedDailyList + checkedWeeklyList

        self.habits = uncheckedList + checkedList
    }

    func getHabit(habit: Habit) async throws -> Habit {
        let store: StoreEntity = try await load()
        if let habitEntity = store.habits.first(where: { $0.id == habit.id }) {
            return Habit(habitEntity: habitEntity, selectedDate: Date.now)
        } else {
            return habit
        }
    }

    func updateHabit(habit: Habit) async throws {
        do {
            var store: StoreEntity = try await load()
            if let index = store.habits.firstIndex(where: { $0.id == habit.id}) {
                let oldHabit = Habit(habitEntity: store.habits[index])
                let eventsHabit = try await manageUpdateEvents(habit: habit, oldHabit: oldHabit)
                var updatedHabit: HabitEntity = store.habits[index].with(
                    eventId: eventsHabit.eventId,
                    name: eventsHabit.name,
                    endDate: eventsHabit.endDate,
                    category: eventsHabit.category.rawValue,
                    schedule: eventsHabit.schedule.map { hour in
                        return HabitEntity.Hour(date: hour.date, eventId: hour.eventId)
                    }
                )

                if let statusIndex = updatedHabit.statusList.firstIndex(where: {
                    $0.date.startOfDay == self.selectedDate.startOfDay
                }) {
                    var status = updatedHabit.statusList[statusIndex]
                    status.isChecked = habit.isChecked
                    status.updatedDate = Date.now

                    updatedHabit.statusList[statusIndex] = status
                } else {
                    let status = HabitEntity.Status(
                        date: self.selectedDate,
                        isChecked: habit.isChecked
                    )
                    updatedHabit.statusList.append(status)
                }

                updatedHabit.successRate = updatedHabit.getSuccessRate()

                store.habits[index] = updatedHabit
            }

            try await storeService.save(store)
            try await loadHabits(date: self.selectedDate)
        } catch { }
    }

    private func manageUpdateEvents(habit: Habit, oldHabit: Habit) async throws -> Habit {
        var habitUpdated = habit
        habitUpdated.schedule = try await eventKitService.manageScheduleEvents(habit, oldHabit: oldHabit)

        if habitUpdated.eventId.isEmpty && habitUpdated.schedule.isEmpty {
            let eventId = try await eventKitService.createCalendarEvent(habitUpdated)
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
        do {
            var store: StoreEntity = try await load()
            if let index = store.habits.firstIndex(where: { $0.id == habitId }) {
                let deleteHabit = store.habits[index]

                store.habitsArchived.append(deleteHabit)
                store.habits.remove(at: index)

                if deleteHabit.schedule.isEmpty {
                    eventKitService.deleteEventById(eventId: deleteHabit.eventId)
                } else {
                    for hour in deleteHabit.schedule {
                        eventKitService.deleteEventById(eventId: hour.eventId)
                    }
                }

                try await storeService.save(store)
                try await loadHabits(date: self.selectedDate)
            }
        } catch {}
    }

    func addHabit(_ habit: Habit) async throws {
        do {
            var eventId: String = ""
            var schedule: [Habit.Hour] = habit.schedule

            if habit.schedule.isEmpty {
                eventId = try await eventKitService.createCalendarEvent(habit)
            } else {
                schedule = try await eventKitService.createScheduleCalendarEvents(habit)
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
                        return HabitEntity.Hour(date: hour.date, eventId: hour.eventId)
                    }
                )
            )

            try await storeService.save(store)
            try await loadHabits(date: self.selectedDate)
        } catch { }
    }
}
