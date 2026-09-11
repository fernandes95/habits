//
//  DefaultStoreService.swift
//  Habits
//
//  Created by Tiago Fernandes on 26/02/2024.
//

import Foundation

class DefaultStoreService: StoreService {
    /// Data file path
    internal func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("habits.data")
    }

    /// Load all Data from local file
    func loadAsData() async throws -> Data {
        let task = Task<Data, Error> {
            let fileURL = try self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return Data()
            }
            return data
        }
        return try await task.value
    }

    /// Load all Data from local file
    func load() async throws -> StoreEntity {
        let task = Task<StoreEntity, Error> {
            let fileURL = try self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return StoreEntity(habits: [], habitsArchived: [], habitsNotified: [])
            }
            let decodedHabits = try JSONDecoder().decode(StoreEntity.self, from: data)
            return decodedHabits
        }
        return try await task.value
    }

    /// Load all Data from local file
    func loadHabit(id: String) async throws -> HabitEntity? {
        let task = Task<HabitEntity?, Error> {
            let fileURL = try self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return nil
            }
            let decodedHabits = try JSONDecoder().decode(StoreEntity.self, from: data)
            return decodedHabits.habits.first(where: { $0.id.uuidString == id }) ?? nil
        }
        return try await task.value
    }

    /// Load all Data from local file
    func didNotifyHabit(id: UUID) async throws -> Bool {
        let task = Task<Bool, Error> {
            let fileURL = try self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return false
            }
            let decodedHabits = try JSONDecoder().decode(StoreEntity.self, from: data)
            return decodedHabits.habitsNotified.contains(where: {
                $0.habitId == id &&
                $0.date.startOfDay == Date().startOfDay })
        }
        return try await task.value
    }

    /// Load all Data from imported file
    func load(url: URL) async throws -> StoreEntity {
        let task = Task<StoreEntity, Error> {
            guard let data = try? Data(contentsOf: url) else {
                return StoreEntity(habits: [], habitsArchived: [], habitsNotified: [])
            }
            let decodedHabits = try JSONDecoder().decode(StoreEntity.self, from: data)
            return decodedHabits
        }
        return try await task.value
    }

    /// Save all Data into local file
    func save(_ store: StoreEntity) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(store)
            let outfile = try self.fileURL()
            try data.write(to: outfile, options: .atomic)
        }
        _ = try await task.value
    }

    /// Only save notified habit
    func appendNotifiedHabit(_ notification: HabitNotificationEntity) async throws {
        let task = Task {
            let fileURL = try self.fileURL()
            var store: StoreEntity

            if let data = try? Data(contentsOf: fileURL) {
                store = try JSONDecoder().decode(StoreEntity.self, from: data)
            } else {
                store = StoreEntity(habits: [], habitsArchived: [], habitsNotified: [])
            }

            // append only if not already recorded today (idempotent)
            let alreadyNotified = store.habitsNotified.contains {
                $0.habitId == notification.habitId &&
                $0.date.startOfDay == notification.date.startOfDay
            }
            guard !alreadyNotified else { return }

            store.habitsNotified.append(notification)

            let data = try JSONEncoder().encode(store)
            try data.write(to: fileURL, options: .atomic)
        }
        _ = try await task.value
    }
}
