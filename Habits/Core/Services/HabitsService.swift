//
//  HabitsService.swift
//  Habits
//
//  Created by Tiago Fernandes on 09/04/2024.
//

import Foundation
import EventKit

// swiftlint:disable:next type_body_length
class HabitsService {
    internal let storeService: DefaultStoreService = DefaultStoreService()
    internal let calendarService: CalendarService = CalendarService()
    private let notificationService: NotificationService = NotificationService()
    private var didLoad = false

    internal var store: StoreEntity = StoreEntity(habits: [], habitsArchived: [], habitsNotified: [])
    internal var habits: [HabitEntity] {
        return store.habits
    }

    func loadIfNeeded() async throws {
        guard !self.didLoad else { return }
        try await self.load()
        self.didLoad = true
    }

    /// Gets store from local file
    internal func load() async throws {
        self.store = try await storeService.load()
    }

    /// Saves store into local file and then loads data from said file
    internal func save() async throws {
        try await storeService.save(self.store)
        try await self.load()
    }

    /// Gets Habit by selected date
    ///
    /// - Parameter date: Date to filter Habits
    /// - Parameter hasFilterLocation: Filters only habits with location
    /// - Returns: Array of Habits
    func getHabits(date: Date, hasFilterLocation: Bool = false) async throws -> [Habit] {
        let habitsFilterted = self.habits
            .filter { ($0.startDate.startOfDay ... $0.endDate.endOfDay) ~= date }
            .filter {
                if hasFilterLocation {
                    return $0.location != nil
                } else {
                    return true
                }
            }
            .map { habitEntity in
                let habit = Habit(habitEntity: habitEntity, selectedDate: date)
                return habit
            }

        print(self.habits.map { "\($0.name): \($0.startDate) → \($0.endDate), forever: \($0.hasNoEndDate)" })
        return habitsFilterted
    }

    /// Gets Habit Entity by UUID
    ///
    /// - Parameter id: UUID from Habit
    /// - Returns: Habit Entity if any else nil
    func getHabit(id: UUID) async throws -> HabitEntity? {
        return self.habits.first(where: { $0.id == id }) ?? nil
    }

    /// Gets Habit Entity by UUID as String
    ///
    /// - Parameter id: UUID as String from Habit
    /// - Returns: Habit Entity if any else nil
    func getHabit(id: String) async throws -> HabitEntity? {
        return self.habits.first(where: { $0.id.uuidString == id }) ?? nil
    }

    /// Gets Habit Entity by UUID as String directly from habits data file
    /// Only use if really needed
    ///
    /// - Parameter id: UUID as String from Habit
    /// - Returns: Habit Entity if any else nil
    func getHabitEntity(id: String) async throws -> HabitEntity? {
        return try await self.storeService.loadHabit(id: id)
    }

    /// Adds new Habit and creates calendar event/s if any
    ///
    /// - Parameter habit: Habit to add
    /// - Returns: New Habit UUID
    func addHabit(_ habit: Habit) async throws -> UUID {
        var eventId: String = ""
        var schedule: [Hour] = habit.schedule
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
            hasNoEndDate: habit.hasNoEndDate,
            frequency: habit.frequency.rawValue,
            frequencyType: habit.frequencyType,
            category: habit.category.rawValue,
            schedule: schedule.map { hour in
                return Hour(
                    eventId: hour.eventId,
                    notificationId: hour.notificationId,
                    date: hour.date
                )
            },
            hasAlarm: habit.hasAlarm,
            hasLocationReminder: habit.hasLocationReminder,
            location: location,
            scheduleInterval: habit.scheduleInterval
        )

        self.store.habits.append(newHabit)
        try await self.save()

        return newHabit.id
    }

    /// Adds new Habit from existing habit and creates calendar event/s if any
    ///
    /// - Parameter habitEntity: HabitEntity to add
    func addHabit(_ habitEntity: HabitEntity) async throws {
        let habit = Habit(habitEntity: habitEntity)
        var eventId: String = ""
        var schedule: [Hour] = habit.schedule

        if habit.schedule.isEmpty {
            eventId = try await calendarService.createCalendarEvent(habit)
        } else {
            schedule = try await calendarService.createScheduleCalendarEvents(habit)
        }

        let newHabit: HabitEntity = habitEntity.with(
            eventId: eventId,
            schedule: schedule.map { hour in
                return Hour(
                    eventId: hour.eventId,
                    notificationId: hour.notificationId,
                    date: hour.date
                )
            },
        )

        self.store.habits.append(newHabit)
        try await self.save()
    }

    /// Adds new Habits from existing habits list
    ///
    /// - Parameter habits: Habits to add
    func addHabits(_ habits: [HabitEntity]) async throws {
        for habit in habits {
            try await self.addHabit(habit)
        }
    }

    /// Updates existing Habit settings and toggles its status on `selectedDate`.
    /// Used when the user taps a habit in the list.
    ///
    /// - Parameters:
    ///   - habit: Habit to update
    ///   - selectedDate: Selected Date to update habit status
    func updateHabit(_ habit: Habit, selectedDate: Date) async throws {
        guard let index: Int = self.store.habits.firstIndex(where: { $0.id == habit.id }) else { return }

        var updatedHabit: HabitEntity = try await self.applySettings(of: habit, at: index)
        self.updateStatus(of: &updatedHabit, with: habit, selectedDate: selectedDate)
        updatedHabit.updatedDate = .now

        self.store.habits[index] = updatedHabit
        try await self.save()
    }

    /// Updates existing Habit settings only, the status of any day is left untouched.
    /// Used when the user edits a habit in the detail screen.
    ///
    /// - Parameter habit: Habit with the edited settings
    func editHabit(_ habit: Habit) async throws {
        guard let index: Int = self.store.habits.firstIndex(where: { $0.id == habit.id }) else { return }

        var updatedHabit: HabitEntity = try await self.applySettings(of: habit, at: index)
        updatedHabit.updatedDate = .now

        self.store.habits[index] = updatedHabit
        try await self.save()
    }

    /// Transfers Habit to Habits Archived list
    /// and deletes all calendar and notifications related to the habit
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

    /// Get Habits with frequency type .daily, .minTimes and .minDays.
    ///
    /// - Parameters:
    ///   - date: Selected Date to filter
    ///   - existingHabits: List of all habits
    /// - Returns: Array of Habits
    private func getDailyHabits(date: Date, existingHabits: [Habit]?) async throws -> [Habit] {
        guard let habits: [Habit] = existingHabits != nil
                ? existingHabits
                : try await getHabits(date: date)
        else {
            return []
        }

        return habits.filter {
            $0.frequency == .daily ||
            $0.frequency == .minDays ||
            $0.frequency == .minTimes
        }
    }

    /// Get Habits with frequency type .weekly
    ///
    /// - Parameters:
    ///   - date: Selected Date to filter
    ///   - existingHabits: List of all habits
    /// - Returns: Array of Habits
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

    /// Get Habits with frequency type .interval
    ///
    /// /// - Parameters:
    ///   - date: Selected Date to filter
    ///   - existingHabits: List of all habits
    /// - Returns: Array of Habits
    private func getIntervalHabits(date: Date, existingHabits: [Habit]?) async throws -> [Habit] {
        guard let habits: [Habit] = existingHabits != nil
                ? existingHabits
                : try await getHabits(date: date)
        else {
            return []
        }

        return habits.filter { habit in
            guard habit.frequency == .interval,
                  let interval = habit.scheduleInterval, interval > 0 else { return false }

            let daysSinceStart = DateHelper.numberOfDaysBetween(habit.startDate, and: date)
            return daysSinceStart >= 0 && daysSinceStart % interval == 0
        }
    }

    /// Get all checked habits from selected date
    /// - Parameter date: Selected date
    /// - Returns: Array of Habits
    func loadCheckedHabits(date: Date) async throws -> [Habit] {
        let habits = try await getHabits(date: date)
        let habitsDaily: [Habit] = try await getDailyHabits(date: date, existingHabits: habits)
        let habitsWeekly: [Habit] = try await getWeeklyHabits(date: date, existingHabits: habits)
        let habitsInterval: [Habit] = try await getIntervalHabits(date: date, existingHabits: habits)

        let checkedDailyList: [Habit] = habitsDaily
          .filter { $0.isChecked }
          .sorted { (lhs: Habit, rhs: Habit) in
              return (lhs.updatedDate < rhs.updatedDate)
          }
        let checkedWeeklyList: [Habit] = habitsWeekly
          .filter { $0.isChecked }
          .sorted { (lhs: Habit, rhs: Habit) in
              return (lhs.updatedDate < rhs.updatedDate)
          }
        let checkedIntervalList: [Habit] = habitsInterval
          .filter { $0.isChecked }
          .sorted { (lhs: Habit, rhs: Habit) in
              return (lhs.updatedDate < rhs.updatedDate)
          }

        let checkedList: [Habit] = checkedDailyList + checkedWeeklyList +
        checkedIntervalList

        return checkedList
    }

    /// Loads the habits of several days at once.
    ///
    /// - Parameter days: Days to load
    /// - Returns: Habits of each day keyed by start of day, unchecked first and then checked
    func loadHabits(days: [Date]) async throws -> [Date: [Habit]] {
        var result: [Date: [Habit]] = [:]

        for day in days.map(\.startOfDay) {
            let habits: [Habit] = try await getHabits(date: day)
            let habitsDaily: [Habit] = try await getDailyHabits(date: day, existingHabits: habits)
            let habitsWeekly: [Habit] = try await getWeeklyHabits(date: day, existingHabits: habits)
            let habitsInterval: [Habit] = try await getIntervalHabits(date: day, existingHabits: habits)
            let scheduled: [Habit] = habitsDaily + habitsWeekly + habitsInterval

            let unchecked: [Habit] = scheduled.filter { !$0.isChecked }
            let checked: [Habit] = scheduled
                .filter { $0.isChecked }
                .sorted { $0.updatedDate < $1.updatedDate }

            result[day] = unchecked + checked
        }

        return result
    }
}
