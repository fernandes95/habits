//
//  CalendarServiceTests.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 15/05/2024.
//

@testable import Habits
import XCTest
import EventKit
import MapKit

// TODO: Find a way to accept Calendar access in Unit tests
internal final class CalendarServiceTests: XCTestCase {
    private var sut: CalendarService!
    private let testHabit: Habit = Habit.empty.with(name: "Test")
    
    override internal func setUp() async throws {
        try await super.setUp()
//        EKEventStore.swizzle(status: .restricted)
        self.sut = CalendarService()
    }

    override internal func tearDown() async throws {
        self.sut = nil
//        EKEventStore.restore(status: .restricted)
        try await super.tearDown()
    }
    
    internal func test_create_calendar_event() async throws {
        // Create event
        let eventId: String = try await sut.createCalendarEvent(testHabit)
        
        // Get event
        let event: EKEvent? = sut.getEventById(eventId: eventId)
        
        XCTAssertNotNil(event)
    }
    
    internal func test_create_schedule_calendar_events() async throws {
        
    }
    
    internal func test_remove_events() async throws {
        
    }
    
    internal func test_manage_schedule_events() async throws {
        
    }
    
    internal func test_get_event_id() async throws {
        
    }
    
    internal func test_delete_event_by_id() async throws {
        
    }
    
    internal func test_edit_event() async throws {
        
    }
}
