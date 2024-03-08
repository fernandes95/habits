//
//  HabitEntity.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import Foundation

struct HabitEntity: Codable {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var frequency: String
    var category: String
    var statusList: [Status]
    var schedule: [Hour]
    var successRate: Int = 0
    var updatedDate: Date
    let createdDate: Date
    
    init(id: UUID = UUID(),
         name: String,
         startDate: Date,
         endDate: Date,
         frequency: String,
         category: String,
         statusList: [Status] = [],
         schedule: [Hour] = [],
         updatedDate: Date = Date.now
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.frequency = frequency
        self.category = category
        self.statusList = statusList
        self.schedule = schedule
        self.updatedDate = updatedDate
        self.createdDate = Date.now
        self.successRate = getSuccessRateValue(statusList: self.statusList, startDate: self.startDate)
    }
    
    internal func with(
        name: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        frequency: String? = nil,
        category: String? = nil,
        statusList: [Status]? = nil,
        schedule: [Hour]? = nil,
        updatedDate: Date? = nil
    ) -> Self {
        return Self(
            id: self.id,
            name: name ?? self.name,
            startDate: self.startDate,
            endDate: endDate ?? self.endDate,
            frequency: frequency ?? self.frequency,
            category: category ?? self.category,
            statusList: statusList ?? self.statusList,
            schedule: schedule ?? self.schedule,
            updatedDate: updatedDate ?? self.updatedDate
        )
    }
    
    internal struct Status: Codable {
        let id: UUID
        var date: Date
        var updatedDate: Date
        var isChecked: Bool
        
        init(id: UUID = UUID(), date: Date, updatedDate: Date = Date.now, isChecked: Bool = false) {
            self.id = id
            self.date = date
            self.updatedDate = updatedDate
            self.isChecked = isChecked
        }
    }
    
    internal struct Hour: Codable {
        let id: UUID
        let date: Date
        
        init(id: UUID = UUID(), date: Date) {
            self.id = id
            self.date = date
        }
    }
}

extension HabitEntity {
    private func getSuccessRateValue(statusList: [Status], startDate: Date) -> Int {
        let checkedAmount = statusList.filter { $0.date <= Date.now.endOfDay && $0.isChecked }.count
        let dayDiff = DateHelper.numberOfDaysBetween(startDate.startOfDay, and: Date.now.endOfDay) + 1
        let percentage = checkedAmount == 0 ? 0 : (Double(checkedAmount) / Double(dayDiff)) * 100.0
        
        return Int(percentage)
    }
    
    func getSuccessRate() -> Int {
        return getSuccessRateValue(statusList: self.statusList, startDate: self.startDate)
    }
}
