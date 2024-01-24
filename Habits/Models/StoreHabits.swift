//
//  StoreHabits.swift
//  Habits
//
//  Created by Tiago Fernandes on 24/01/2024.
//

import SwiftUI

@MainActor
class StoreHabits: ObservableObject {
    @Published var habits: [Habit] = []
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("habits.data")
    }
    
    func load() async throws {
        let task = Task<[Habit], Error> {
            let fileURL = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return []
            }
            let decodedHabits = try JSONDecoder().decode([Habit].self, from: data)
            return decodedHabits
        }
        let habits = try await task.value
        self.habits = habits
    }
    
    func save(habits: [Habit]) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(habits)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
}

