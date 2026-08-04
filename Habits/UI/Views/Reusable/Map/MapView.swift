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

    private let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.736946, longitude: -9.142685),
        latitudinalMeters: .mapDistance,
        longitudinalMeters: .mapDistance
    )
    var body: some View {
        MapReader { proxy in
            ZStack(alignment: .topTrailing) {
                Map(position: .constant(
                        .region(position ?? MapCameraPosition.automatic.region ?? initialRegion)
                    ),
                    scope: mapScope) {
                    if let selectedLocation {
                        Marker("", coordinate: selectedLocation.locationCoordinate)
                        MapCircle(center: selectedLocation.locationCoordinate, radius: CLLocationDistance(5))
                                .foregroundStyle(.white.opacity(0.10))
                                .stroke(.red)
                                .mapOverlayLevel(level: .aboveLabels)
                    }

                }
                .onMapCameraChange {
                    self.selectedLocation?.region = $0.region
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

                        print(coordinate)
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
