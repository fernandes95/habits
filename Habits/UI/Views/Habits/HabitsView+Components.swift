//
//  HabitsView+Components.swift
//  Habits
//
//  Created by Tiago Fernandes on 10/10/2026.
//

import SwiftUI

extension HabitsView {
    /// Header of the today mode: the day and month, with the weekday below
    internal struct TodayHeaderView: View {
        let date: Date

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(self.date, format: .dateTime.day().month(.wide))
                    .font(.system(size: 34, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(self.date, format: .dateTime.weekday(.wide))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .accessibilityElement(children: .combine)
        }
    }

    /// Shown while habits have their location reminder on but `Always` location isn't allowed,
    /// tells how many habits can't remind and leads to the app's Settings
    internal struct LocationRemindersPausedBanner: View {
        let habitsCount: Int

        @Environment(\.openURL) private var openURL

        var body: some View {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "location.slash.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.stepAccent)
                        .frame(width: 32, height: 32)
                        .background(Color.stepAccent.opacity(0.18), in: .circle)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("habits_location_paused_title")
                            .font(.subheadline.weight(.semibold))
                        Text("habits_location_paused_message \(self.habitsCount)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        self.openURL(url)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("general_open_settings")
                        Image(systemName: "arrow.up.right")
                            .font(.footnote.weight(.semibold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemFill), in: .capsule)
                    .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("habits_location_paused_open_settings")
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
            .accessibilityElement(children: .contain)
        }
    }

    /// Header of the all habits mode
    internal struct AllHabitsHeaderView: View {
        var body: some View {
            Text("habits_mode_all")
                .font(.system(size: 34, weight: .bold))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
        }
    }

    internal struct WeekHeaderView: View {
        @Binding var date: Date
        let progress: [Date: Double]
        /// Calendar with the configured first day of the week
        let calendar: Calendar
        /// First day that can be selected, days before it can't be picked or swiped to
        let earliestDate: Date
        var changeDateAction: () -> Void

        @State private var showDatePicker = false
        @State private var datePickerDate = Date.now
        /// Week currently shown by the pager, relative to the week of `referenceWeekStart`
        @State private var visibleWeek: Int?
        /// True while the user is dragging the pager, used to tell user swipes from programmatic scrolls
        @State private var isUserScrolling = false

        @Environment(\.locale)
        private var locale: Locale

        private let referenceWeekStart: Date
        /// Amount of weeks reachable by swiping, before and after the current week (~19 years)
        private static let weekRange: ClosedRange<Int> = -1000...1000

        /// Weeks shown by the pager, from the week of `earliestDate`
        private var weeks: [Int] {
            Array(self.weekOffset(for: self.earliestDate)...Self.weekRange.upperBound)
        }

        init(
            date: Binding<Date>,
            progress: [Date: Double],
            calendar: Calendar,
            earliestDate: Date,
            changeDateAction: @escaping () -> Void
        ) {
            self._date = date
            self.progress = progress
            self.calendar = calendar
            self.earliestDate = earliestDate
            self.changeDateAction = changeDateAction
            let referenceWeekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start
                ?? Date.now.startOfDay
            self.referenceWeekStart = referenceWeekStart
            // Start the pager on the selected week before the first layout
            self._visibleWeek = State(
                initialValue: Self.weekOffset(for: date.wrappedValue, from: referenceWeekStart, calendar: calendar)
            )
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    self.titleButton
                    Spacer()
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
                    earliestDate: self.earliestDate,
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
            .onChange(of: self.calendar.firstWeekday) {
                // The start of the week changed: every week moved, keep the selected day in view
                self.visibleWeek = self.weekOffset(for: self.date)
            }
        }

        // MARK: Title
        private var titleButton: some View {
            Button {
                self.datePickerDate = date
                self.showDatePicker = true
            } label: {
                (
                    Text(self.date, format: .dateTime.month(.wide).day())
                        .foregroundStyle(Color.primary)
                    + Text(verbatim: ", ")
                        .foregroundStyle(Color.primary)
                    + Text(self.date, format: .dateTime.year())
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
            var calendar = self.calendar
            calendar.locale = self.locale
            // Some languages have long short names ("segunda" in Portuguese), keep 3 letters so they fit
            let symbols = calendar.shortStandaloneWeekdaySymbols.map { String($0.prefix(3)).capitalized }
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
                    ForEach(self.weeks, id: \.self) { week in
                        WeekRow(
                            days: self.days(ofWeek: week),
                            selectedDate: self.date,
                            progress: self.progress,
                            earliestDate: self.earliestDate,
                            onSelect: { day in
                                guard !self.calendar.isDate(day, inSameDayAs: self.date),
                                      day >= self.earliestDate else { return }
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
            // The week of the earliest date can start before it
            self.date = max(firstDay, self.earliestDate)
            self.changeDateAction()
        }

        // MARK: Date helpers

        private func weekOffset(for date: Date) -> Int {
            Self.weekOffset(for: date, from: self.referenceWeekStart, calendar: self.calendar)
        }

        /// Number of weeks between the week of `reference` and the week of `date`
        private static func weekOffset(for date: Date, from reference: Date, calendar: Calendar) -> Int {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date.startOfDay
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
        /// Days before it are dimmed and can't be selected
        let earliestDate: Date
        let onSelect: (Date) -> Void

        var body: some View {
            HStack(spacing: 0) {
                ForEach(self.days, id: \.self) { day in
                    let isEnabled = day >= self.earliestDate
                    DayProgressCell(
                        date: day,
                        isSelected: Calendar.current.isDate(day, inSameDayAs: self.selectedDate),
                        progress: self.progress[day.startOfDay]
                    )
                    .opacity(isEnabled ? 1 : 0.3)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { self.onSelect(day) }
                    .disabled(!isEnabled)
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

    // MARK: Day swipe

    /// Lets the user swipe the content horizontally to go to the previous / next day.
    /// The content follows the finger and slides out / in when the day changes.
    internal struct DaySwipeContainer<Content: View>: View {
        /// False when there's no day in that direction (-1 previous, 1 next), the content bounces back
        var canSwipe: (Int) -> Bool = { _ in true }
        let onSwipe: (Int) async -> Void
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
                            // Swipe right -> previous day, it resists when there's no day to go to
                            let direction = value.translation.width > 0 ? -1 : 1
                            let resistance: CGFloat = self.canSwipe(direction) ? 0.6 : 0.15
                            self.offset = value.translation.width * resistance
                        }
                        .onEnded { value in
                            defer { self.axis = nil }
                            guard self.axis == .horizontal else { return }

                            let distance = value.predictedEndTranslation.width
                            let direction = distance < 0 ? 1 : -1
                            guard abs(distance) > self.threshold, self.canSwipe(direction) else {
                                withAnimation(.snappy) { self.offset = 0 }
                                return
                            }
                            // Swipe left -> next day, swipe right -> previous day
                            self.slide(direction: direction)
                        }
                )
        }

        private func slide(direction: Int) {
            let distance = width > 0 ? width : 400
            withAnimation(.easeIn(duration: 0.15)) {
                offset = -CGFloat(direction) * distance
            } completion: {
                Task {
                    // Load the new day while the list is off screen, then slide it in
                    await onSwipe(direction)
                    offset = CGFloat(direction) * distance
                    withAnimation(.snappy) { offset = 0 }
                }
            }
        }
    }
}
