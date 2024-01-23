//
//  GetHeightModifier.swift
//  Habits
//
//  Created by Tiago Fernandes on 23/01/2024.
//

import SwiftUI

struct RelativeHeightSheetContent : ViewModifier {
    @State var detentHeight: CGFloat = 0
    
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
        }
    }
    
    internal func body(content: Content) -> some View {
        content
            .background(sizeView)
            .onPreferenceChange(HeightPreferenceKey.self) { height in
                if let height {
                    self.detentHeight = height
                }
            }
            .presentationDetents([.height(self.detentHeight)])
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat?

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        guard let nextValue = nextValue() else { return }
        value = nextValue
    }
}
