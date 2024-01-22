//
//  ContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import SwiftUI

struct HabitsView: View {
    @Binding var habits: [Habit]
    @State private var showDatePicker = false
    @State private var datePickerDate = Date.now
    @State private var date = Date.now
    private let todayDate = Date().formatDate()
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button(action: { changeDate(day: -1) }) {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    HStack {
                        if date.formatDate() == todayDate {
                            Text("Today")
                        }
                        else {
                            Text(date, style: .date)
                        }
                    }
                    .onTapGesture {
                        showDatePicker.toggle()
                    }
                    .sheet(isPresented: $showDatePicker) {
                        VStack(alignment: .trailing) {
                            HStack {
                                Button("Today", role: .none, action: {
                                    showDatePicker.toggle()
                                    date = Date()
                                    datePickerDate = date
                                })
                                .disabled(date.formatDate() == todayDate)
                                Spacer()
                                    .buttonStyle(.borderless)
                                Button("Done", role: .none, action: {
                                    showDatePicker.toggle()
                                    date = datePickerDate
                                })
                                .buttonStyle(.borderless)
                            }
                            .padding([.top, .horizontal])
                            
                            DatePicker(
                                "",
                                selection: $datePickerDate,
                                displayedComponents: [.date]
                            )
                        }
                        .datePickerStyle(.graphical)
                        .presentationDetents([.medium])
                    }
                    Spacer()
                    Button(action: { changeDate(day: 1) }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding([.top, .horizontal])
            List($habits) { $habit in
                Toggle(isOn: .constant(habit.status)) {
                    Text(habit.name)
                }
                .toggleStyle(checkBoxStyle())
            }
            .navigationTitle("Habits")
            .toolbar {
                Button(action: {}) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New Habit")
            }
        }}
    }
    
    private func changeDate(day: Int) {
        var dateComponent = DateComponents()
        dateComponent.day = day
        let newDate = Calendar.current.date(byAdding: dateComponent, to: date)
        if newDate != nil {
            date = newDate.unsafelyUnwrapped
            datePickerDate = date
        }
    }
}

struct checkBoxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 20, height: 20)
            configuration.label
        }.onTapGesture { configuration.isOn.toggle() }
    }
}

extension Date {
        func formatDate() -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.setLocalizedDateFormatFromTemplate("dd-MM-yyyy") //TODO: improve this later
            return dateFormatter.string(from: self)
        }
}

#Preview {
    HabitsView(habits: .constant(Habit.sampleData))
}
