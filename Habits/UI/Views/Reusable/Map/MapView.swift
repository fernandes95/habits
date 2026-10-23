//
//  MapView.swift
//  Habits
//
//  Created by Tiago Fernandes on 25/03/2024.
//

import Foundation
import SwiftUI
import MapKit

struct MapView: View {
    @Binding var position: MKCoordinateRegion?
    @Binding var selectedLocation: Habit.Location?
    @Binding var canEdit: Bool
    @Namespace var mapScope

    /// Called with the visible region every time the camera stops moving
    private let onCameraChange: ((MKCoordinateRegion) -> Void)?

    /// Owned by the map so it remembers where the user left it (panning, user location button)
    @State private var camera: MapCameraPosition
    /// Last region the map reported, used to ignore our own updates coming back through `position`
    @State private var lastCameraRegion: RegionKey?

    private static let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.736946, longitude: -9.142685),
        latitudinalMeters: .mapDistance,
        longitudinalMeters: .mapDistance
    )

    init(
        position: Binding<MKCoordinateRegion?>,
        selectedLocation: Binding<Habit.Location?>,
        canEdit: Binding<Bool>,
        onCameraChange: ((MKCoordinateRegion) -> Void)? = nil
    ) {
        self._position = position
        self._selectedLocation = selectedLocation
        self._canEdit = canEdit
        self._camera = State(initialValue: .region(position.wrappedValue ?? Self.initialRegion))
        self.onCameraChange = onCameraChange
    }

    var body: some View {
        MapReader { proxy in
            ZStack(alignment: .topTrailing) {
                Map(position: self.$camera, scope: self.mapScope) {
                    if let selectedLocation {
                        Marker("", coordinate: selectedLocation.locationCoordinate)
                        MapCircle(center: selectedLocation.locationCoordinate, radius: .regionRadius)
                            .foregroundStyle(.white.opacity(0.10))
                            .stroke(.red)
                            .mapOverlayLevel(level: .aboveLabels)
                    }
                }
                .onMapCameraChange { (context: MapCameraUpdateContext) in
                    self.lastCameraRegion = RegionKey(context.region)
                    self.selectedLocation?.region = context.region
                    self.onCameraChange?(context.region)
                }
                .onChange(of: self.position.map(RegionKey.init)) { _, newRegion in
                    guard let newRegion, newRegion != self.lastCameraRegion,
                          let region = self.position
                    else {
                        return
                    }

                    withAnimation(.easeOut) {
                        self.camera = .region(region)
                    }
                }
                .mapControlVisibility(.hidden)
                .onTapGesture { position in
                    if let coordinate: CLLocationCoordinate2D = proxy.convert(position, from: .local) {
                        var newRegion = self.selectedLocation?.region ?? MKCoordinateRegion(
                            center: coordinate,
                            latitudinalMeters: .mapDistance,
                            longitudinalMeters: .mapDistance
                        )
                        newRegion.center = coordinate

                        withAnimation(.easeOut) {
                            self.selectedLocation = Habit.Location(
                                latitude: coordinate.latitude,
                                longitude: coordinate.longitude,
                                region: newRegion
                            )
                         }
                    }
                }
                if canEdit {
                    MapUserLocationButton(scope: mapScope)
                        .buttonBorderShape(.circle)
                        .padding(10)
                }
            }
            .mapScope(mapScope)
        }
    }
}

/// `MKCoordinateRegion` isn't `Equatable`, this is what `onChange` compares
private struct RegionKey: Equatable {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let latitudeDelta: CLLocationDegrees
    let longitudeDelta: CLLocationDegrees

    init(_ region: MKCoordinateRegion) {
        self.latitude = region.center.latitude
        self.longitude = region.center.longitude
        self.latitudeDelta = region.span.latitudeDelta
        self.longitudeDelta = region.span.longitudeDelta
    }
}
