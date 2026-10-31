//
//  HabitsServiceTests.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 14/05/2024.
//

@testable import Habits
import XCTest
import EventKit
import MapKit

internal final class HabitsServiceTests: XCTestCase {
    private var sut: HabitsService!
    private let testHabit: Habit = Habit.empty.with(name: "Test")
    
    override internal func setUp() async throws {
        try await super.setUp()
        self.sut = HabitsService(storeService: .tests())
    }

    override internal func tearDown() async throws {
        self.sut = nil
        try await DefaultStoreService.tests().save(
            StoreEntity(habits: [], habitsArchived: [], habitsNotified: [], appConfigs: AppConfig.empty)
        )
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
    
    internal func test_get_habit_by_uuid() async throws {
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
    
    internal func test_load_checked_habits() async throws {
        let habitCheckedAdded: Habit = testHabit.with(name: "Habit Checked")
        var habit: Habit
        calendarAuthorizationMock()
        
        // Add Habit Checked
        let habitCheckedId: UUID = try await addHabit(habitCheckedAdded)
        if let habitEntity: HabitEntity = try await getHabit(habitCheckedId) {
            habit = Habit(habitEntity: habitEntity)
            try await sut.updateHabit(habit.with(isChecked: true), selectedDate: Date.now)
        }
        
        // Add Habit Unchecked
        _ = try await addHabit(testHabit)
        
        // Load Checked Habits
        let habitsChecked: [Habit] = try await sut.loadCheckedHabits(date: Date.now)
        
        // Get added checked Habit
        let habitChecked: Habit? = habitsChecked.first(where: { $0.id == habitCheckedId })
        
        XCTAssertNotNil(habitChecked)
        XCTAssert(habitChecked?.isChecked == true)
    }
    
    /*internal func test_get_habits_by_distance() async throws {
        calendarAuthorizationMock()
        
        //Add Four Habits from furthest to closest
        let furthestHabitId: UUID = try await addHabit(
            testHabit.with(
                location: getMockHabitLocation(lat: 38.799582, long: -9.232582)
            )
        )
        _ = try await addHabit(testHabit.with(
                location: getMockHabitLocation(lat: 38.734015, long: -9.155403)
            )
        )
        _ = try await addHabit(testHabit.with(
                location: getMockHabitLocation(lat: 38.725539, long: -9.149830)
            )
        )
        let closestHabitId: UUID = try await addHabit(testHabit.with(
                location: getMockHabitLocation(lat: 38.716605, long: -9.1424020)
            )
        )
        
        //Get Only Three Habits by Distance
        let (habits, _): ([Habit], Double) = try await sut.getHabitsByDistance(
            currentLocation: CLLocation(latitude: 38.714042, longitude: -9.132921),
            maxHabits: 3
        )
        
        let furthestHabit: Habit? = habits.first(where: { $0.id == furthestHabitId })
        let closestHabit: Habit? = habits.first(where: { $0.id == closestHabitId })
        
        XCTAssertEqual(habits.count, 3)
        XCTAssertNil(furthestHabit)
        XCTAssertNotNil(closestHabit)
        XCTAssertEqual(closestHabit, habits.first)
    }*/
    
    // MARK: Install date

    internal func test_install_date_is_today_without_habits() async throws {
        try await self.sut.updateInstallDate()

        XCTAssertEqual(self.sut.appConfigs.installDate, Date.now.startOfDay)
        XCTAssertEqual(self.sut.appConfigs.earliestDate, Date.now.startOfDay)
    }

    internal func test_install_date_is_the_oldest_habit_date_when_updating_with_habits() async throws {
        let oldestDate: Date = Date.now.adding(days: -40)
        try await self.sut.addHabit(self.habitEntity(createdDate: Date.now.adding(days: -10)))
        try await self.sut.addHabit(self.habitEntity(createdDate: oldestDate))

        try await self.sut.updateInstallDate()

        XCTAssertEqual(self.sut.appConfigs.installDate, oldestDate.startOfDay)
    }

    internal func test_install_date_uses_a_start_date_older_than_the_creation_date() async throws {
        let startDate: Date = Date.now.adding(days: -60)
        try await self.sut.addHabit(self.habitEntity(createdDate: Date.now.adding(days: -5), startDate: startDate))

        try await self.sut.updateInstallDate()

        XCTAssertEqual(self.sut.appConfigs.installDate, startDate.startOfDay)
    }

    internal func test_install_date_never_moves_forward() async throws {
        let installDate: Date = Date.now.adding(days: -30)
        try await self.sut.updateInstallDate(now: installDate)

        try await self.sut.updateInstallDate()

        XCTAssertEqual(self.sut.appConfigs.installDate, installDate.startOfDay)
    }

    internal func test_install_date_moves_back_for_an_older_imported_habit() async throws {
        try await self.sut.updateInstallDate()
        let importedDate: Date = Date.now.adding(days: -90)
        try await self.sut.addHabit(self.habitEntity(createdDate: importedDate))

        try await self.sut.updateInstallDate()

        XCTAssertEqual(self.sut.appConfigs.installDate, importedDate.startOfDay)
    }

    internal func test_install_date_is_kept_when_changing_the_start_of_the_week() async throws {
        try await self.sut.updateInstallDate(now: Date.now.adding(days: -30))
        let installDate: Date? = self.sut.appConfigs.installDate

        try await self.sut.updateAppConfigs(self.sut.appConfigs.with(startOfWeek: .monday))

        XCTAssertEqual(self.sut.appConfigs.installDate, installDate)
    }

    internal func test_configs_saved_before_the_install_date_existed_still_load() throws {
        let data: Data = Data(#"{"startOfWeek": 2}"#.utf8)

        let configs: AppConfig = try JSONDecoder().decode(AppConfig.self, from: data)

        XCTAssertNil(configs.installDate)
        XCTAssertEqual(configs.earliestDate, Date.now.startOfDay)
    }

    // MARK: ABSTRACTIONS

    private func habitEntity(createdDate: Date, startDate: Date? = nil) -> HabitEntity {
        HabitEntity(
            eventId: "",
            name: "Test habit \(UUID().uuidString)",
            startDate: startDate ?? createdDate,
            endDate: createdDate.adding(days: 30),
            hasNoEndDate: true,
            frequency: Habit.Frequency.daily.rawValue,
            frequencyType: Ocurrence(),
            category: Habit.Category.new.rawValue,
            createdDate: createdDate
        )
    }
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
    
    private func getMockHabitLocation(lat: Double, long: Double) -> Habit.Location {
        return Habit.Location(
            latitude: lat,
            longitude: long,
            region: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: long),
                latitudinalMeters: 3000,
                longitudinalMeters: 3000
            )
        )
    }
}
