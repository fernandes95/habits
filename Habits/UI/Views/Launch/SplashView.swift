//
//  SplashView.swift
//  Habits
//
//  Created by Tiago Fernandes on 23/10/2026.
//

import SwiftUI

struct SplashValues {
    var lensScale: CGFloat = 0
    var lensOpacity: Double = 0
    var hScale: CGFloat = 0.6
    var mapScale: CGFloat = 1.06
}

private extension UnitCurve {
    static let lensEase = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.33, y: 0),
        endControlPoint: UnitPoint(x: 0.2, y: 1)
    )
    static let mapEase = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.2, y: 0.7),
        endControlPoint: UnitPoint(x: 0.2, y: 1)
    )
}

struct SplashView: View {
    var onFinished: () -> Void = {}
    @State private var trigger = false

    var body: some View {
        KeyframeAnimator(initialValue: SplashValues(), trigger: trigger) { value in
            ZStack {
                Color.clear
                    .overlay(
                        Image("SplashBackground")
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(value.mapScale)
                    )
                    .clipped()

                ZStack {
                    Image("SplashRings")
                    Image("SplashLens")
                    Image("SplashH").scaleEffect(value.hScale)
                }
                .frame(width: 292, height: 292)
                .scaleEffect(value.lensScale)
                .opacity(value.lensOpacity)
            }
            .ignoresSafeArea()
        } keyframes: { _ in
            KeyframeTrack(\.lensScale) {
                LinearKeyframe(0, duration: 0.24)                                  // 0–8%
                LinearKeyframe(1.12, duration: 0.96, timingCurve: .lensEase)       // →40%
                LinearKeyframe(1.0, duration: 0.30, timingCurve: .lensEase)        // →50%
                LinearKeyframe(1.05, duration: 0.75, timingCurve: .lensEase)       // →75%
                LinearKeyframe(1.0, duration: 0.75, timingCurve: .lensEase)        // →100%
            }
            KeyframeTrack(\.lensOpacity) {
                LinearKeyframe(0, duration: 0.24)                                  // 0–8%
                LinearKeyframe(1, duration: 0.18, timingCurve: .lensEase)          // →14%
            }
            KeyframeTrack(\.hScale) {
                LinearKeyframe(0.6, duration: 0.6)                                 // 0–20%
                LinearKeyframe(1.04, duration: 0.84, timingCurve: .lensEase)       // →48%
                LinearKeyframe(1.0, duration: 0.24, timingCurve: .lensEase)        // →56%
            }
            KeyframeTrack(\.mapScale) {
                LinearKeyframe(1.0, duration: 3.0, timingCurve: .mapEase)
            }
        }
        .task {
            trigger.toggle()
            try? await Task.sleep(for: .seconds(3))
            onFinished()
        }
    }
}

#Preview { SplashView() }
