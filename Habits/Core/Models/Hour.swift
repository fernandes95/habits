//
//  Hour.swift
//  Habits
//
//  Created by Tiago Fernandes on 05/09/2025.
//

import Foundation

struct Hour: Identifiable, Equatable, Codable {
    let id: UUID
    var eventId: String
    var notificationId: String?
    var date: Date
    var hour: String

    init(id: UUID = UUID(), eventId: String, notificationId: String? = nil, date: Date) {
        self.id = id
        self.eventId = eventId
        self.notificationId = notificationId
        self.date = date
        self.hour = date.getHourAndMinutes()
    }
}
