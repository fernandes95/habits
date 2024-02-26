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
}

extension Date {
    func formatDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("dd-MM-yyyy")
        return dateFormatter.string(from: self)
    }
}
