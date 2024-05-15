//
//  HabitsServiceTests.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 14/05/2024.
//

@testable import Habits
import XCTest
import EventKit

internal final class HabitsServiceTests: XCTestCase {
    private var sut: HabitsService!
    private let testHabit: Habit = Habit.empty.with(name: "Test")
    
    override internal func setUp() async throws {
        try await super.setUp()
        self.sut = HabitsService()
    }

    override internal func tearDown() async throws {
        self.sut = nil
        try await DefaultStoreService().save(StoreEntity(habits: [], habitsArchived: []))
        try await super.tearDown()
    }
    
    internal func test_get_habits() async throws {
        let habits: [Habit] = try await sut.getHabits(date: Date.now)
        
        XCTAssertTrue(habits.isEmpty)
    }
    
    internal func test_add_habit() async throws {
        calendarAuthorizationMock()
        
        var loadedHabit: Habit? = nil
        
        // Add Habit
        let habitId: UUID = try await addHabit(testHabit)
        
        // Get Habit
        if let loadedHabitEntity: HabitEntity = try await getHabit(habitId) {
            loadedHabit = Habit(habitEntity: loadedHabitEntity)
        }
        
        XCTAssertNotNil(loadedHabit)
        XCTAssertEqual(testHabit.name, loadedHabit!.name)
    }
    
    internal func test_get_habit_by_uuid(id: UUID) async throws {
        // Add Habit
        let habitId: UUID = try await addHabit(testHabit)
        
        // Get Habit
        let habitEntity: HabitEntity? = try await getHabit(habitId)
        
        XCTAssertNotNil(habitEntity)
    }
    
    internal func test_get_habit_by_string() async throws {
        // Add Habit
        let habitId: UUID = try await addHabit(testHabit)
        
        // Get Habit
        let habitEntity: HabitEntity? = try await sut.getHabit(id: habitId.uuidString)
        
        XCTAssertNotNil(habitEntity)
    }
    
    internal func test_update_habit() async throws {
        calendarAuthorizationMock()
        
        let habitUpdatedName: String = "Name updated"
        var habit: Habit
        
        // Add Habit
        let habitId: UUID = try await addHabit(testHabit)
        
        // Get Habit
        if let habitEntity: HabitEntity = try await getHabit(habitId) {
            habit = Habit(habitEntity: habitEntity)
            habit.name = habitUpdatedName
            
            // Update habit
            try await sut.updateHabit(habit, selectedDate: Date.now)
        }
        
        let habitUpdated: HabitEntity? = try await getHabit(habitId)
        
        XCTAssertNotNil(habitUpdated)
        XCTAssertNotEqual(testHabit.name, habitUpdated!.name)
    }
    
    internal func test_remove_habit() async throws {
        calendarAuthorizationMock()
        
        // Add Habit
        let habitId: UUID = try await addHabit(testHabit)
        
        // Remove habit
        try await sut.removeHabit(habitId: habitId)
        
        // Get habit
        let habitRemoved: HabitEntity? = try await getHabit(habitId)
        
        XCTAssertNil(habitRemoved)
    }
    
    // MARK: - ABSTRACTIONS
    private func calendarAuthorizationMock() {
        // set up
        EKEventStore.swizzle()
        
        // tear down
        addTeardownBlock {
            EKEventStore.restore()
        }
    }
    
    private func addHabit(_ habit: Habit) async throws -> UUID {
        return try await sut.addHabit(habit)
    }
    
    private func getHabit(_ habitId: UUID) async throws -> HabitEntity? {
        return try await sut.getHabit(id: habitId)
    }
}
