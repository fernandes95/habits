//
//  HabitDetailView.swift
//  Habits
//
//  Created by Tiago Fernandes on 20/02/2024.
//

import SwiftUI

struct HabitDetailView: View {
    @Binding var habits: [Habit]
    @Binding var habit: Habit
    @State private var isEditing: Bool = false
    @State private var editingHabit: Habit
    
    init(habits: Binding<[Habit]>, habit: Binding<Habit>) {
        self._habits = habits
        self._habit = habit
        self._editingHabit = State(initialValue: habit.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            NewHabitContentView(
                habitName: $editingHabit.name,
                startDate: $editingHabit.date, // TODO: get correct startDate
                endDate: $editingHabit.date, // TODO: get groupId endDate?
                isEdit: $isEditing,
                isNew: false
                
                // TODO: add remove button
            )
            .navigationBarBackButtonHidden(isEditing)
            .navigationTitle($habit.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isEditing {
                        Button("Cancel") {
                            cancelEditHabit()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    let title = isEditing ? "Done" : "Edit"
                    Button(title) {
                        if isEditing {
                            editHabit()
                            isEditing = false
                        } else {
                            isEditing = true
                        }
                    }
                }
            }
            
        }
        
    }
    
    private func cancelEditHabit() {
        editingHabit = habit
        isEditing = false
    }
    
    private func editHabit() {
        if let index = habits.firstIndex(where: {$0.id == habit.id}) {
            habits[index] = editingHabit
            habit = editingHabit
        }
    }
}

#Preview {
    HabitDetailView(
        habits: .constant([]),
        habit: .constant(Habit(groupId: UUID(), name: "CENAS", date: Date.now, statusDate: Date.now))
    )
}
