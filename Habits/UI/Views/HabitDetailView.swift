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
            Form {
                Section(header: Text("habit_new_section_habit_info")) {
                    TextField("habit_name", text: self.$editingHabit.name)
                        .disabled(!self.isEditing)

                    Picker("habit_category", selection: self.$habit.category) {
                        ForEach(Habit.Category.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .disabled(!self.isEditing)

                    DatePicker("habit_start_date", selection: self.$habit.startDate,
                               in: self.$habit.startDate.wrappedValue...,
                               displayedComponents: .date
                    )
                    .disabled(true)

                    DatePicker("habit_end_date", selection: self.$editingHabit.endDate,
                               in: habit.startDate...,
                               displayedComponents: .date)
                    .disabled(!self.isEditing)
                }

                HabitFrequencyView(
                    habit: self.$editingHabit,
                    isEditing: self.$isEditing
                )

                Section(header: Text("Location Reminder")) {
                    MapView(location: self.$editingHabit.location, canEdit: self.$isEditing)
                        .frame(height: 250)
                        .cornerRadius(10)
                        .isHidden(!self.habit.hasLocationReminder)
                        .disabled(!self.isEditing)
                }
            }

            Button(role: .destructive) {
                self.showingAlert = true
            } label: {
                Label("habit_detail_delete", systemImage: "trash")
            }
            .confirmationDialog(
                "habit_delete_dialog_title",
                isPresented: self.$showingAlert,
                titleVisibility: .visible
            ) {
                Button("habit_delete_dialog_single", role: .destructive) {
                    deleteHabit()
                }
                Button("general_cancel", role: .cancel) { }
            }
        }
        .navigationBarBackButtonHidden(self.isEditing)
        .navigationTitle("habit_detail_title")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("general_cancel") {
                    cancelEditHabit()
                }
                .isHidden(!self.isEditing)
            }
            ToolbarItem(placement: .confirmationAction) {
                let title = self.isEditing ? "general_done" : "general_edit"
                Button(LocalizedStringKey(title)) {
                    if self.isEditing {
                        updateHabit()
                    }
                    self.isEditing = !self.isEditing
                }
            }
        }
    }

    private func deleteHabit() {
        Task {
            do {
                try await self.state.removeHabit(habitId: self.habit.id)
            } catch {}
        }
        self.router.pop()
    }

    private func updateHabit() {
        Task {
            do {
                try await self.state.updateHabit(habit: self.editingHabit)
                let habitEdited = try await self.state.getHabit(habit: self.editingHabit)
                self.habit = habitEdited
                self.editingHabit = habitEdited
            } catch {}
        }
    }

    private func cancelEditHabit() {
        self.editingHabit = self.habit
        self.isEditing = false
    }
}

#Preview {
    HabitDetailView(habit: .empty)
        .environmentObject(HabitsRouter())
        .environmentObject(MainState())
}
