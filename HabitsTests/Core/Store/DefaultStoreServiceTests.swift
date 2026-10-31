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
        self.sut = DefaultStoreService.tests()
    }

    override internal func tearDown() async throws {
        self.sut = nil
        try await super.tearDown()
    }
    
    internal func test_file_url() async throws {
        let sut: DefaultStoreService = DefaultStoreService.tests()
        
        let path = try sut.fileURL()
        
        XCTAssertTrue(path.isFileURL)
    }

    internal func test_tests_store_is_not_the_app_store() async throws {
        let testsPath = try DefaultStoreService.tests().fileURL()
        let appPath = try DefaultStoreService().fileURL()

        XCTAssertNotEqual(testsPath, appPath)
    }
    
    internal func test_save_and_load() async throws {
        let sut: DefaultStoreService = DefaultStoreService.tests()
        let emptyStore: StoreEntity = StoreEntity(
            habits: [], habitsArchived: [],
            habitsNotified: [], appConfigs: AppConfig.empty
        )
        
        try await sut.save(emptyStore)
        
        let loadedStore: StoreEntity = try await sut.load()

        XCTAssertNotNil(loadedStore)
        XCTAssertTrue(emptyStore.habits.isEmpty)
        XCTAssertTrue(loadedStore.habits.isEmpty)
    }
}
