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
    private let calendarService: CalendarService = CalendarService()
    private let notificationService: NotificationService = NotificationService()

    private var store: StoreEntity = StoreEntity(habits: [], habitsArchived: [])
    private var habits: [HabitEntity] {
        return store.habits
    }

    init() {
        Task {
            try await load()
        }
    }

    private func load() async throws {
        self.store = try await storeService.load()
    }

    private func save() async throws {
        try await storeService.save(self.store)
        try await self.load()
    }

    func getHabits(date: Date) async throws -> [Habit] {
        let habitsFilterted = self.habits
            .filter { ($0.startDate.startOfDay ... $0.endDate.endOfDay) ~= date }
            .map { habitEntity in
                let habit = Habit(habitEntity: habitEntity, selectedDate: date)
                return habit
            }

        return habitsFilterted
    }

    func getHabit(id: UUID) async throws -> HabitEntity? {
        return self.habits.first(where: { $0.id == id }) ?? nil
    }

    func getHabit(id: String) async throws -> HabitEntity? {
        return self.habits.first(where: { $0.id.uuidString == id }) ?? nil
    }

    func addHabit(_ habit: Habit) async throws -> UUID {
        var eventId: String = ""
        var schedule: [Habit.Hour] = habit.schedule
        var location: HabitEntity.Location?

        if habit.schedule.isEmpty {
            eventId = try await calendarService.createCalendarEvent(habit)
        } else {
            schedule = try await calendarService.createScheduleCalendarEvents(habit)
        }

        if habit.location != nil {
            location = HabitEntity.Location(
                latitude: habit.location!.latitude,
                longitude: habit.location!.longitude
            )
        }

        let newHabit: HabitEntity = HabitEntity(
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

        self.store.habits.append(newHabit)
        try await self.save()

        return newHabit.id
    }

    func updateHabit(_ habit: Habit, selectedDate: Date) async throws {
        if let index: Int = self.store.habits.firstIndex(where: { $0.id == habit.id}) {
            let oldHabit: Habit = Habit(habitEntity: self.habits[index])
            let eventsHabit: Habit = try await manageUpdateEvents(habit: habit, oldHabit: oldHabit)
            var updatedHabit: HabitEntity = self.habits[index].with(
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

            self.store.habits[index] = updatedHabit
        }

        try await self.save()
    }

    private func manageUpdateEvents(habit: Habit, oldHabit: Habit) async throws -> Habit {
        var habitUpdated: Habit = habit
        habitUpdated.schedule = try await calendarService.manageScheduleEvents(habit, oldHabit: oldHabit)

        if habitUpdated.eventId.isEmpty && habitUpdated.schedule.isEmpty {
            let eventId: String = try await calendarService.createCalendarEvent(habitUpdated)
            habitUpdated.eventId = eventId
        } else if !habitUpdated.eventId.isEmpty && !habitUpdated.schedule.isEmpty && oldHabit.schedule.isEmpty {
            calendarService.deleteEventById(eventId: habitUpdated.eventId)
            habitUpdated.eventId = ""
        } else {
            calendarService.editEvent(habitUpdated)
        }

        return habitUpdated
    }

    func removeHabit(habitId: UUID) async throws {
        if let index: Int = self.habits.firstIndex(where: { $0.id == habitId }) {
            let deleteHabit: HabitEntity = self.habits[index]

            self.store.habitsArchived.append(deleteHabit)
            self.store.habits.remove(at: index)

            if deleteHabit.schedule.isEmpty {
                calendarService.deleteEventById(eventId: deleteHabit.eventId)
            } else {
                for hour in deleteHabit.schedule {
                    calendarService.deleteEventById(eventId: hour.eventId)
                    notificationService.removePendingNotification(identifer: hour.notificationId)
                }
            }

            try await self.save()
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

                return if habit.startDate.startOfDay == date.startOfDay ||
                        habit.frequencyType.weekFrequency.contains(weekday) {
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

    func getHabitsByDistance(currentLocation: CLLocation, maxHabits: Int = 20) async throws -> ([Habit], Double) {
        var distanceFromClosest: Double = 200

        guard let habits: [Habit] = try? await loadUncheckedHabits(date: Date.now) else {
            return ([], distanceFromClosest)
        }

        let habitsByDistance: [Habit] = habits
            .filter({ $0.location != nil })
            .sorted { (lhs: Habit, rhs: Habit) in
                let lhsLocation: CLLocation = CLLocation(
                    latitude: lhs.location!.latitude,
                    longitude: lhs.location!.longitude
                )
                let rhsLocation: CLLocation = CLLocation(
                    latitude: rhs.location!.latitude,
                    longitude: rhs.location!.longitude
                )

                return currentLocation.distance(from: lhsLocation) < currentLocation.distance(from: rhsLocation)
            }

        if let closestHabit: Habit = habitsByDistance.first {
            let closestHabitLocation: CLLocation = CLLocation(
                latitude: closestHabit.location!.latitude,
                longitude: closestHabit.location!.longitude
            )

            distanceFromClosest = currentLocation.distance(from: closestHabitLocation)
        }

        // DEBUG LOGS
        print("\n **** Habits by Distance ****")
        print(" **** Limit Lenght: \(maxHabits) ****")
        print(" **** Count: \(habits.count) **** \n")
        for habit in Array(habitsByDistance.prefix(maxHabits)) {
            let closestLocation: CLLocation = CLLocation(
                latitude: habit.location!.latitude,
                longitude: habit.location!.longitude
            )
            let distance = currentLocation.distance(from: closestLocation)

            print("● Name: \(habit.name), Distance: \(distance)")
        }
        print("\n **** End of Habits by Distance ****")
        // END OF DEBUG LOGS

        let habitsToReturn: [Habit] = maxHabits == 0 ? (habitsByDistance) : Array(habitsByDistance.prefix(maxHabits))

        return (habitsToReturn, distanceFromClosest)
    }
}
