//
//  DefaultStoreServiceTests.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 13/05/2024.
//

@testable import Habits
import XCTest

internal final class DefaultStoreServiceTests: XCTestCase {
    private var sut: DefaultStoreService?
    
    override internal func setUp() async throws {
        try await super.setUp()
        self.sut = DefaultStoreService()
    }

    override internal func tearDown() async throws {
        self.sut = nil
        try await super.tearDown()
    }
    
    internal func test_file_url() async throws {
        let sut: DefaultStoreService = DefaultStoreService()
        
        let path = try sut.fileURL()
        
        XCTAssertTrue(path.isFileURL)
    }
    
    internal func test_save_and_load() async throws {
        let sut: DefaultStoreService = DefaultStoreService()
        let emptyStore: StoreEntity = StoreEntity(habits: [], habitsArchived: [])
        
        try await sut.save(emptyStore)
        
        let loadedStore: StoreEntity = try await sut.load()

        XCTAssertNotNil(loadedStore)
        XCTAssertTrue(emptyStore.habits.isEmpty)
        XCTAssertTrue(loadedStore.habits.isEmpty)
    }
}
