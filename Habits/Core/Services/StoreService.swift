//
//  StoreService.swift
//  Habits
//
//  Created by Tiago Fernandes on 26/02/2024.
//

import Foundation

protocol StoreService {
    func fileURL() throws -> URL
    func load() async throws -> [HabitEntity]
    func save(_ habits: [HabitEntity]) async throws
}
