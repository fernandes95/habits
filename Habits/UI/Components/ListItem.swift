//
//  ListItem.swift
//  Habits
//
//  Created by Tiago Fernandes on 23/01/2024.
//

import SwiftUI

struct ListItem: View {
    let name: String
    var completedSteps: Int = 0
    var totalSteps: Int = 0
    @Binding var status: Bool
    let statusAction: () -> Void
    let itemAction: () -> Void

    var body: some View {
        HStack {
            Toggle(isOn: self.$status) {
                Text(self.name).strikethrough(status)
                    .lineLimit(1)
            }
            .padding([.vertical, .trailing])
            .toggleStyle(CheckBoxStyle(completed: completedSteps, total: totalSteps))
            .onTapGesture { statusAction() }

            Spacer(minLength: 8)

            if self.totalSteps > 0 {
                Text("\(completedSteps)/\(totalSteps)")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Button(action: { itemAction() }, label: {
                Image(systemName: "chevron.right")
                    .padding(.leading)
            })
            .padding([.vertical, .leading])
        }
    }
}

extension Color {
    static let stepAccent = Color(red: 0.95, green: 0.76, blue: 0.20)
    static let stepTrack  = Color(white: 0.80)
}

struct SegmentedRing: View {
    let completed: Int
    let total: Int
    var lineWidth: CGFloat = 3
    var gapDegrees: Double = 14

    private var segmentCount: Int { max(total, 1) }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let radius = (side - lineWidth) / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let sweep = 360.0 / Double(segmentCount)
            // Keep the gap sensible when there are many segments.
            let gap = min(gapDegrees, sweep * 0.35)

            ZStack {
                ForEach(0..<segmentCount, id: \.self) { index in
                    Path { path in
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: .degrees(Double(index) * sweep - 90 + gap / 2),
                            endAngle: .degrees(Double(index + 1) * sweep - 90 - gap / 2),
                            clockwise: false
                        )
                    }
                    .stroke(
                        index < completed ? Color.stepAccent : Color.stepTrack,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                }
            }
        }
    }
}

struct CheckBoxStyle: ToggleStyle {
    var completed: Int = 0
    var total: Int
    var ringSize: CGFloat = 36
    var markSize: CGFloat = 20

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            ZStack {
                if total > 1 {
                    SegmentedRing(completed: completed, total: total)
                        .frame(width: ringSize, height: ringSize)
                }

                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        configuration.isOn ? Color.black : Color.primary,
                        Color.stepAccent
                    )
                    .frame(width: markSize, height: markSize)
            }
            .frame(width: ringSize, height: ringSize)

            configuration.label
        }
    }
}

#Preview {
    VStack {
        ListItem(
            name: "LONG NAMEEEEEEEEEEEEEEEEEEEEE shfsjdfnsjdfbsljdfbs",
            status: .constant(false),
            statusAction: {},
            itemAction: {}
        )
        ListItem(name: "Test 1", status: .constant(true), statusAction: {}, itemAction: {})
    }
}
