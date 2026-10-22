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

    @FocusState private var nameFocused: Bool

    var startDateIn: Date = .now

    var body: some View {
        NavigationStack {
            Form {
                // Name
                TextField("Title", text: self.$habit.name)
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.fill.tertiary, in: .rect(cornerRadius: 26))
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .focused(self.$nameFocused)
                    .accessibilityIdentifier("new_habit_name")

                // Duration
                Section(header: Text("Duration")) {
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

                Section(header: Text("Location")) {
                    Button {
                        // open location picker
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "location")
                                .font(.body.weight(.medium))
                            Text("Location to remind")
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
                }

                // Frequency
                HabitFrequencyView(
                    habit: self.$habit,
                    isEditing: .constant(true)
                )
            }
            .navigationTitle("New habit")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { self.nameFocused = true }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        self.addHabit()
                    }
                    .disabled(self.habit.name.isEmpty)
                }
            }
        }
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
