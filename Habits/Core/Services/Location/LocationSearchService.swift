//
//  LocationSearchService.swift
//  Habits
//
//  Created by Tiago Fernandes on 28/08/2025.
//
import MapKit
import Observation
import OSLog

@Observable
class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {
    private let completer: MKLocalSearchCompleter

    var completions = [LocationSearchCompletion]()

    init(completer: MKLocalSearchCompleter) {
        self.completer = completer
        super.init()
        self.completer.delegate = self
        self.completer.resultTypes = [.address, .pointOfInterest]
    }

    func update(region: MKCoordinateRegion) {
        completer.region = region
    }

    func update(queryFragment: String) {
        guard !queryFragment.isEmpty else {
            completer.cancel()
            completions = []
            return
        }

        completer.queryFragment = queryFragment
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results.map(LocationSearchCompletion.init)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Logger.location.error("Location search failed: \(error.localizedDescription)")
    }

    /// Finds the place of the tapped suggestion, not a new text search that can land on another match
    func search(for completion: LocationSearchCompletion) async throws -> LocationSearchResult? {
        let request = MKLocalSearch.Request(completion: completion.completion)
        let response = try await MKLocalSearch(request: request).start()

        guard let location = response.mapItems.first?.placemark.location?.coordinate else { return nil }

        return LocationSearchResult(location: location)
    }

    func search(with query: String, coordinate: CLLocationCoordinate2D? = nil) async throws -> [LocationSearchResult] {
        let mapKitRequest = MKLocalSearch.Request()
        mapKitRequest.naturalLanguageQuery = query
        if let coordinate {
            mapKitRequest.region = .init(.init(origin: .init(coordinate), size: .init(width: 1, height: 1)))
        }
        let search = MKLocalSearch(request: mapKitRequest)

        let response = try await search.start()

        return response.mapItems.compactMap { mapItem in
            guard let location = mapItem.placemark.location?.coordinate else { return nil }

            return LocationSearchResult(location: location)
        }
    }
}
