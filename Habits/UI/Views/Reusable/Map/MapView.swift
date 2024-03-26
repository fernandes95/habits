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
    @Binding var location: Habit.Location?

    var body: some View {
        if #available(iOS 17.0, *) {
            MapViewRecent(location: $location)
        } else {
            MapViewFallback(location: $location)
        }
    }
}

@available(iOS 17.0, *)
private struct MapViewRecent: View {
    @Binding var location: Habit.Location?

    @State private var cameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 38.736946, longitude: -9.142685),
            distance: 3729,
            heading: 92,
            pitch: 0
        )
    )

    var body: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                if let location {
                    Marker("", coordinate: location.locationCoordinate)
                }
            }
//            .mapControls {
//                MapUserLocationButton()
//            }
            .mapControlVisibility(.hidden)
            .onTapGesture { position in
                if let coordinate: CLLocationCoordinate2D = proxy.convert(position, from: .local) {
                    location = Habit.Location(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )
                    print(coordinate)
                }
            }
        }
    }
}

private struct MapViewFallback: UIViewRepresentable {
    @Binding var location: Habit.Location?

    private let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.736946, longitude: -9.142685),
        latitudinalMeters: CLLocationDistance(exactly: 3000)!,
        longitudinalMeters: CLLocationDistance(exactly: 3000)!
    )

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        let marker = MKPointAnnotation()

        if let location {
            marker.coordinate = location.locationCoordinate
        }

        mapView.preferredConfiguration = MKHybridMapConfiguration()
        mapView.addAnnotation(marker)
        mapView.setRegion(mapView.regionThatFits(initialRegion), animated: true)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.centerCoordinate = location?.locationCoordinate ?? initialRegion.center
    }
}
