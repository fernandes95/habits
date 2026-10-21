//
//  TodoView.swift
//  Habits
//
//  Created by Tiago Fernandes on 21/10/2026.
//

import SwiftUI

struct TodoView: View {
    @EnvironmentObject
    private var router: HabitsRouter

    @EnvironmentObject
    private var state: MainState

    var body: some View {
        VStack {
            Text("TODO")
        }
    }
}
