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

    /// Gets store from local file
    private func load() async throws {
        self.store = try await storeService.load()
    }

    /// Gets store from imported file
    func load(url: URL) async throws -> [HabitEntity] {
        var habitsToBeAdded: [HabitEntity] = []
        let importedStore: StoreEntity = try await storeService.load(url: url)

        var duplicatedHabits: [HabitEntity] = importedStore.habits.compactMap { habit in
            if self.store.habits.contains(where: { $0.id == habit.id }) {
                return habit
            } else if self.store.habits.contains(where: { $0.name == habit.name }) {
                return habit
            } else {
                habitsToBeAdded.append(habit)
                return nil
            }
        }

        for habit in duplicatedHabits {
            if let originalHabit: HabitEntity = self.store.habits
                .first(where: { $0.id == habit.id }) {
                if habit.name != originalHabit.name {
                    habitsToBeAdded.append(habit.clone())
                    if let index: Int = duplicatedHabits.firstIndex(where: { $0.id == habit.id }) {
                        duplicatedHabits.remove(at: index)
                    }
                }
            }
        }

        if duplicatedHabits.isEmpty && habitsToBeAdded.isEmpty {
            try await self.addHabits(importedStore.habits)
            return []
        } else {
            try await self.addHabits(habitsToBeAdded)
            // not using habitsArchived for now so doesn't matter if data is being overitten
            self.store.habitsArchived = store.habitsArchived
            return duplicatedHabits
        }
    }

    func manageDuplicates(habits: [HabitEntity], resolution: ConflictResolution) async throws {
        switch resolution {
        case .delete: return
        case .duplicate: try await self.duplicateHabits(habits)
        case .replace: try await self.replaceHabits(habits)
        }
    }

    private func duplicateHabits(_ habits: [HabitEntity]) async throws {
        var duplicatedHabits: [HabitEntity] = []
        for habit in habits {
            let habitClone = habit.clone()
            var count: Int = 2
            var name: String

            repeat {
                name = "\(habit.name) #\(count)"
                count += 1
            } while self.habits.contains(where: { $0.name == name })

            let newHabit = habitClone.with(name: name)
            duplicatedHabits.append(newHabit)
        }

        try await self.addHabits(duplicatedHabits)
    }

    private func replaceHabits(_ habits: [HabitEntity]) async throws {
        for habit in habits {
            if self.store.habits.contains(where: { $0.id == habit.id }) {
                try await self.removeHabit(habitId: habit.id)
                try await addHabit(habit)
            } else {
                return
            }
        }
    }

    /// Saves store into local file and then loads data from said file
    private func save() async throws {
        try await storeService.save(self.store)
        try await self.load()
    }

    /// Gets exportable document
    func getDocument() async -> ExportableDocument {
        var data: Data = Data()
        do {
            // Making sure latest data is saved
            try await storeService.save(self.store)
            data = try await storeService.loadAsData()
        } catch {}
        return ExportableDocument(data: data)
    }

    /// Gets Habit by selected date
    ///
    /// - Parameter date: Date to filter Habits
    /// - Returns: Array of Habits
    func getHabits(date: Date) async throws -> [Habit] {
        let habitsFilterted = self.habits
            .filter { ($0.startDate.startOfDay ... $0.endDate.endOfDay) ~= date }
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

    /// Adds new Habit and creates calendar event/s if any
    ///
    /// - Parameter habit: Habit to add
    /// - Returns: New Habit UUID
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
            hasNoEndDate: habit.hasNoEndDate,
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
        var schedule: [Habit.Hour] = habit.schedule

        if habit.schedule.isEmpty {
            eventId = try await calendarService.createCalendarEvent(habit)
        } else {
            schedule = try await calendarService.createScheduleCalendarEvents(habit)
        }

        let newHabit: HabitEntity = habitEntity.with(
            eventId: eventId,
            schedule: schedule.map { hour in
                return HabitEntity.Hour(
                    date: hour.date,
                    eventId: hour.eventId,
                    notificationId: hour.notificationId
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

    /// Updates existing Habit
    /// - Parameters:
    ///   - habit: Habit to update
    ///   - selectedDate: Selected Date to update habit status
    func updateHabit(_ habit: Habit, selectedDate: Date) async throws {
        if let index: Int = self.store.habits.firstIndex(where: { $0.id == habit.id}) {
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
                    return HabitEntity.Hour(
                        date: hour.date,
                        eventId: hour.eventId,
                        notificationId: hour.notificationId
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

            /// If status exists updates based on `habit` else will create new status based on `habit`
            if let statusIndex: Int = updatedHabit.statusList.firstIndex(where: {
                $0.date.startOfDay == selectedDate.startOfDay
            }) {
                var status = updatedHabit.statusList[statusIndex]
                status.isChecked = habit.isChecked
                status.updatedDate = .now

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

        if habit.schedule.count > 0 || oldHabit.schedule.count > 0 {
            habitUpdated.schedule = try await calendarService.manageScheduleEvents(habit, oldHabit: oldHabit)
        }

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

    /// Get Habits with frequency type .daily
    ///
    /// /// - Parameters:
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

        return habits.filter { $0.frequency == .daily }
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

        return habits.filter { $0.frequency == .interval }
            .compactMap { habit in
                let calendar = Calendar.current
                var currentDate = habit.startDate
                while currentDate <= habit.endDate {
                    if calendar.isDate(currentDate, inSameDayAs: date) {
                        return habit // The provided date matches an interval point
                    }
                    // Move to the next interval
                    currentDate = calendar.date(byAdding: .day, value: habit.scheduleInterval!, to: currentDate)!
                    }
                return nil
            }
    }

    /// Get all unchecked habits from selected date
    /// - Parameter date: Selected date
    /// - Returns: Array of Habits
    func loadUncheckedHabits(date: Date) async throws -> [Habit] {
        let habits = try await getHabits(date: date)
        let habitsDaily: [Habit] = try await getDailyHabits(date: date, existingHabits: habits)
        let habitsWeekly: [Habit] = try await getWeeklyHabits(date: date, existingHabits: habits)
        let habitsInterval: [Habit] = try await getIntervalHabits(date: date, existingHabits: habits)

        let uncheckedDailyList: [Habit] = habitsDaily
            .filter { !$0.isChecked }
        let uncheckedWeeklyList: [Habit] = habitsWeekly
            .filter { !$0.isChecked }
        let uncheckedIntervalList: [Habit] = habitsInterval
            .filter { !$0.isChecked }

        let uncheckedList: [Habit] = uncheckedDailyList + uncheckedWeeklyList + uncheckedIntervalList

        return uncheckedList
    }

    /// Get all checked habits from selected date
    /// - Parameter date: Selected date
    /// - Returns: Array of Habits
    func loadCheckedHabits(date: Date) async throws -> [Habit] {
        let habits = try await getHabits(date: date)
        let habitsDaily: [Habit] = try await getDailyHabits(date: date, existingHabits: habits)
        let habitsWeekly: [Habit] = try await getWeeklyHabits(date: date, existingHabits: habits)
        let habitsInterval: [Habit] = try await getIntervalHabits(date: date, existingHabits: habits)

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
        let checkedIntervalList: [Habit]  = habitsInterval
          .filter { $0.isChecked }
          .sorted { (lhs: Habit, rhs: Habit) in
              return (lhs.updatedDate < rhs.updatedDate)
          }

        let checkedList: [Habit] = checkedDailyList + checkedWeeklyList + checkedIntervalList

        return checkedList
    }

    /// Get habits and closest habit distance from current location
    ///
    /// - Parameters:
    ///   - currentLocation: User current location
    ///   - maxHabits: Limit of habits to be returned
    /// - Returns: Array of habits and Distance from closest habit
    func getHabitsByDistance(currentLocation: CLLocation, maxHabits: Int = 20) async throws -> ([Habit], Double) {
        var distanceFromClosest: Double = 200

        guard let habits: [Habit] = try? await loadUncheckedHabits(date: .now) else {
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
