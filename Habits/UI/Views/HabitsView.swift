//
//  ContentView.swift
//  Habits
//
//  Created by Tiago Fernandes on 22/01/2024.
//

import SwiftUI

struct HabitsView: View {
    @EnvironmentObject
    private var router: HabitsRouter

    @EnvironmentObject
    private var state: MainState

    @State private var didLoadData = false

    var body: some View {
        VStack {
            HeaderView(
                date: self.$state.selectedDate,
                progress: self.state.dayProgress,
                changeDateAction: self.loadSelectedDate,
                settingsAction: { self.router.push(SettingsView()) }
            )
            .padding(.horizontal)
            .padding(.bottom, 12)

            ZStack(alignment: .bottomTrailing) {
                DaySwipeContainer(onSwipe: changeDay) {
                    ContentView(
                        list: self.$state.habits,
                        date: self.$state.selectedDate,
                        onItemStatusAction: { habit in
                            Task {
                                do {
                                    try await self.state.updateHabit(habit: habit)
                                } catch let error { print(error.localizedDescription) }
                            }
                        },
                        onItemAction: { habit in
                            router.push(HabitDetailView(habit: habit))
                        }
                    )
                }

                Button {
                    self.router.push(NewHabitQuoteView())
                } label: {
                    Image(systemName: "plus")
                        .font(.title.weight(.medium))
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.primary)
                        .clipShape(Circle())
                        .shadow(radius: 4, x: 0, y: 4)

                }
                .accessibilityLabel("habits_accessibility_new_habit")
                .padding(20)
            }
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                    .fill(Color(.systemBackground))
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(Color(.systemGroupedBackground))
        .task {
            if !didLoadData {
                Task {
                    do {
                        try await state.loadHabits(date: state.selectedDate)
                    } catch let error { print(error.localizedDescription) }
                }
                didLoadData = true
            }
        }
        .navigationTitle("habits_title")
        .toolbar(.hidden, for: .navigationBar)
    }

    private func loadSelectedDate() {
        Task {
            do {
                try await self.state.loadHabits(date: state.selectedDate)
            } catch let error { print(error.localizedDescription) }
        }
    }

    /// Moves the selected date by `days` (negative goes back)
    private func changeDay(by days: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: days, to: state.selectedDate) else { return }
        self.state.selectedDate = newDate
        self.loadSelectedDate()
    }
}

private struct HeaderView: View {
    @Binding var date: Date
    let progress: [Date: Double]
    var changeDateAction: () -> Void
    var settingsAction: () -> Void

    @State private var showDatePicker = false
    @State private var datePickerDate = Date.now
    /// Week currently shown by the pager, relative to the week of `referenceWeekStart`
    @State private var visibleWeek: Int?
    /// True while the user is dragging the pager, used to tell user swipes from programmatic scrolls
    @State private var isUserScrolling = false

    private let calendar = Calendar.current
    private let referenceWeekStart: Date
    /// Amount of weeks reachable by swiping, before and after the current week (~19 years)
    private static let weekRange: ClosedRange<Int> = -1000...1000

    init(
        date: Binding<Date>,
        progress: [Date: Double],
        changeDateAction: @escaping () -> Void,
        settingsAction: @escaping () -> Void
    ) {
        self._date = date
        self.progress = progress
        self.changeDateAction = changeDateAction
        self.settingsAction = settingsAction
        let referenceWeekStart = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start
            ?? Date.now.startOfDay
        self.referenceWeekStart = referenceWeekStart
        // Start the pager on the selected week before the first layout
        self._visibleWeek = State(
            initialValue: Self.weekOffset(for: date.wrappedValue, from: referenceWeekStart)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                self.titleButton
                Spacer()
                Button(action: self.settingsAction, label: {
                    Image(systemName: "gearshape.2.fill")
                })
                .accessibilityLabel("habits_accessibility_settings")
            }
            .padding(.top, 8)

            VStack(spacing: 6) {
                self.weekdaySymbols
                self.weekPager
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheetContent(
                datePickerDate: self.$datePickerDate,
                todayAction: {
                    self.showDatePicker = false
                    self.date = Date()
                    self.changeDateAction()
                },
                doneAction: {
                    self.showDatePicker = false
                    self.date = datePickerDate
                    self.changeDateAction()
                },
                todayButtonDisabled: self.calendar.isDateInToday(self.date)
            )
        }
        .onAppear {
            self.visibleWeek = self.weekOffset(for: self.date)
        }
        .onChange(of: self.date) { _, newDate in
            // Date changed from outside the pager (calendar, day tap, list swipe): follow it.
            let newWeek = weekOffset(for: newDate)
            if self.visibleWeek != newWeek && !self.isUserScrolling {
                withAnimation(.snappy) { self.visibleWeek = newWeek }
            }
        }
    }

    // MARK: Title
    private var titleButton: some View {
        Button {
            self.datePickerDate = date
            self.showDatePicker = true
        } label: {
            (
                Text(self.date.formatted(.dateTime.month(.wide).day()) + ", ")
                    .foregroundStyle(Color.primary)
                + Text(self.date.formatted(.dateTime.year()))
                    .foregroundStyle(Color.primary)
                + Text(" ")
                + Text(Image(systemName: "chevron.right"))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.primary)
            )
            .font(.system(size: 34, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(self.date, style: .date))
    }

    // MARK: Week
    private var weekdaySymbols: some View {
        let symbols = self.calendar.shortStandaloneWeekdaySymbols
        let first = self.calendar.firstWeekday - 1
        let ordered = Array(symbols[first...] + symbols[..<first])

        return HStack(spacing: 0) {
            ForEach(ordered.indices, id: \.self) { index in
                Text(ordered[index])
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private var weekPager: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(Self.weekRange, id: \.self) { week in
                    WeekRow(
                        days: self.days(ofWeek: week),
                        selectedDate: self.date,
                        progress: self.progress,
                        onSelect: { day in
                            guard !self.calendar.isDate(day, inSameDayAs: self.date) else { return }
                            self.date = day
                            self.changeDateAction()
                        }
                    )
                    .containerRelativeFrame(.horizontal)
                    .id(week)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: self.$visibleWeek)
        .frame(height: 52)
        .onScrollPhaseChange { _, newPhase in
            switch newPhase {
            case .interacting:
                self.isUserScrolling = true
            case .idle:
                if self.isUserScrolling {
                    self.isUserScrolling = false
                    self.selectFirstDayOfVisibleWeek()
                }
            default:
                break
            }
        }
    }

    /// After the user swipes to another week, select the first day of that week
    private func selectFirstDayOfVisibleWeek() {
        guard let visibleWeek, visibleWeek != self.weekOffset(for: self.date) else { return }
        guard let firstDay = self.days(ofWeek: visibleWeek).first else { return }
        self.date = firstDay
        self.changeDateAction()
    }

    // MARK: Date helpers

    private func weekOffset(for date: Date) -> Int {
        Self.weekOffset(for: date, from: self.referenceWeekStart)
    }

    /// Number of weeks between the week of `reference` and the week of `date`
    private static func weekOffset(for date: Date, from reference: Date) -> Int {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start ?? date.startOfDay
        let days = DateHelper.numberOfDaysBetween(reference, and: weekStart)
        let offset = Int((Double(days) / 7).rounded(.down))
        return min(max(offset, self.weekRange.lowerBound), self.weekRange.upperBound)
    }

    private func days(ofWeek week: Int) -> [Date] {
        (0..<7).compactMap { day in
            self.calendar.date(byAdding: .day, value: week * 7 + day, to: self.referenceWeekStart)
        }
    }
}

private struct WeekRow: View {
    let days: [Date]
    let selectedDate: Date
    let progress: [Date: Double]
    let onSelect: (Date) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(self.days, id: \.self) { day in
                DayProgressCell(
                    date: day,
                    isSelected: Calendar.current.isDate(day, inSameDayAs: self.selectedDate),
                    progress: self.progress[day.startOfDay]
                )
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { self.onSelect(day) }
            }
        }
    }
}

private struct DayProgressCell: View {
    let date: Date
    let isSelected: Bool
    /// nil when the day has no habits
    let progress: Double?

    private let size: CGFloat = 44
    private let lineWidth: CGFloat = 4

    private var isToday: Bool { Calendar.current.isDateInToday(self.date) }
    private var value: Double { self.progress ?? 0 }

    var body: some View {
        ZStack {
            if self.isSelected {
                Circle()
                    .fill(Color.dayTrack)
                PieSlice(progress: self.value)
                    .fill(Color.dayProgress)
            } else {
                Circle()
                    .inset(by: self.lineWidth / 2)
                    .stroke(Color.dayTrack, lineWidth: self.lineWidth)
                Circle()
                    .inset(by: self.lineWidth / 2)
                    .trim(from: 0, to: self.value)
                    .stroke(Color.dayProgress, style: StrokeStyle(lineWidth: self.lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            Text(self.date.formatted(.dateTime.day()))
                .font(.system(size: 20, weight: self.isSelected ? .bold : .regular))
                .monospacedDigit()
                .foregroundStyle(self.isToday && !self.isSelected ? Color.red : Color.primary)
        }
        .frame(width: self.size, height: self.size)
        .animation(.easeInOut(duration: 0.3), value: self.value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(self.date, style: .date))
        .accessibilityValue(self.progress.map { "\(Int(($0 * 100).rounded()))%" } ?? "")
        .accessibilityAddTraits(self.isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Filled circle sector starting at 12 o'clock and growing clockwise
private struct PieSlice: Shape {
    var progress: Double

    var animatableData: Double {
        get { self.progress }
        set { self.progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clamped = min(max(self.progress, 0), 1)
        guard clamped > 0 else { return Path() }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * clamped),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

private extension Color {
    static let dayProgress = Color(red: 0.39, green: 0.77, blue: 0.39)
    static let dayTrack = Color(.systemGray5)
}

// MARK: - Day swipe

/// Lets the user swipe the content horizontally to go to the previous / next day.
/// The content follows the finger and slides out / in when the day changes.
private struct DaySwipeContainer<Content: View>: View {
    let onSwipe: (Int) -> Void
    @ViewBuilder let content: Content

    @State private var offset: CGFloat = 0
    @State private var width: CGFloat = 0
    @State private var axis: Axis?

    private let threshold: CGFloat = 80

    var body: some View {
        self.content
            .offset(x: self.offset)
            .opacity(self.width > 0 ? 1 - min(abs(self.offset) / self.width, 1) * 0.6 : 1)
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { self.width = $0 })
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        if self.axis == nil {
                            let horizontal = abs(value.translation.width) > abs(value.translation.height)
                            self.axis = horizontal ? .horizontal : .vertical
                        }
                        guard self.axis == .horizontal else { return }
                        self.offset = value.translation.width * 0.6
                    }
                    .onEnded { value in
                        defer { self.axis = nil }
                        guard self.axis == .horizontal else { return }

                        let distance = value.predictedEndTranslation.width
                        guard abs(distance) > self.threshold else {
                            withAnimation(.snappy) { self.offset = 0 }
                            return
                        }
                        // Swipe left -> next day, swipe right -> previous day
                        self.slide(direction: distance < 0 ? 1 : -1)
                    }
            )
    }

    private func slide(direction: Int) {
        let distance = self.width > 0 ? self.width : 400
        withAnimation(.easeIn(duration: 0.15)) {
            self.offset = -CGFloat(direction) * distance
        } completion: {
            self.onSwipe(direction)
            self.offset = CGFloat(direction) * distance
            withAnimation(.snappy) { self.offset = 0 }
        }
    }
}

private struct ContentView: View {
    @Binding var list: [Habit]
    @Binding var date: Date
    var onItemStatusAction: (Habit) -> Void
    var onItemAction: (Habit) -> Void

    var body: some View {
        List {
            ForEach($list) { $habit in
                let totalSteps = habit.frequency == .minTimes ? habit.frequencyType.minimumTimes : 0
                let dividerColor = $list.count == 1 ?
                    Color.black.opacity(0.0) : nil

                ListItem(
                    name: habit.name,
                    completedSteps: habit.completedCount,
                    totalSteps: totalSteps,
                    status: $habit.isChecked,
                    statusAction: {
                        var habit = habit
                        habit.isChecked = !habit.isChecked
                        onItemStatusAction(habit)
                    },
                    itemAction: { onItemAction(habit) }
                )
                .listRowSeparatorTint(dividerColor)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        // Keeps the empty area swipeable when there are no habits
        .contentShape(Rectangle())
    }
}
