//
//  HabitDetailView.swift
//  Habits
//
//  Created by Tiago Fernandes on 20/02/2024.
//

import SwiftUI
import EventKitUI

struct HabitDetailView: View {
    @EnvironmentObject
    private var router: HabitsRouter

    @EnvironmentObject
    private var state: MainState

    @State private var habit: Habit

    @State private var isEditing: Bool = false
    @State private var editingHabit: Habit
    @State private var showingAlert = false
    @State private var hasLocationReminder: Bool = false

    init(habit: Habit) {
        self.habit = habit
        self._editingHabit = State(initialValue: habit)
    }

    var body: some View {
        VStack {
            NewHabitContentView(
                habit: $editingHabit,
                isEdit: $isEditing,
                isNew: false,
                locationAction: { },
                notificationAction: { }
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
                    deleteHabit()
                }
                Button("general_cancel", role: .cancel) { }
            }
        }
        .navigationBarBackButtonHidden(isEditing)
        .navigationTitle("habit_detail_title")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("general_cancel") {
                    cancelEditHabit()
                }
                .isHidden(!isEditing)
            }
            ToolbarItem(placement: .confirmationAction) {
                let title = isEditing ? "general_done" : "general_edit"
                Button(LocalizedStringKey(title)) {
                    if isEditing {
                        updateHabit()
                    }
                    isEditing = !isEditing
                }
            }
        }
    }

    private func deleteHabit() {
        Task {
            do {
                try await state.removeHabit(habitId: editingHabit.id)
            } catch {}
        }
        router.pop()
    }

    private func updateHabit() {
        Task {
            do {
                try await state.updateHabit(habit: editingHabit)
                let habitEdited = try await state.getHabit(habit: editingHabit)
                habit = habitEdited
                editingHabit = habitEdited
            } catch {}
        }
    }

    private func cancelEditHabit() {
        editingHabit = habit
        isEditing = false
    }
}

#Preview {
    HabitDetailView(habit: .empty)
        .environmentObject(HabitsRouter())
        .environmentObject(MainState())
}
