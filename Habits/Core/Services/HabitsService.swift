//
//  HabitsService.swift
//  Habits
//
//  Created by Tiago Fernandes on 09/04/2024.
//

import Foundation
import EventKit

class HabitsService {
    internal let storeService: DefaultStoreService
    internal let calendarService: CalendarService = CalendarService()
    internal let notificationService: NotificationService = NotificationService()
    private var didLoad = false

    internal var store: StoreEntity = StoreEntity(
        habits: [], habitsArchived: [],
        habitsNotified: [], appConfigs: AppConfig.empty
    )

    internal var habits: [HabitEntity] {
        return store.habits
    }

    internal var appConfigs: AppConfig {
        return store.appConfigs
    }

    /// - Parameter storeService: Where the habits are saved, the app's data file by default
    init(storeService: DefaultStoreService = DefaultStoreService()) {
        self.storeService = storeService
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
    /// - Parameter hasFilterLocation: Filters only habits with location and the location reminder on
    /// - Returns: Array of Habits
    func getHabits(date: Date, hasFilterLocation: Bool = false) async throws -> [Habit] {
        let habitsFilterted = self.habits
            .filter { ($0.startDate.startOfDay ... $0.endDate.endOfDay) ~= date }
            .filter {
                if hasFilterLocation {
                    return $0.location != nil && $0.hasLocationReminder
                } else {
                    return true
                }
            }
            .map { habitEntity in
                let habit = Habit(habitEntity: habitEntity, selectedDate: date)
                return habit
            }

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
        let eventId: String = ""
        let schedule: [Hour] = habit.schedule
        let location: HabitEntity.Location? = habit.location?.entity

        // Won't use this feature for now
        /*if habit.schedule.isEmpty {
            eventId = try await calendarService.createCalendarEvent(habit)
        } else {
            schedule = try await calendarService.createScheduleCalendarEvents(habit)
        }*/

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
            scheduleInterval: habit.scheduleInterval,
            goal: habit.goal
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
        let eventId: String = ""
        let schedule: [Hour] = habit.schedule

        // Won't use this feature for now
        /*if habit.schedule.isEmpty {
            eventId = try await calendarService.createCalendarEvent(habit)
        } else {
            schedule = try await calendarService.createScheduleCalendarEvents(habit)
        }*/

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

    /// Removes the last step of a habit with a goal on `selectedDate`, a done habit isn't done anymore.
    /// Used from the reset dialog of the habits list.
    ///
    /// - Parameters:
    ///   - habit: Habit to update
    ///   - selectedDate: Day of the status to change
    func undoLastStep(_ habit: Habit, selectedDate: Date) async throws {
        try await self.changeStatus(of: habit, on: selectedDate) { status in
            // Older statuses were saved without a target, fall back to the current one.
            let required: Int? = status.requiredCount ?? habit.goal?.value
            status.count = max(status.count - 1, 0)
            status.isChecked = required.map { status.count >= $0 } ?? false
        }
    }

    /// Clears the progress of a habit on `selectedDate`, every other day is left untouched.
    /// Used from the reset dialog of the habits list.
    ///
    /// - Parameters:
    ///   - habit: Habit to update
    ///   - selectedDate: Day of the status to change
    func resetProgress(_ habit: Habit, selectedDate: Date) async throws {
        try await self.changeStatus(of: habit, on: selectedDate) { status in
            status.count = 0
            status.isChecked = false
        }
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

    /// Transfers Habit to Habits Archived list and deletes all calendar events related to the habit.
    /// Its reminders go away on the next `syncReminders`
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
                }
            }

            try await self.save()
        }
    }

    /// Get Habits with frequency type .daily and .minDays.
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
            $0.frequency == .minDays
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
                let weekday = WeekDay(date: date)

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
