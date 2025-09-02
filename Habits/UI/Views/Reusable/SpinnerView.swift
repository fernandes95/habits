//
//  SpinnerView.swift
//  Habits
//
//  Created by Tiago Fernandes on 02/09/2025.
//

import SwiftUI

struct SpinnerView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5, anchor: .center)
        }
    }
}

#Preview {
    SpinnerView()
}
