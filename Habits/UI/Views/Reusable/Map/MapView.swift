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
    @Namespace var mapScope

    private let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.736946, longitude: -9.142685),
        latitudinalMeters: .mapDistance,
        longitudinalMeters: .mapDistance
    )
    var body: some View {
        MapReader { proxy in
            ZStack(alignment: .topTrailing) {
                Map(position: .constant(.region(location?.region ?? initialRegion)), scope: mapScope) {
                    if let location {
                        Marker("", coordinate: location.locationCoordinate)
                        MapCircle(center: location.locationCoordinate, radius: CLLocationDistance(5))
                                .foregroundStyle(.white.opacity(0.10))
                                .stroke(.red)
                                .mapOverlayLevel(level: .aboveLabels)
                    }

                }
                .onMapCameraChange {
                    location?.region = $0.region
                }
                .mapControlVisibility(.hidden)
                .onTapGesture { position in
                    if let coordinate: CLLocationCoordinate2D = proxy.convert(position, from: .local) {
                        var newRegion = location?.region ?? MKCoordinateRegion(
                            center: coordinate,
                            latitudinalMeters: .mapDistance,
                            longitudinalMeters: .mapDistance
                        )
                        newRegion.center = coordinate

                        withAnimation(.easeOut) {
                            location = Habit.Location(
                                latitude: coordinate.latitude,
                                longitude: coordinate.longitude,
                                region: newRegion
                            )
                         }

                        print(coordinate)
                    }
                }
                MapUserLocationButton(scope: mapScope)
                    .buttonBorderShape(.circle)
                    .padding(10)
            }
            .mapScope(mapScope)
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
                    self.parent.location = Habit.Location(
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

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.fillColor = UIColor.white.withAlphaComponent(0.10)
            circleRenderer.strokeColor = UIColor.red
            circleRenderer.lineWidth = 1.0
            return circleRenderer
        }
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        let marker = MKPointAnnotation()
        let trackingButton = MKUserTrackingButton(mapView: mapView)

        if let location {
            marker.coordinate = location.locationCoordinate
        }

        mapView.addSubview(trackingButton)

        trackingButton.layer.cornerRadius = trackingButton.frame.height / 2
        trackingButton.layer.masksToBounds = true
        trackingButton.layer.backgroundColor = UIColor.systemBackground.cgColor
        trackingButton.translatesAutoresizingMaskIntoConstraints = false
        trackingButton.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 10).isActive = true

        mapView.trailingAnchor.constraint(equalTo: trackingButton.trailingAnchor, constant: 10).isActive = true
        mapView.delegate = context.coordinator
        mapView.showsCompass = false
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat)
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
            let circle = MKCircle(center: location.locationCoordinate, radius: 5.0)

            marker.coordinate = location.locationCoordinate

            mapView.setCenter(location.locationCoordinate, animated: true)
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotation(marker)
            mapView.removeOverlays(mapView.overlays)
            mapView.addOverlay(circle)
        }
    }
}
