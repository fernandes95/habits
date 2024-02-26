//
//  HabitsApp.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import SwiftUI

@main
struct HabitsApp: App {
    @StateObject private var state = MainState()
    @StateObject private var router: HabitsRouter = HabitsRouter()

    var body: some Scene {
        WindowGroup {
            ZStack {
                self.router.root
                    .environmentObject(self.state)
                    .environmentObject(self.router)
            }
        }
    }
}
