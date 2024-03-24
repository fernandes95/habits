//
//  NewHabitContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 20/02/2024.
//

import SwiftUI
import MapKit

struct NewHabitContentView: View {
    @Binding var name: String
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var frequency: Habit.Frequency
    @Binding var weekFrequency: [WeekDay]
    @Binding var category: Habit.Category
    @Binding var schedule: [Habit.Hour]
    @Binding var isEdit: Bool
    @Binding var hasAlarm: Bool

    let isNew: Bool
    var startDateIn: Date = Date.now
    var successRate: String?

    @State private var mapLocations: [CLLocationCoordinate2D] = []
    @State private var hasLocationReminder: Bool = false
    @State private var hoursDate: Date = Date.now

    // TODO: CHANGE THIS TO MAP POSITION
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.736946, longitude: -9.142685),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))

    var body: some View {
        Form {
            Section(header: Text("habit_new_section_habit_info")) {
                TextField("habit_name", text: $name)
                    .disabled(!isEdit)

                Picker("habit_category", selection: $category) {
                    ForEach(Habit.Category.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .disabled(!isEdit)

                DatePicker("habit_start_date", selection: $startDate,
                           in: startDateIn...,
                           displayedComponents: .date
                )
                .disabled(!isNew)

                DatePicker("habit_end_date", selection: $endDate,
                           in: startDate...,
                           displayedComponents: .date)
                .disabled(!isEdit)
            }

            Section(header: Text("habit_new_section_habit_frequency")) {
                Picker("habit_frequency", selection: $frequency) {
                    ForEach(Habit.Frequency.allCases) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                            .onTapGesture {
                                if frequency != .weekly {
                                    weekFrequency.removeAll()
                                }
                            }
                    }
                }
                .disabled(!isEdit)

                if frequency == .weekly {
                    Spacer()
                    ForEach(WeekDay.allCases, id: \.self) { day in
                        HStack {
                            Text(day.rawValue).tag(day)
                            Spacer()
                            if weekFrequency.contains(day) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if weekFrequency.contains(day) {
                                weekFrequency.removeAll(where: {$0 == day})
                            } else {
                                weekFrequency.append(day)
                            }
                        }
                    }
                    .disabled(!isEdit)
                }
            }

            if schedule.count > 0 || schedule.count == 0 && isEdit {
                Section {
                    ForEach($schedule) { $hour in
                        if let index = schedule.firstIndex(of: hour) {
                            let datePicker = DatePicker("Hour #\(index + 1)",
                                                        selection: $hour.date,
                                                        displayedComponents: .hourAndMinute
                            )

                            if !isEdit {
                                datePicker
                            } else {
                                datePicker
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            schedule.remove(at: index)

                                            if schedule.isEmpty {
                                                hasAlarm = false
                                            }
                                        } label: {
                                            Label("habit_schedule_delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .disabled(!isEdit)
                } header: {
                    HStack {
                        Text("habit_new_section_habit_schedule")
                        Spacer()
                        if isEdit {
                            Button(action: {
                                let calendar = Calendar.current
                                var date: Date = Date.now
                                var mainDateComponents: DateComponents = DateComponents()

                                if schedule.isEmpty {
                                    var dateComponents = calendar.dateComponents(
                                        [.day, .month, .year, .hour, .minute],
                                        from: self.startDate
                                    )
                                    dateComponents.hour = 09
                                    dateComponents.minute = 00
                                    dateComponents.second = 00

                                    mainDateComponents = dateComponents

                                    hasAlarm = true
                                } else {
                                    let scheduleSorted = schedule.sorted { (lhs: Habit.Hour, rhs: Habit.Hour) in
                                        return (lhs.date < rhs.date)
                                    }
                                    if let hour = scheduleSorted.last {
                                        var dateComponents = calendar.dateComponents(
                                            [.day, .month, .year, .hour, .minute],
                                            from: hour.date
                                        )
                                        dateComponents.hour = (dateComponents.hour ?? 9) + 1
                                        dateComponents.minute = dateComponents.minute

                                        mainDateComponents = dateComponents
                                    }
                                }

                                if let newDate = calendar.date(from: mainDateComponents) {
                                    date = newDate
                                }

                                schedule.append(
                                    Habit.Hour(eventId: "", date: date)
                                )
                            }, label: {
                                Image(systemName: "plus")
                            })
                            .accessibilityLabel("habits_accessibility_new_schedule_hour")
                        }
                    }
                }

                let isDisabled = $schedule.isEmpty ? true : !isEdit
                    Toggle("habit_has_alarm", isOn: $hasAlarm)
                    .disabled(isDisabled)
            }

            Section(header: Text("Location Reminder")) {
                VStack {
                    Toggle("hasLocationReminder", isOn: $hasLocationReminder)
                        .disabled(!isEdit)

                    if #available(iOS 17.0, *) {
                        MapReader { proxy in
                            Map() // TODO: ADD CORRECT POSITION
                            .frame(height: 250)
                            .mapControlVisibility(.hidden)
                            .onTapGesture { position in
                                if let coordinate: CLLocationCoordinate2D = proxy.convert(position, from: .local) {
                                    print(coordinate)
                                }
                            }
                        }
                    } else {
                        // TODO: Fallback on earlier versions
                    }
                }
            }

            if !isNew && successRate != nil {
                Text(successRate!)
                    .disabled(true)
            }
        }
    }
}

#Preview {
    NewHabitContentView(
        name: .constant("cenas"),
        startDate: .constant(Date.now),
        endDate: .constant(Date.now),
        frequency: .constant(.daily),
        weekFrequency: .constant([]),
        category: .constant(.new),
        schedule: .constant([]),
        isEdit: .constant(true),
        hasAlarm: .constant(false),
        isNew: true,
        successRate: "70%"
    )
}
