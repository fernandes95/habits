//
//  HabitsApp.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import SwiftUI

@main
struct HabitsApp: App {
    @StateObject private var store = StoreHabits()
    
    var body: some Scene {
        WindowGroup {
            HabitsView(habits: $store.habits) {
                Task {
                    do {
                        try await store.save(habits: store.habits)
                    } catch {
                        
                    }
                }
            }
            .task {
                do {
                    try await store.load()
                } catch {
                }
            }
        }
    }
}
