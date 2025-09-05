//
//  HabitEntity.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import Foundation

struct HabitEntity: Codable {
    var id: UUID
    var eventId: String
    var name: String
    var startDate: Date
    var endDate: Date
    var hasNoEndDate: Bool
    var frequency: String
    var frequencyType: Ocurrence
    var category: String
    var statusList: [Status]
    var schedule: [Hour]
    var successRate: Int = 0
    var hasAlarm: Bool
    var updatedDate: Date
    let createdDate: Date
    var hasLocationReminder: Bool
    var location: Location?
    var scheduleInterval: Int?

    init(id: UUID = UUID(),
         eventId: String,
         name: String,
         startDate: Date,
         endDate: Date,
         hasNoEndDate: Bool,
         frequency: String,
         frequencyType: Ocurrence,
         category: String,
         statusList: [Status] = [],
         schedule: [Hour] = [],
         hasAlarm: Bool = false,
         updatedDate: Date = .now,
         hasLocationReminder: Bool = false,
         location: Location? = nil,
         scheduleInterval: Int? = nil
    ) {
        self.id = id
        self.eventId = eventId
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.hasNoEndDate = hasNoEndDate
        self.frequency = frequency
        self.frequencyType = frequencyType
        self.category = category
        self.statusList = statusList
        self.schedule = schedule
        self.hasAlarm = hasAlarm
        self.updatedDate = updatedDate
        self.hasLocationReminder = hasLocationReminder
        self.location = location
        self.scheduleInterval = scheduleInterval
        self.createdDate = .now
        self.successRate = getSuccessRateValue(statusList: self.statusList, startDate: self.startDate)
    }

    internal func with(
        eventId: String? = nil,
        name: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        hasNoEndDate: Bool? = nil,
        frequency: String? = nil,
        frequencyType: Ocurrence? = nil,
        category: String? = nil,
        statusList: [Status]? = nil,
        scheduleInterval: Int? = nil,
        schedule: [Hour]? = nil,
        hasAlarm: Bool? = nil,
        updatedDate: Date? = nil,
        hasLocationReminder: Bool? = nil,
        location: Location? = nil
    ) -> Self {
        return Self(
            id: self.id,
            eventId: eventId ?? self.eventId,
            name: name ?? self.name,
            startDate: self.startDate,
            endDate: endDate ?? self.endDate,
            hasNoEndDate: hasNoEndDate ?? self.hasNoEndDate,
            frequency: frequency ?? self.frequency,
            frequencyType: frequencyType ?? self.frequencyType,
            category: category ?? self.category,
            statusList: statusList ?? self.statusList,
            schedule: schedule ?? self.schedule,
            hasAlarm: hasAlarm ?? self.hasAlarm,
            updatedDate: updatedDate ?? self.updatedDate,
            hasLocationReminder: hasLocationReminder ?? self.hasLocationReminder,
            location: location ?? self.location,
            scheduleInterval: scheduleInterval ?? self.scheduleInterval
        )
    }

    internal func clone() -> Self {
        return Self(
            id: UUID(),
            eventId: self.eventId,
            name: self.name,
            startDate: self.startDate,
            endDate: self.endDate,
            hasNoEndDate: self.hasNoEndDate,
            frequency: self.frequency,
            frequencyType: self.frequencyType,
            category: self.category,
            statusList: self.statusList,
            schedule: self.schedule,
            hasAlarm: self.hasAlarm,
            updatedDate: self.updatedDate,
            hasLocationReminder: self.hasLocationReminder,
            location: self.location,
            scheduleInterval: self.scheduleInterval
        )
    }

    internal struct Status: Codable {
        let id: UUID
        var date: Date
        var updatedDate: Date
        var isChecked: Bool

        init(id: UUID = UUID(), date: Date, updatedDate: Date = .now, isChecked: Bool = false) {
            self.id = id
            self.date = date
            self.updatedDate = updatedDate
            self.isChecked = isChecked
        }
    }

    internal struct Location: Codable {
        var latitude: Double
        var longitude: Double
    }
}

extension HabitEntity {
    private func getSuccessRateValue(statusList: [Status], startDate: Date) -> Int {
        let checkedAmount: Int = statusList.filter { $0.date <= .now.endOfDay && $0.isChecked }.count
        let dayDiff: Int = DateHelper.numberOfDaysBetween(startDate.startOfDay, and: .now.endOfDay) + 1
        let percentage: Double = checkedAmount == 0 ? 0 : (Double(checkedAmount) / Double(dayDiff)) * 100.0

        return Int(percentage)
    }

    func getSuccessRate() -> Int {
        return getSuccessRateValue(statusList: self.statusList, startDate: self.startDate)
    }
}
