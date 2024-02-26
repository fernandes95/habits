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
    private var state: MainState
    
    private let habit: MainState.Item
    
    @State private var isEditing: Bool = false
    @State private var editingHabit: MainState.Item
    @State private var showingAlert = false
    @State private var endDate: Date = Date.now
    @State private var editingEndDate: Date = Date.now
    
    init(habit: MainState.Item) {
        self.habit = habit
        self._editingHabit = State(initialValue: habit)
    }
    
    var body: some View {
        VStack {
            NewHabitContentView(
                habitName: $editingHabit.name,
                startDate: $editingHabit.startDate,
                endDate: $editingEndDate,
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
//                    store.removeHabit(habit.id)
                    router.pop()
                }
//                if groupHabits.count > 1 {
//                    Button("habit_delete_dialog_future", role: .destructive) {
////                        store.removeFutureHabits(groupId: editingHabit.groupId, date: editingHabit.date)
//                        router.pop()
//                    }
//                }
                Button("general_cancel", role: .cancel) { }
            }
        }
        .onAppear {
//            endDate = groupHabits.last?.date ?? habit.date
            editingEndDate = endDate
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
                        updateHabit()
                        isEditing = false
                    } else {
                        isEditing = true
                    }
                }
            }
        }
    }
    
    private func updateHabit() {
//        if habit.name != editingHabit.name {
//            
//        }
//        
//        if editingEndDate < endDate {
//            store.removeGroupHabits(groupId: habit.groupId, date: editingEndDate)
//        } else if editingEndDate > endDate {
//            store.addHabitsByDates(startDate: habit.date, endDate: editingEndDate, groupId: habit.groupId, habitName: editingHabit.name)
//        }
//        store.updateHabit(habitId: habit.id, habitEdited: editingHabit)
    }
    
    private func cancelEditHabit() {
        editingHabit = habit
        editingEndDate = endDate
        isEditing = false
    }
}

#Preview {
    HabitDetailView(
        habit: MainState.Item(id: UUID(), name: "CENAS", startDate: Date.now, endDate: Date.now, isChecked: false)
    )
    .environmentObject(HabitsRouter())
    .environmentObject(MainState())
}
