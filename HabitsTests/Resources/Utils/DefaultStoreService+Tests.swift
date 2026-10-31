//
//  DefaultStoreService+Tests.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 26/10/2026.
//

@testable import Habits

extension DefaultStoreService {
    /// Store used by the unit tests. The tests run inside the app, so they get their own
    /// data file instead of overwriting the app's habits.
    internal static func tests() -> DefaultStoreService {
        return DefaultStoreService(fileName: "habits-tests.data")
    }
}
