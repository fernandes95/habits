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
    
    @Binding var habit: Habit
    @State private var isEditing: Bool = false
    @State private var editingHabit: Habit
    @State private var showingAlert = false
    
    init(habit: Binding<Habit>) {
        self._habit = habit
        self._editingHabit = State(initialValue: habit.wrappedValue)
    }
    
    var body: some View {
            VStack {
                NewHabitContentView(
                    habitName: $editingHabit.name,
                    startDate: $editingHabit.date, // TODO: get correct startDate
                    endDate: $editingHabit.date, // TODO: get groupId endDate?
                    isEdit: $isEditing,
                    isNew: false
                )
                
                Button(role: .destructive) {
                    showingAlert = true
                } label: {
                    Label("Delete habit", systemImage: "trash")
                }
                .confirmationDialog(
                    "Are you sure you wanto to delete this habit?",
                    isPresented: $showingAlert,
                    titleVisibility: .visible
                ) {
                    Button("Delete this habit", role: .destructive) {
                        removeHabit()
                    }
                    Button("Delete future habits", role: .destructive) {
                        //TODO
                    }
                    Button("Cancel", role: .cancel) { }
                }
        }
        .navigationBarBackButtonHidden(isEditing)
        .navigationTitle("Habit detail")
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
    
    private func save() {
        Task {
            do {
                try await store.save()
            } catch {
            }
        }
    }
    
    private func editHabit() {
        if let index = store.habits.firstIndex(where: {$0.id == habit.id}) {
            store.habits[index] = editingHabit
            habit = editingHabit
            save()
        }
    }
    
    private func cancelEditHabit() {
        editingHabit = habit
        isEditing = false
    }
    
    private func removeHabit() {
        if let index = store.habits.firstIndex(where: {$0.id == habit.id}) {
            store.habits.remove(at: index)
            save()
            router.pop()
        }
    }
}

#Preview {
    HabitDetailView(
        habit: .constant(Habit(groupId: UUID(), name: "CENAS", date: Date.now, statusDate: Date.now))
    )
}
