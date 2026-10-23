//
//  HabitDetailView.swift
//  Habits
//
//  Created by Tiago Fernandes on 20/02/2024.
//

import SwiftUI
import EventKitUI
import MapKit

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

    @State
    private var isPickingLocation: Bool = false

    @State
    private var locationPlace: LocationPlaceDetails?

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

                    /*Picker("habit_category", selection: self.$habit.category) {
                        ForEach(Habit.Category.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .disabled(!self.isEditing)*/

                    DatePicker("habit_start_date", selection: self.$habit.startDate,
                               in: self.$habit.startDate.wrappedValue...,
                               displayedComponents: .date
                    )
                    .disabled(true)

                    if !self.editingHabit.hasNoEndDate && self.isEditing ||
                        !self.habit.hasNoEndDate && !self.isEditing {
                        DatePicker("habit_end_date", selection: self.$editingHabit.endDate,
                                   in: habit.startDate...,
                                   displayedComponents: .date)
                        .disabled(!self.isEditing)
                    }

                    if self.isEditing {
                        Toggle("habit_has_end_date", isOn: $editingHabit.hasNoEndDate)
                            .onChange(of: self.editingHabit.hasNoEndDate) { _, hasNoEndDate in
                                if hasNoEndDate {
                                    let calendar = Calendar.current
                                    let endDate = calendar.date(
                                        byAdding: .year,
                                        value: 100,
                                        to: self.editingHabit.endDate
                                    )!
                                    self.editingHabit.endDate = endDate
                                } else {
                                    self.editingHabit.endDate = self.habit.startDate
                                }
                            }
                    }
                }

                HabitFrequencyView(
                    habit: self.$editingHabit,
                    isEditing: self.$isEditing
                )

                if !self.isEditing && self.habit.location != nil {
                    Section(header: Text("habit_location_section_title")) {
                        LocationCardView(location: self.habit.location!)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    }
                }

                if self.isEditing {
                    if let location = self.editingHabit.location {
                        LocationCardView(
                            location: location,
                            place: self.locationPlace,
                            onTap: {
                                self.isPickingLocation = true
                            },
                            onClear: {
                                withAnimation {
                                    self.editingHabit.location = nil
                                    self.locationPlace = nil
                                }
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    } else {
                        Button {
                            self.isPickingLocation = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "location")
                                    .font(.body.weight(.medium))
                                Text("habit_location_button")
                                    .font(.title3)
                                Spacer()
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(.fill.tertiary, in: .rect(cornerRadius: 26))
                            .contentShape(.rect(cornerRadius: 26))
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("new_habit_location")
                    }
                }

                Section(header: Text("habit_detail_history_section_title")) {
                    HabitCalendarView(
                        startDate: self.habit.createdDate,
                        history: self.habit.history
                    )
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
        .sheet(isPresented: self.$isPickingLocation) {
            NewHabitLocationView(
                location: self.$editingHabit.location,
                place: self.$locationPlace
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
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
                .disabled(!self.canContinue())
            }
        }
    }

    private func deleteHabit() {
        Task {
            do {
                try await self.state.removeHabit(habitId: self.habit.id)
            } catch let error { print(error.localizedDescription) }
        }
        self.router.pop()
    }

    private func updateHabit() {
        Task {
            do {
                try await self.state.editHabit(habit: self.editingHabit)
                let habitEdited = try await self.state.getHabit(habit: self.editingHabit)
                self.habit = habitEdited
                self.editingHabit = habitEdited
            } catch let error { print(error.localizedDescription) }
        }
    }

    private func cancelEditHabit() {
        self.editingHabit = self.habit
        self.isEditing = false
    }

    private func canContinue() -> Bool {
        guard isEditing else { return true }

        switch editingHabit.frequency {
        case .daily:
            return true
        case .interval:
            if let interval = editingHabit.scheduleInterval {
                return interval >= 2
            }
            return false
        case .weekly:
            return !editingHabit.frequencyType.weekFrequency.isEmpty
        case .minDays: return self.habit.frequencyType.minimumDays > 0 && self.habit.frequencyType.minimumDays < 6
        case .minTimes: return self.habit.frequencyType.minimumTimes > 0
        }
    }
}
