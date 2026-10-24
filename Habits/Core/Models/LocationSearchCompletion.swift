//
//  LocationSearchCompletion.swift
//  Habits
//
//  Created by Tiago Fernandes on 28/08/2025.
//

import Foundation
import MapKit

struct LocationSearchCompletion: Identifiable {
    let id = UUID()
    let title: String
    let subTitle: String
    let completion: MKLocalSearchCompletion

    init(_ completion: MKLocalSearchCompletion) {
        self.title = completion.title
        self.subTitle = completion.subtitle
        self.completion = completion
    }
}
