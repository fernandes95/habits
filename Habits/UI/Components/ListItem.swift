//
//  ListItem.swift
//  Habits
//
//  Created by Tiago Fernandes on 23/01/2024.
//

import SwiftUI
import CoreLocation

enum ListItemType {
    /// Checkbox, name, progress label and detail arrow
    case regularListItem
    /// Only the name and the detail arrow
    case noStatusListItem
}

struct ListItem: View {
    /// Space between the row edges and its content. Lists give the row no insets,
    /// see `listItemRowInsets`, so the hours can scroll edge to edge
    static let horizontalPadding: CGFloat = 16

    let name: String
    var type: ListItemType = .regularListItem
    var completedSteps: Int = 0
    var totalSteps: Int = 0
    var label: String?
    /// Shown under the name when set
    var location: Habit.Location?
    /// Distance from the user to `location`, nil while the user location is unknown
    var locationDistance: CLLocationDistance?
    /// The location reminder is on but can't remind, `Always` location isn't allowed
    var isLocationReminderPaused: Bool = false
    /// Reminder hours of the day, shown under the name when there are any
    var hourChips: [Habit.HourChip] = []
    var hourAction: (Habit.HourChip) -> Void = { _ in }
    @Binding var status: Bool
    let statusAction: () -> Void
    let itemAction: () -> Void

    /// Changes on every checkbox tap, so the haptic plays on taps and not when the list reloads
    @State private var statusTaps: Int = 0
    @State private var statusFeedback: SensoryFeedback?

    /// Briefly checked after doing an hour that isn't the last one, the habit itself stays unchecked
    @State private var isShowingHourCheck: Bool = false

    private var hasHourChips: Bool {
        self.type == .regularListItem && !self.hourChips.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            self.mainRow
                .padding(.horizontal, Self.horizontalPadding)

            if self.hasHourChips {
                // Lined up with the name, past the checkbox, but scrolls out to the row edges
                HourChipsRow(
                    chips: self.hourChips,
                    leadingMargin: Self.horizontalPadding + CheckBoxStyle.defaultRingSize + 8,
                    trailingMargin: Self.horizontalPadding,
                    action: self.hourAction
                )
                .padding(.bottom, 12)
            }
        }
        // The divider ends where the content does, not at the row edge
        .alignmentGuide(.listRowSeparatorTrailing) { $0.width - Self.horizontalPadding }
    }

    private var mainRow: some View {
        HStack {
            switch self.type {
            case .regularListItem:
                Toggle(isOn: self.checkboxStatus) {
                    self.title
                }
                .padding(.trailing)
                .padding(.top)
                .padding(.bottom, self.hasHourChips ? 8 : nil)
                .toggleStyle(CheckBoxStyle(completed: completedSteps, total: totalSteps))
                .onTapGesture {
                    self.statusFeedback = self.feedbackForStatusTap
                    self.statusTaps += 1
                    self.showHourCheckIfNeeded()
                    statusAction()
                }
                .sensoryFeedback(trigger: self.statusTaps) { _, _ in self.statusFeedback }
            case .noStatusListItem:
                self.title
                    // Same height as the checkbox, so every list has the same row height
                    .frame(minHeight: 36)
                    .padding([.vertical, .trailing])
            }

            Spacer(minLength: 8)

            if self.type == .regularListItem, let progressLabel {
                Text(progressLabel)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Button(action: { itemAction() }, label: {
                Image(systemName: "chevron.right")
                    .padding(.leading)
            })
            .padding([.vertical, .leading])
        }
    }

    /// The habit status, or checked for a moment after doing an hour
    private var checkboxStatus: Binding<Bool> {
        Binding(
            get: { self.status || self.isShowingHourCheck },
            set: { self.status = $0 }
        )
    }

    /// Without a goal a tap does the selected or first missed hour, the checkbox shows it checked and then unchecked again
    /// for the next hour. The last hour checks the habit, so it stays checked
    private func showHourCheckIfNeeded() {
        guard self.hasHourChips, self.totalSteps == 0, !self.status,
              self.hourChips.contains(where: { $0.state == .selected || $0.state == .missed }) else { return }

        self.isShowingHourCheck = true
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation { self.isShowingHourCheck = false }
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(self.name)
                .strikethrough(self.type == .regularListItem && self.status)
                .lineLimit(1)

            if let location {
                HabitLocationLabel(
                    location: location,
                    distance: self.locationDistance,
                    isCompleted: self.type == .regularListItem && self.status,
                    isReminderPaused: self.isLocationReminderPaused
                )
            }
        }
    }

    /// Success when the tap checks the habit, a tick for each step of a goal, a light tap when it unchecks
    private var feedbackForStatusTap: SensoryFeedback {
        if self.status { return .impact(weight: .light) }
        if self.totalSteps > 0 && self.completedSteps + 1 < self.totalSteps { return .increase }
        return .success
    }

    private var progressLabel: String? {
        if let label { return label }
        return self.totalSteps > 0 ? "\(completedSteps)/\(totalSteps)" : nil
    }
}

extension View {
    /// No side insets, `ListItem` pads its own content. Top and bottom keep the list's default spacing.
    /// Set on the list row, outside any wrapper view
    func listItemRowInsets() -> some View {
        self.listRowInsets(EdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0))
    }
}

extension Color {
    static let stepAccent = Color(red: 0.95, green: 0.76, blue: 0.20)
    static let stepTrack  = Color(white: 0.80)
}

struct SegmentedRing: View {
    let completed: Int
    let total: Int
    var lineWidth: CGFloat = 3
    var gapDegrees: Double = 14

    private var segmentCount: Int { max(total, 1) }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let radius = (side - lineWidth) / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let sweep = 360.0 / Double(segmentCount)
            // Keep the gap sensible when there are many segments.
            let gap = min(gapDegrees, sweep * 0.35)

            ZStack {
                ForEach(0..<segmentCount, id: \.self) { index in
                    Path { path in
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: .degrees(Double(index) * sweep - 90 + gap / 2),
                            endAngle: .degrees(Double(index + 1) * sweep - 90 - gap / 2),
                            clockwise: false
                        )
                    }
                    .stroke(
                        index < completed ? Color.stepAccent : Color.stepTrack,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                }
            }
        }
    }
}

/// Continuous ring filling clockwise from the top, for goals with too many steps to show as segments
struct ProgressRing: View {
    let completed: Int
    let total: Int
    var lineWidth: CGFloat = 3

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(Double(completed) / Double(total), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .inset(by: lineWidth / 2)
                .stroke(Color.dayTrack, lineWidth: lineWidth)
            Circle()
                .inset(by: lineWidth / 2)
                .trim(from: 0, to: progress)
                .stroke(Color.stepAccent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}

struct CheckBoxStyle: ToggleStyle {
    static let defaultRingSize: CGFloat = 36

    var completed: Int = 0
    var total: Int
    var ringSize: CGFloat = Self.defaultRingSize
    var markSize: CGFloat = 20

    /// Most steps shown as segments, more than that and the segments get too small to read
    static let maxSegments: Int = 8

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            ZStack {
                if total > Self.maxSegments {
                    ProgressRing(completed: completed, total: total)
                        .frame(width: ringSize, height: ringSize)
                } else if total > 1 {
                    SegmentedRing(completed: completed, total: total)
                        .frame(width: ringSize, height: ringSize)
                }

                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        configuration.isOn ? Color.black : Color.primary,
                        Color.stepAccent
                    )
                    .frame(width: markSize, height: markSize)
            }
            .frame(width: ringSize, height: ringSize)

            configuration.label
        }
    }
}

/// Reminder hours of a habit, scrolled so the selected hour is always in view.
/// Done hours undo with a tap, missed hours get selected with a tap, upcoming hours can't be tapped.
struct HourChipsRow: View {
    let chips: [Habit.HourChip]
    var leadingMargin: CGFloat = 0
    var trailingMargin: CGFloat = 0
    let action: (Habit.HourChip) -> Void

    @Environment(\.locale) private var locale
    @Environment(\.daySwipeLock) private var daySwipeLock

    private var selectedId: UUID? {
        self.chips.first(where: { $0.state == .selected })?.id
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(self.chips) { chip in
                        Button {
                            self.action(chip)
                        } label: {
                            HourChipView(chip: chip, time: self.time(of: chip.hour))
                        }
                        .buttonStyle(.plain)
                        .allowsHitTesting(chip.state != .upcoming)
                        .id(chip.id)
                    }
                }
                // Room for the selected outline
                .padding(.vertical, 1)
            }
            .contentMargins(.leading, self.leadingMargin, for: .scrollContent)
            .contentMargins(.trailing, self.trailingMargin, for: .scrollContent)
            // Scrolling the hours in the week view doesn't change the day too
            .onScrollPhaseChange { _, phase in
                self.daySwipeLock?.isLocked = phase != .idle
            }
            .onAppear {
                self.scrollToSelected(proxy)
            }
            .onChange(of: self.selectedId) {
                withAnimation { self.scrollToSelected(proxy) }
            }
        }
    }

    private func scrollToSelected(_ proxy: ScrollViewProxy) {
        guard let selectedId else { return }
        // No anchor scrolls only when the hour is out of view
        proxy.scrollTo(selectedId)
    }

    /// Two digit hour, same as the reminder hours of the habit
    private func time(of hour: Hour) -> String {
        hour.date.formatted(.dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits).locale(self.locale))
    }
}

private struct HourChipView: View {
    let chip: Habit.HourChip
    let time: String

    var body: some View {
        HStack(spacing: 6) {
            switch self.chip.state {
            case .done:
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
            case .missed:
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(Color.stepAccent)
            case .selected, .upcoming:
                EmptyView()
            }

            Text(verbatim: self.time)
                .monospacedDigit()
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(self.foreground)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(self.background, in: .capsule)
        .overlay {
            Capsule().strokeBorder(self.border, lineWidth: 1.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: self.time))
        .accessibilityValue(Text(self.stateName))
    }

    private var foreground: Color {
        self.chip.state == .upcoming ? .secondary : .primary
    }

    private var background: Color {
        switch self.chip.state {
        case .done: Color.dayProgress.opacity(0.2)
        case .missed: .clear
        case .selected: Color(.systemGray4)
        case .upcoming: Color(.systemGray6)
        }
    }

    private var border: Color {
        switch self.chip.state {
        case .missed: Color.stepAccent
        case .selected: Color.primary.opacity(0.8)
        case .done, .upcoming: .clear
        }
    }

    private var stateName: LocalizedStringKey {
        switch self.chip.state {
        case .done: "habit_hour_done"
        case .missed: "habit_hour_missed"
        case .selected: "habit_hour_selected"
        case .upcoming: "habit_hour_upcoming"
        }
    }
}

/// Habit location shown under the habit name.
/// Inside the habit region it reads "You're here • Place", outside it reads "Place • 1.2 km".
/// Once the habit is done it only shows the place.
/// While the reminder is paused it reads "Reminder paused • Place".
struct HabitLocationLabel: View {
    let location: Habit.Location
    /// Distance from the user to the location, nil while the user location is unknown
    let distance: CLLocationDistance?
    /// Done habits don't need to tell where the user is
    var isCompleted: Bool = false
    /// The reminder is on but can't remind, `Always` location isn't allowed
    var isReminderPaused: Bool = false

    private var shownDistance: CLLocationDistance? {
        self.isCompleted ? nil : self.distance
    }

    /// Same radius used to monitor the habit region
    private var isInside: Bool {
        guard let distance = self.shownDistance else { return false }
        return distance <= .regionRadius
    }

    var body: some View {
        if self.isReminderPaused {
            self.pausedBody
        } else {
            self.locationBody
        }
    }

    /// The words are there too, so it doesn't rely on the icon alone
    private var pausedBody: some View {
        HStack(spacing: 4) {
            Group {
                Image(systemName: "location.slash.fill")
                    .font(.caption)
                Text("habit_location_reminder_paused")
                    .fontWeight(.semibold)
                    .fixedSize()
            }
            .foregroundStyle(Color.stepAccent)
            self.separator
            self.placeName
        }
        .font(.subheadline)
        .foregroundStyle(Color.secondary)
        .accessibilityElement(children: .combine)
    }

    private var locationBody: some View {
        HStack(spacing: 4) {
            Image(systemName: "location.fill")
                .font(.caption)
                .foregroundStyle(self.isInside ? Color.blue : Color.secondary)

            if self.isInside {
                Text("habit_location_here")
                    .fontWeight(.semibold)
                    .fixedSize()
                self.separator
                self.placeName
            } else {
                self.placeName
                if let formattedDistance {
                    self.separator
                    Text(verbatim: formattedDistance)
                        .monospacedDigit()
                        .fixedSize()
                }
            }
        }
        .font(.subheadline)
        .foregroundStyle(self.isInside ? Color.primary : Color.secondary)
        .accessibilityElement(children: .combine)
    }

    /// Name saved with the habit, older habits and pins dropped offline have none
    private var placeName: some View {
        Group {
            if let name = self.location.place?.name {
                Text(verbatim: name)
            } else {
                Text("habit_location_pinned")
            }
        }
        .lineLimit(1)
    }

    private var separator: some View {
        Text(verbatim: "•")
            .accessibilityHidden(true)
    }

    private var formattedDistance: String? {
        guard let distance = self.shownDistance else { return nil }
        return Measurement(value: distance, unit: UnitLength.meters).formatted(
            .measurement(
                width: .abbreviated,
                usage: .road,
                // 680 m, 1.2 km, 12 km
                numberFormatStyle: .number.precision(.significantDigits(1...2))
            )
        )
    }
}

#Preview {
    let location = Habit.Location(
        latitude: 38.7369,
        longitude: -9.1426,
        region: .around(CLLocationCoordinate2D(latitude: 38.7369, longitude: -9.1426))
    )

    VStack {
        ListItem(
            name: "Gym",
            location: location,
            locationDistance: 40,
            status: .constant(false),
            statusAction: {},
            itemAction: {}
        )
        ListItem(
            name: "Read 20 pages",
            totalSteps: 3,
            location: location,
            locationDistance: 1200,
            status: .constant(false),
            statusAction: {},
            itemAction: {}
        )
        ListItem(
            name: "Drink water",
            completedSteps: 4,
            totalSteps: 10,
            status: .constant(false),
            statusAction: {},
            itemAction: {}
        )
        ListItem(
            name: "LONG NAMEEEEEEEEEEEEEEEEEEEEE shfsjdfnsjdfbsljdfbs",
            status: .constant(false),
            statusAction: {},
            itemAction: {}
        )
        ListItem(name: "Test 1", status: .constant(true), statusAction: {}, itemAction: {})
        ListItem(
            name: "No status",
            type: .noStatusListItem,
            status: .constant(false),
            statusAction: {},
            itemAction: {}
        )
    }
}
