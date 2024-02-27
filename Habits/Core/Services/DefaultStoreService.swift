//
//  DefaultStoreService.swift
//  Habits
//
//  Created by Tiago Fernandes on 26/02/2024.
//

import Foundation

class DefaultStoreService: StoreService {
    internal func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("habitsTest.data")
    }
    
    func load() async throws -> [HabitEntity] {
        let task = Task<[HabitEntity], Error> {
            let fileURL = try fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return []
            }
            let decodedHabits = try JSONDecoder().decode([HabitEntity].self, from: data)
            return decodedHabits
        }
        return try await task.value
    }
    
    func save(_ habits: [HabitEntity]) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(habits)
            let outfile = try fileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
}
