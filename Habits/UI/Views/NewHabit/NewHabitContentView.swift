//
//  NewHabitContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/10/2026.
//

import SwiftUI

struct NewHabitContentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @EnvironmentObject
    private var router: HabitsRouter

    @EnvironmentObject
    private var state: MainState

    @State
    private var habit: Habit = Habit.empty

    @State
    private var isPickingLocation: Bool = false

    @State
    private var locationPlace: LocationPlaceDetails?

    @State
    private var isAskingLocationAlways: Bool = false

    /// Adds the habit once the `Always` location sheet is dismissed
    @State
    private var shouldAddAfterLocationAlways: Bool = false

    @FocusState private var nameFocused: Bool

    var startDateIn: Date = .now

    /// - Parameters:
    ///   - startDateIn: First date the habit can start
    ///   - location: Location already picked, e.g. tapped on the map
    init(startDateIn: Date = .now, location: Habit.Location? = nil) {
        self.startDateIn = startDateIn
        self._habit = State(initialValue: Habit.empty.with(location: location))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Name
                TextField("new_habit_name_placeholder", text: self.$habit.name)
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.fill.tertiary, in: .rect(cornerRadius: 26))
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .focused(self.$nameFocused)
                    .accessibilityIdentifier("new_habit_name")

                // Duration
                Section(header: Text("new_habit_duration_section_title")) {
                    DatePicker("habit_start_date", selection: $habit.startDate,
                               in: self.startDateIn...,
                               displayedComponents: .date
                    )

                    if !habit.hasNoEndDate {
                        DatePicker("habit_end_date", selection: self.$habit.endDate,
                                   in: self.habit.startDate...,
                                   displayedComponents: .date)
                    }

                    Toggle("habit_has_end_date", isOn: $habit.hasNoEndDate)
                        .accessibilityIdentifier("new_habit_is_forever")
                        .onChange(of: self.habit.hasNoEndDate) { _, hasNoEndDate in
                            if hasNoEndDate {
                                let calendar = Calendar.current
                                let endDate = calendar.date(byAdding: .year, value: 100, to: self.habit.endDate)!
                                self.habit.endDate = endDate
                            } else {
                                self.habit.endDate = self.habit.startDate
                            }
                        }
                }

                HabitLocationSectionView(
                    location: self.$habit.location,
                    hasLocationReminder: self.$habit.hasLocationReminder,
                    place: self.$locationPlace,
                    onPickLocation: {
                        self.nameFocused = false
                        self.isPickingLocation = true
                    }
                )

                // Frequency
                HabitFrequencyView(
                    habit: self.$habit,
                    isEditing: .constant(true)
                )
            }
            .navigationTitle("new_habit_title")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { self.nameFocused = true }
            .sheet(isPresented: self.$isPickingLocation) {
                NewHabitLocationView(
                    location: self.$habit.location,
                    place: self.$locationPlace
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: self.$isAskingLocationAlways, onDismiss: {
                if self.shouldAddAfterLocationAlways {
                    self.shouldAddAfterLocationAlways = false
                    self.addHabit()
                }
            }, content: {
                LocationAlwaysSheetContentView(
                    openSettingsAction: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            self.openURL(url)
                        }
                    },
                    withoutReminderTitle: "new_habit_add_without_reminder",
                    withoutReminderAction: {
                        // Keeps the location but its region won't be monitored
                        self.habit.hasLocationReminder = false
                        self.shouldAddAfterLocationAlways = true
                        self.isAskingLocationAlways = false
                    },
                    closeAction: {
                        self.isAskingLocationAlways = false
                    }
                )
            })
            .onChange(of: self.scenePhase) { _, scenePhase in
                // Coming back from Settings with `Always` allowed, the habit can be added as it is
                if scenePhase == .active && self.isAskingLocationAlways && self.state.getLocationAuthorizationStatus() {
                    self.shouldAddAfterLocationAlways = true
                    self.isAskingLocationAlways = false
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("general_add") {
                        self.addHabit()
                    }
                    .disabled(!self.habit.isValid)
                }
            }
        }
    }

    private var locationTitle: Text {
        guard self.habit.location != nil else { return Text("habit_location_button") }

        if let locationName = self.locationPlace?.name {
            return Text(verbatim: locationName)
        }
        return Text("habit_location_pinned")
    }

    private func addHabit() {
        if self.state.needsLocationAlwaysAuthorization(for: self.habit) {
            self.nameFocused = false
            self.isAskingLocationAlways = true
            return
        }

        Task {
            if self.habit.startDate >= self.habit.endDate {
                self.habit.endDate = self.habit.startDate
            }
            let newHabit = self.habit
                .with(
                    createdDate: .now,
                    updatedDate: .now
                )

            do {
                try await self.state.addHabit(newHabit)
                dismiss()
            } catch let error { print(error.localizedDescription) }
        }
    }
}
