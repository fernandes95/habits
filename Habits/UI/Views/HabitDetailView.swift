//
//  HabitDetailView.swift
//  Habits
//
//  Created by Tiago Fernandes on 20/02/2024.
//

import SwiftUI

struct HabitDetailView: View {
    @EnvironmentObject
    private var router: HabitsRouter
    
    @EnvironmentObject
    private var store: StoreHabits
    
    let habit: Habit
    @State private var isEditing: Bool = false
    @State private var editingHabit: Habit
    @State private var showingAlert = false
    
    init(habit: Habit) {
        self.habit = habit
        self._editingHabit = State(initialValue: habit)
    }
    
    var body: some View {
        VStack {
            NewHabitContentView(
                habitName: $editingHabit.name,
                startDate: $editingHabit.date,
                endDate: $editingHabit.date, // TODO: get groupId endDate?
                isEdit: $isEditing,
                isNew: false
            )
            
            Button(role: .destructive) {
                showingAlert = true
            } label: {
                Label("habit_detail_delete", systemImage: "trash")
            }
            .confirmationDialog(
                "habit_delete_dialog_title",
                isPresented: $showingAlert,
                titleVisibility: .visible
            ) {
                Button("habit_delete_dialog_single", role: .destructive) {
                    store.removeHabit(habit.id)
                    router.pop()
                }
                Button("habit_delete_dialog_future", role: .destructive) {
                    //TODO
                }
                Button("general_cancel", role: .cancel) { }
            }
        }
        .navigationBarBackButtonHidden(isEditing)
        .navigationTitle("habit_detail_title")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if isEditing {
                    Button("general_cancel") {
                        cancelEditHabit()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                let title = isEditing ? "general_done" : "general_edit"
                Button(LocalizedStringKey(title)) {
                    if isEditing {
                        store.updateHabit(habitId: habit.id, habitEdited: editingHabit)
                        isEditing = false
                    } else {
                        isEditing = true
                    }
                }
            }
        }
    }
    
    private func cancelEditHabit() {
        editingHabit = habit
        isEditing = false
    }
}

#Preview {
    HabitDetailView(
        habit: Habit(groupId: UUID(), name: "CENAS", date: Date.now, statusDate: Date.now)
    )
}
