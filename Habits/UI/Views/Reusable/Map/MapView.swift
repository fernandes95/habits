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

    var body: some View {
        MapReader { proxy in
            Map(position: .constant(.region(location!.region))) {
                if let location {
                    Marker("", coordinate: location.locationCoordinate)
                }
            }
            .onMapCameraChange {
                location?.region = $0.region
            }
//            .mapControls {
//                MapUserLocationButton()
//            }
            .mapControlVisibility(.hidden)
            .onTapGesture { position in
                if let coordinate: CLLocationCoordinate2D = proxy.convert(position, from: .local) {
                    location = Habit.Location(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        region: MKCoordinateRegion(
                            center: coordinate,
                            latitudinalMeters: .mapDistance,
                            longitudinalMeters: .mapDistance
                        )
                    )
                    print(coordinate)
                }
            }
        }
    }
}

private struct MapViewFallback: UIViewRepresentable {
    @Binding var location: Habit.Location?
    private let initialLocation: MKCoordinateRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.736946, longitude: -9.142685),
            latitudinalMeters: .mapDistance,
            longitudinalMeters: .mapDistance
    )

    func makeCoordinator() -> MapViewCoordinator {
        MapViewCoordinator(self)
    }

    class MapViewCoordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewFallback

        init(_ parent: MapViewFallback) {
            self.parent = parent
        }

        @objc func onTap(_ sender: UITapGestureRecognizer? = nil) {
            let location = sender?.location(in: sender?.view)
            let mapView: MKMapView? = sender?.view as? MKMapView

            if let location {
                if let newCoord: CLLocationCoordinate2D = mapView?.convert(location, toCoordinateFrom: mapView) {
                    parent.location = Habit.Location(
                        latitude: newCoord.latitude,
                        longitude: newCoord.longitude,
                        region: MKCoordinateRegion(
                            center: newCoord,
                            latitudinalMeters: .mapDistance,
                            longitudinalMeters: .mapDistance
                        )
                    )
                    print("\(newCoord)")
                }
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            guard annotation is MKPointAnnotation else { return nil }

                let identifier = "Annotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView!.canShowCallout = true
                } else {
                    annotationView!.annotation = annotation
                }

                return annotationView
        }
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        let marker = MKPointAnnotation()

        if let location {
            marker.coordinate = location.locationCoordinate
        }

        mapView.delegate = context.coordinator
        mapView.preferredConfiguration = MKHybridMapConfiguration()
        mapView.addAnnotation(marker)
        mapView.setRegion(mapView.regionThatFits(location?.region ?? initialLocation), animated: true)
        mapView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(context.coordinator.onTap)
            )
        )

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let marker = MKPointAnnotation()

        if let location {
            marker.coordinate = location.locationCoordinate

            mapView.centerCoordinate = location.locationCoordinate
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotation(marker)
        }
    }
}
