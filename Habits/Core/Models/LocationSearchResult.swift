//
//  LocationSearchResult.swift
//  Habits
//
//  Created by Tiago Fernandes on 28/08/2025.
//

import Foundation
import MapKit

struct LocationSearchResult: Identifiable, Hashable {
    let id = UUID()
    let location: CLLocationCoordinate2D

    static func == (lhs: LocationSearchResult, rhs: LocationSearchResult) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
