//
//  AddHabitView.swift
//  Habits
//
//  Created by Tiago Fernandes on 24/01/2024.
//

import SwiftUI
import Foundation

struct NewHabitView: View {
    @EnvironmentObject
    private var state: MainState
    
    @Binding var isPresentingNewHabit: Bool
    @State private var name: String = ""
    @State var startDate: Date
    @State private var endDate: Date = Date.now
    
    var body: some View {
        NavigationStack {
            NewHabitContentView(
                habitName: $name,
                startDate: $startDate,
                endDate: $endDate,
                isEdit: .constant(true),
                isNew: true
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("general_dismiss") {
                        isPresentingNewHabit = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("general_add") {
                        addHabit()
                    }.disabled(name.isEmpty)
                }
            }
        }
        .onAppear() {
            endDate = startDate
        }
    }
    
    private func addHabit() {
        if startDate >= endDate {
            endDate = startDate
        }
        let newHabit = MainState.Item(
            id: UUID(),
            name: name,
            startDate: startDate,
            endDate: endDate,
            isChecked: false
        )
        state.addItem(newHabit)
        
        isPresentingNewHabit = false
    }
}

#Preview {
    NewHabitView(isPresentingNewHabit: .constant(false), startDate: Date.now)
}
