//
//  DateHelper.swift
//  Habits
//
//  Created by Tiago Fernandes on 26/02/2024.
//

import Foundation

struct DateHelper {
    static func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let calendar = Calendar.current
        let fromDate = calendar.startOfDay(for: from)
        let toDate = calendar.startOfDay(for: to)
        let numberOfDays = calendar.dateComponents([.day], from: fromDate, to: toDate).day
        
        return numberOfDays!
    }
    
    //  TODO validate that the date is at least 3 days old
    static func dateIsValidToDelete(startDate: Date) -> Bool {
        let daysDiff = DateHelper.numberOfDaysBetween(
            startDate.startOfDay,
            and: Date.now.startOfDay
        )
        
        return daysDiff <= 3
    }
}

extension Date {
    func formatDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("dd-MM-yyyy")
        return dateFormatter.string(from: self)
    }
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
}
