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
    
    private let habit: Habit
    
    @State private var isEditing: Bool = false
    @State private var editingHabit: Habit
    @State private var showingAlert = false
    @State private var editingEndDate: Date
    
    init(habit: Habit) {
        self.habit = habit
        self._editingHabit = State(initialValue: habit)
        self._editingEndDate = State(initialValue: habit.endDate)
    }
    
    var body: some View {
        VStack {
            let isValidToDelete = DateHelper.dateIsValidToDelete(startDate: habit.startDate)
            
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
            .disabled(!isValidToDelete)
            .confirmationDialog(
                "habit_delete_dialog_title",
                isPresented: $showingAlert,
                titleVisibility: .visible
            ) {
                
                let isSingleDate = DateHelper.numberOfDaysBetween(editingHabit.startDate, and: editingHabit.endDate) == 0
                let isLastDayValidation = editingHabit.endDate == state.selectedDate
                let isFirstDayValidation = editingHabit.createdDate == state.selectedDate
                    
                if isSingleDate || isLastDayValidation || isFirstDayValidation {
                    deleteSingleHabitButton
                } else {
                    deleteFutureHabitsButton
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
                        updateHabit()
                        isEditing = false
                    } else {
                        isEditing = true
                    }
                }
            }
        }
    }
   
    var deleteSingleHabitButton: some View {
        Button("habit_delete_dialog_single", role: .destructive) {
            //  TODO: ON DEVELOPMENT
            var amountOfDays = DateHelper.numberOfDaysBetween(editingHabit.startDate, and: editingHabit.endDate)
            if amountOfDays == 0 {
                removeHabit()
            } else {
                updateHabit()
            }
            router.pop()
        }
    }
    
    var deleteFutureHabitsButton: some View {
        Button("habit_delete_dialog_future", role: .destructive) {
            if editingHabit.startDate.formatDate() == state.selectedDate.formatDate() {
                removeHabit()
            } else {
                let date = state.selectedDate
                var dateComponent = DateComponents()
                dateComponent.day = -1
                if let newDate = Calendar.current.date(byAdding: dateComponent, to: date) {
                    editingHabit.endDate = newDate
                    updateHabit()
                }
            }
            router.pop()
        }
    }
    
    private func updateHabit() {
        Task {
            do {
                try await state.updateHabit(habit: editingHabit)
            } catch {}
        }
    }
    
    private func removeHabit() {
        Task {
            do {
                try await state.removeHabit(habitId: editingHabit.id)
            } catch {}
        }
    }
    
    private func cancelEditHabit() {
        editingHabit = habit
        editingEndDate = habit.endDate
        isEditing = false
    }
}

#Preview {
    HabitDetailView(
        habit: Habit(id: UUID(), name: "CENAS", startDate: Date.now, endDate: Date.now, isChecked: false, createdDate: Date.now, updatedDate: Date.now)
    )
    .environmentObject(HabitsRouter())
    .environmentObject(MainState())
}
