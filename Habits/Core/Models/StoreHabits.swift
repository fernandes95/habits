////
////  StoreHabits.swift
////  Habits
////
////  Created by Tiago Fernandes on 24/01/2024.
////
//
//import SwiftUI
//
//@MainActor
//class StoreHabits: ObservableObject {
//    @Published var habits: [Habit] = [] 
//    {
//        didSet {
//            filterListByDate(date: selectedDate)
//        }
//    }
//    
//    @Published var filteredHabits: [Habit] = []
//    @Published var selectedDate: Date = Date.now
//    
//    private static func fileURL() throws -> URL {
//        try FileManager.default.url(for: .documentDirectory,
//                                    in: .userDomainMask,
//                                    appropriateFor: nil,
//                                    create: false)
//        .appendingPathComponent("habits.data")
//    }
//    
//    func filterListByDate(date: Date) {
//        selectedDate = date
//        
//        let dateList = habits
//            .filter { ($0.startDate ... $0.endDate).contains(date)}
//        let uncheckedList = dateList
//            .filter { $0.statusList.contains { $0.id.formatDate() == date.formatDate() && !$0.status } }
//        let checkedList = dateList
//            .filter { $0.statusList.contains { $0.id.formatDate() == date.formatDate() && $0.status } }
////            .sorted { (lhs: Habit, rhs: Habit) in
////                return (lhs.statusList[date]?.updateDate ?? date) > (rhs.statusList[date]?.updateDate ?? date)
////            }
//        
//        filteredHabits = uncheckedList + checkedList
////        filteredHabits = dateList
//    }
//    
//    func changeHabitStatus(habitId: UUID, date: Date) {
//        if let index = habits.firstIndex(where: {$0.id == habitId}) {
//            var habitUpdated = habits[index]
//            
//            if let status = habitUpdated.statusList[date] {
//                habitUpdated.statusList[date] = !status
//            } else {
//                habitUpdated.statusList[date] = true
//            }
//            
//            habits[index] = habitUpdated
//            
//            filterListByDate(date: habitUpdated.date)
//        }
//    }
//    
//    private func load() async throws {
//        let task = Task<[Habit], Error> {
//            let fileURL = try Self.fileURL()
//            guard let data = try? Data(contentsOf: fileURL) else {
//                return []
//            }
//            let decodedHabits = try JSONDecoder().decode([Habit].self, from: data)
//            return decodedHabits
//        }
//        let habits = try await task.value
//        self.habits = habits
//        filteredHabits = habits.filter { $0.date.formatDate() == Date.now.formatDate() }
//    }
//    
//    private func save() async throws {
//        let task = Task {
//            let data = try JSONEncoder().encode(habits)
//            let outfile = try Self.fileURL()
//            try data.write(to: outfile)
//        }
//        _ = try await task.value
//    }
//    
//    func getFutureHabits(_ habit: Habit) -> [Habit] {
//        return habits.filter { $0.groupId == habit.groupId && $0.date >= habit.date }
//    }
//    
//    func getHabitEndDate(_ habit: Habit) -> Date {
//        let list = getFutureHabits(habit)
//        return list.last?.date ?? habit.date
//    }
//    
//    func addHabit(_ habit: Habit) {
//        habits.append(habit)
//        saveData()
//    }
//    
//    func addHabitsByDates(startDate: Date, endDate: Date, groupId: UUID, habitName: String) {
//        let daysCount = DateHelper.numberOfDaysBetween(startDate, and: endDate)
//        
//        for i in 0...daysCount {
//            var dateComponent = DateComponents()
//            dateComponent.day = i
//            if let newDate = Calendar.current.date(byAdding: dateComponent, to: startDate) {
//                let addHabit = Habit(groupId: groupId, name: habitName, date: newDate, status: false, statusDate: Date.now)
//                self.addHabit(addHabit)
//            }
//        }
//    }
//    
//    func updateHabit(habitId: UUID, habitEdited: Habit) {
//        if let index = habits.firstIndex(where: {$0.id == habitId}) {
//            habits[index] = habitEdited
//            saveData()
//        }
//    }
//    
//    func removeHabit(_ habitId: UUID) {
//        if let index = habits.firstIndex(where: {$0.id == habitId}) {
//            habits.remove(at: index)
//            saveData()
//        }
//    }
//    
//    /// Removes habits where date is bigger than paramether date
//    func removeGroupHabits(groupId: UUID, date: Date) {
//        habits.removeAll(where: { $0.groupId == groupId && $0.date > date } )
//        saveData()
//    }
//    
//    /// Removes habits where date is bigger and equal to paramether date
//    func removeFutureHabits(groupId: UUID, date: Date) {
//        habits.removeAll(where: { $0.groupId == groupId && $0.date >= date} )
//        saveData()
//    }
//    
//    func loadData() {
//        Task {
//            do {
//                try await load()
//            } catch { }
//        }
//    }
//    
//    func saveData() {
//        Task {
//            do {
//                try await save()
//            } catch { }
//        }
//    }
//}
//
