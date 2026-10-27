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
    let name: String
    var type: ListItemType = .regularListItem
    var completedSteps: Int = 0
    var totalSteps: Int = 0
    var label: String?
    /// Shown under the name when set
    var location: Habit.Location?
    /// Distance from the user to `location`, nil while the user location is unknown
    var locationDistance: CLLocationDistance?
    @Binding var status: Bool
    let statusAction: () -> Void
    let itemAction: () -> Void

    var body: some View {
        HStack {
            switch self.type {
            case .regularListItem:
                Toggle(isOn: self.$status) {
                    self.title
                }
                .padding([.vertical, .trailing])
                .toggleStyle(CheckBoxStyle(completed: completedSteps, total: totalSteps))
                .onTapGesture { statusAction() }
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

    private var title: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(self.name)
                .strikethrough(self.type == .regularListItem && self.status)
                .lineLimit(1)

            if let location {
                HabitLocationLabel(
                    location: location,
                    distance: self.locationDistance,
                    isCompleted: self.type == .regularListItem && self.status
                )
            }
        }
    }

    private var progressLabel: String? {
        if let label { return label }
        return self.totalSteps > 0 ? "\(completedSteps)/\(totalSteps)" : nil
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

struct CheckBoxStyle: ToggleStyle {
    var completed: Int = 0
    var total: Int
    var ringSize: CGFloat = 36
    var markSize: CGFloat = 20

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            ZStack {
                if total > 1 {
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

/// Habit location shown under the habit name.
/// Inside the habit region it reads "You're here • Place", outside it reads "Place • 1.2 km".
/// Once the habit is done it only shows the place.
struct HabitLocationLabel: View {
    let location: Habit.Location
    /// Distance from the user to the location, nil while the user location is unknown
    let distance: CLLocationDistance?
    /// Done habits don't need to tell where the user is
    var isCompleted: Bool = false

    private var shownDistance: CLLocationDistance? {
        self.isCompleted ? nil : self.distance
    }

    /// Same radius used to monitor the habit region
    private var isInside: Bool {
        guard let distance = self.shownDistance else { return false }
        return distance <= .regionRadius
    }

    var body: some View {
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
