//
//  MapView.swift
//  Habits
//
//  Created by Tiago Fernandes on 25/03/2024.
//

import Foundation
import SwiftUI
import MapKit

@available(iOS 17.0, *)
struct MapView: View {
    @State private var locationSelected: CLLocationCoordinate2D = 
        CLLocationCoordinate2D(latitude: 38.736946, longitude: -9.142685)
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
            Map(
                position: $cameraPosition
            ) {
                Marker("", coordinate: $locationSelected.wrappedValue)
            }
            .frame(height: 250)
            .mapControlVisibility(.hidden)
            .onTapGesture { position in
                if let coordinate: CLLocationCoordinate2D = proxy.convert(position, from: .local) {
                    locationSelected = coordinate
                    print(coordinate)
                }
            }
            .cornerRadius(10)
        }
    }
}
