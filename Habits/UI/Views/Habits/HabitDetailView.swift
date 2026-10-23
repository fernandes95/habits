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
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @EnvironmentObject
    private var router: HabitsRouter

    @EnvironmentObject
    private var state: MainState

    @State private var habit: Habit

    @State private var isEditing: Bool = false
    @State private var editingHabit: Habit
    @State private var showingAlert = false

    @State
    private var isPickingLocation: Bool = false

    @State
    private var locationPlace: LocationPlaceDetails?

    @State
    private var isAskingLocationAlways: Bool = false

    /// Saves the habit once the `Always` location sheet is dismissed
    @State
    private var shouldSaveAfterLocationAlways: Bool = false

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

                if self.isEditing || self.editingHabit.location != nil {
                    HabitLocationSectionView(
                        location: self.$editingHabit.location,
                        hasLocationReminder: self.$editingHabit.hasLocationReminder,
                        place: self.$locationPlace,
                        isEditing: self.isEditing,
                        onPickLocation: {
                            self.isPickingLocation = true
                        }
                    )
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
        .sheet(isPresented: self.$isAskingLocationAlways, onDismiss: {
            if self.shouldSaveAfterLocationAlways {
                self.shouldSaveAfterLocationAlways = false
                self.saveHabit()
            }
        }, content: {
            LocationAlwaysSheetContentView(
                openSettingsAction: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        self.openURL(url)
                    }
                },
                withoutReminderTitle: "habit_detail_save_without_reminder",
                withoutReminderAction: {
                    // Keeps the location but its region won't be monitored
                    self.editingHabit.hasLocationReminder = false
                    self.shouldSaveAfterLocationAlways = true
                    self.isAskingLocationAlways = false
                },
                closeAction: {
                    self.isAskingLocationAlways = false
                }
            )
        })
        .onChange(of: self.scenePhase) { _, scenePhase in
            // Coming back from Settings with `Always` allowed, the habit can be saved as it is
            if scenePhase == .active && self.isAskingLocationAlways && self.state.getLocationAuthorizationStatus() {
                self.shouldSaveAfterLocationAlways = true
                self.isAskingLocationAlways = false
            }
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
                    if !self.isEditing {
                        self.isEditing = true
                    } else if self.state.needsLocationAlwaysAuthorization(for: self.editingHabit) {
                        self.isAskingLocationAlways = true
                    } else {
                        self.saveHabit()
                    }
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

    private func saveHabit() {
        self.isEditing = false
        self.updateHabit()
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
