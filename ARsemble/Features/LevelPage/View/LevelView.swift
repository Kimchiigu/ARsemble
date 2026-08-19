//
//  LevelView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 18/08/26.
//

import SwiftUI

/// Level-select screen for one lesson: a horizontal scroll of island cards
/// (~3 visible at a time) joined by dotted connectors, ending in a
/// "Next Island" label. Tapping an unlocked card starts that level.
struct LevelView: View {
    let lesson: Int
    var onSelect: (Int) -> Void = { _ in }

    @State private var viewModel = LevelViewModel()
    @Environment(LevelProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss

    /// Sized so roughly 3 cards fit across iPad landscape.
    private let cardWidth: CGFloat = 280
    private let islandHeight: CGFloat = 240
    private let cardTopPadding: CGFloat = 8
    private let connectorWidth: CGFloat = 56

    /// Vertical offset of the dotted line, measured from the top of the row.
    private var connectorY: CGFloat {
        cardTopPadding + islandHeight * 0.55
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color("G1"), Color("G2")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            levelScrollView

            BackButton { dismiss() }
                .padding(.leading, 24)
                .padding(.top, 12)
        }
    }

    // MARK: - Level scroll

    private var levelScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {

                ForEach(viewModel.nodes(for: lesson)) { node in

                    LevelIslandCard(
                        node: node,
                        state: viewModel.state(
                            for: node,
                            lesson: lesson,
                            progress: progress
                        ),
                        islandHeight: islandHeight
                    ) {
                        SoundManager.shared.playSound(named: "click")
                        onSelect(node.id)
                    }
                    .frame(width: cardWidth)

                    // Dotted connector after every island, including the last
                    // one (which links across to the "Next Island" label).
                    dottedConnector
                }

//                nextIslandLabel
            }
            .padding(.horizontal, 32)
            .padding(.vertical, cardTopPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Pieces

    private var dottedConnector: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: connectorWidth, height: connectorY + 4)
            .overlay(alignment: .bottom) {
                Line()
                    .stroke(
                        Color.primary.opacity(0.75),
                        style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round,
                            dash: [1, 16]
                        )
                    )
                    .frame(height: 5)
            }
    }

//    private var nextIslandLabel: some View {
//        Text("Next Island")
//            .font(.system(size: 30, weight: .semibold))
//            .foregroundStyle(.primary)
//            .fixedSize()
//            .padding(.top, connectorY - 20)
//            .padding(.trailing, 32)
//    }
}

/// A single horizontal line, used as the dotted connector shape.
private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

#Preview(traits: .landscapeLeft) {
    LevelView(lesson: 1)
        .environment(LevelProgressStore())
}
