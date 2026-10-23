//
//  NewHabitContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/10/2026.
//

import SwiftUI

struct NewHabitContentView: View {
    @Environment(\.dismiss) private var dismiss

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

    @FocusState private var nameFocused: Bool

    var startDateIn: Date = .now

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

                Section(header: Text("habit_location_section_title")) {
                    if let location = self.habit.location {
                        LocationCardView(
                            location: location,
                            place: self.locationPlace,
                            onTap: {
                                self.isPickingLocation = true
                            },
                            onClear: {
                                withAnimation {
                                    self.habit.location = nil
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
            .onChange(of: self.habit.location) { _, location in
                // Reminders fire in the background, so they need always authorization
                if location != nil {
                    self.state.requestAlwaysLocation()
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
                    .disabled(self.habit.name.isEmpty)
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
