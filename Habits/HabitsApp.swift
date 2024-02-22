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
    @StateObject private var router: HabitsRouter = HabitsRouter()

    var body: some Scene {
        WindowGroup {
            ZStack {
                self.router.root
                    .environmentObject(self.store)
                    .environmentObject(self.router)
            }
        }
    }
}
