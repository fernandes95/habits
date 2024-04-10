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
        .appendingPathComponent("habits.data")
    }

    func load() async throws -> StoreEntity {
        let task = Task<StoreEntity, Error> {
            let fileURL = try self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return StoreEntity(habits: [], habitsArchived: [])
            }
            let decodedHabits = try JSONDecoder().decode(StoreEntity.self, from: data)
            return decodedHabits
        }
        return try await task.value
    }

    func save(_ store: StoreEntity) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(store)
            let outfile = try self.fileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
}
