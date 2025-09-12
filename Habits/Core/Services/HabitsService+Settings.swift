//
//  HabitsService+Settings.swift
//  Habits
//
//  Created by Tiago Fernandes on 12/09/2025.
//

import Foundation

extension HabitsService {
    /// Gets exportable document
    func exportDataDocument() async -> ExportableDocument {
        var data: Data = Data()
        do {
            // Making sure latest data is saved
            try await storeService.save(self.store)
            data = try await storeService.loadAsData()
        } catch let error { print(error.localizedDescription) }
        return ExportableDocument(data: data)
    }

    /// Imports habits from url
    ///
    /// - Parameter url: Imported file Url
    /// - Returns: A nulable array of HabitEntities
    func importHabits(from: URL) async throws -> [HabitEntity]? {
        var habitsToBeAdded: [HabitEntity] = []
        if from.startAccessingSecurityScopedResource() {
            defer {
                from.stopAccessingSecurityScopedResource()
            }
            let importedStore: StoreEntity = try await storeService.load(url: from)

            var duplicatedHabits: [HabitEntity] = importedStore.habits.compactMap { habit in
                if self.store.habits.contains(where: { $0.id == habit.id || $0.name == habit.name }) {
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
        } else {
            return nil
        }
    }

    /// Manages duplicated habits when importing
    ///
    /// - Parameters:
    ///   - habits: Duplicated habits
    ///   - resolution: Conflict resolution type
    func manageDuplicates(habits: [HabitEntity], resolution: ConflictResolution) async throws {
        switch resolution {
        case .delete: return
        case .duplicate: try await self.duplicateHabits(habits)
        case .replace: try await self.replaceHabits(habits)
        }
    }

    /// Duplicates habits
    ///
    /// - Parameter habits: Duplicated habits
    private func duplicateHabits(_ habits: [HabitEntity]) async throws {
        var duplicatedHabits: [HabitEntity] = []
        for habit in habits {
            var count: Int = 1
            var name: String

            repeat {
                name = "\(habit.name) #\(count)"
                count += 1
            } while self.habits.contains(where: { $0.name == name })

            duplicatedHabits.append(habit.clone().with(name: name))
        }

        try await self.addHabits(duplicatedHabits)
    }

    /// Replaces existing habits
    ///
    /// - Parameter habits: Duplicated habits
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

}
