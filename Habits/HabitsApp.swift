//
//  HabitsApp.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import SwiftUI

@main
struct HabitsApp: App {
    @State private var habits = Habit.sampleData
    
    var body: some Scene {
        WindowGroup {
            HabitsView(habits: $habits)
        }
    }
}
