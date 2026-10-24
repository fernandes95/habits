//
//  HabitsMapView.swift
//  Habits
//
//  Created by Tiago Fernandes on 21/10/2026.
//

import SwiftUI
import MapKit

/// Map with a pin, and the monitored region around it, for every habit with a location.
/// Tapping a pin opens its habit, tapping anywhere else starts a new habit at that place.
struct HabitsMapView: View {
    @EnvironmentObject
    private var appRouter: AppRouter

    @EnvironmentObject
    private var router: HabitsRouter

    @EnvironmentObject
    private var state: MainState

    @State private var pins: [HabitPin] = []
    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        MapReader { (proxy: MapProxy) in
            Map(position: self.$camera) {
                UserAnnotation()

                ForEach(self.pins) { (pin: HabitPin) in
                    MapCircle(center: pin.coordinate, radius: .regionRadius)
                        .foregroundStyle(Color.accentColor.opacity(0.10))
                        .stroke(Color.accentColor)
                        .mapOverlayLevel(level: .aboveLabels)

                    // A button, so tapping the pin doesn't also count as a tap on the map
                    Annotation(pin.name, coordinate: pin.coordinate, anchor: .bottom) {
                        Button {
                            self.router.push(HabitDetailView(habit: pin.habit))
                        } label: {
                            HabitPinLabel(name: pin.name)
                        }
                        .buttonStyle(.plain)
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .onTapGesture { (position: CGPoint) in
                if let coordinate: CLLocationCoordinate2D = proxy.convert(position, from: .local) {
                    self.addHabit(at: coordinate)
                }
            }
        }
        .onAppear {
            self.reloadPins()
        }
        .onChange(of: self.state.habits) {
            // Habits were added, edited or removed
            self.reloadPins()
        }
    }

    /// Opens the new habit sheet with `coordinate` already picked as its location
    private func addHabit(at coordinate: CLLocationCoordinate2D) {
        // Only prompts the first time, while the location permission wasn't asked yet
        self.state.requestLocation()

        let location = Habit.Location(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            region: .around(coordinate)
        )
        self.appRouter.presentSheet(NewHabitContentView(location: location))
    }

    private func reloadPins() {
        let pins: [HabitPin] = self.state.getLocationHabits().compactMap(HabitPin.init(habit:))
        guard pins != self.pins else { return }

        self.pins = pins
        if let camera = Self.camera(fitting: pins) {
            withAnimation(.easeOut) {
                self.camera = camera
            }
        }
    }

    /// Camera showing every pin with some margin, `nil` when there are no pins
    private static func camera(fitting pins: [HabitPin]) -> MapCameraPosition? {
        guard let first = pins.first else { return nil }
        guard pins.count > 1 else { return .region(.around(first.coordinate)) }

        let rect: MKMapRect = pins.reduce(MKMapRect.null) { (rect: MKMapRect, pin: HabitPin) in
            let point = MKMapPoint(pin.coordinate)
            return rect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
        }
        let margin: Double = max(rect.width, rect.height) * 0.25
        return .rect(rect.insetBy(dx: -margin, dy: -margin))
    }
}

/// Habit name in an accent colored glass capsule, with a dot on the habit coordinate under it
private struct HabitPinLabel: View {
    let name: String

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 8) {
                Image(systemName: "mappin")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24, height: 24)
                    .background(.white, in: .circle)

                CappedWidthLayout(maxWidth: 160) {
                    Text(verbatim: self.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }
            .padding(.leading, 5)
            .padding(.trailing, 12)
            .padding(.vertical, 5)
            .accentGlassCapsule()

            Circle()
                .fill(Color.accentColor)
                .stroke(.white, lineWidth: 1.5)
                .frame(width: 8, height: 8)
        }
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// Sizes its child to its ideal width capped to `maxWidth`, so short names stay compact and long ones truncate.
/// Annotations lay their content out at its ideal size, where a `.frame(maxWidth:)` wouldn't truncate.
private struct CappedWidthLayout: Layout {
    let maxWidth: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let subview = subviews.first else { return .zero }

        let idealWidth: CGFloat = subview.sizeThatFits(.unspecified).width
        return subview.sizeThatFits(ProposedViewSize(width: min(idealWidth, self.maxWidth), height: nil))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
    }
}

private extension View {
    /// Accent tinted Liquid Glass capsule on iOS 26, solid accent capsule on older versions.
    /// The glass is only the background, so it doesn't tone down the colors of the content.
    @ViewBuilder
    func accentGlassCapsule() -> some View {
        if #available(iOS 26.0, *) {
            self.background {
                Color.clear
                    .glassEffect(.regular.tint(Color.accentColor.opacity(0.85)).interactive(), in: .capsule)
            }
        } else {
            self.background(Color.accentColor, in: .capsule)
        }
    }
}

/// What the map needs from a habit, only habits with a location have one
private struct HabitPin: Identifiable, Equatable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    /// Opened in the detail screen when the pin is tapped
    let habit: Habit

    init?(habit: Habit) {
        guard let location = habit.location else { return nil }

        self.id = habit.id
        self.name = habit.name
        self.coordinate = location.locationCoordinate
        self.habit = habit
    }

    static func == (lhs: HabitPin, rhs: HabitPin) -> Bool {
        return lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.coordinate.latitude == rhs.coordinate.latitude &&
            lhs.coordinate.longitude == rhs.coordinate.longitude &&
            lhs.habit == rhs.habit
    }
}
