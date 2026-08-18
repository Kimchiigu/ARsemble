//
//  LevelView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 18/08/26.
//

import SwiftUI

/// Level-select map for one lesson: the island artwork with the level stops
/// along its winding path. Tapping an unlocked stop starts the lesson flow.
struct LevelView: View {
    let lesson: Int

    /// Called with the level number when an unlocked node is tapped.
    var onSelect: (Int) -> Void = { _ in }

    @State private var viewModel = LevelViewModel()
    @Environment(LevelProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(spacing: 8) {
                header

                map
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
    }

    private var header: some View {
        ZStack {
            Image("woodenboard")
                .resizable()
                .frame(width: 329, height: 90)
                .overlay(
                    Text(LevelMap.lessonTitles[lesson] ?? "Lesson \(lesson)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                )

            HStack {
                BackButton {
                    dismiss()
                }
                .padding(.leading, 24)
                .padding(.bottom, 36)

                Spacer()
            }
        }
        .padding(.horizontal, 24)
    }

    /// The map aspect-fitted to the available space, with the nodes
    /// positioned along the path so they track the artwork at any size or
    /// orientation.
    private var map: some View {
        GeometryReader { geo in
            let scale = min(
                geo.size.width / LevelMap.backgroundSize.width,
                geo.size.height / LevelMap.backgroundSize.height
            )
            let mapSize = CGSize(
                width: LevelMap.backgroundSize.width * scale,
                height: LevelMap.backgroundSize.height * scale
            )
            let origin = CGPoint(
                x: (geo.size.width - mapSize.width) / 2,
                y: (geo.size.height - mapSize.height) / 2
            )

            ZStack {
                Image(LevelMap.backgroundImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)

                ForEach(viewModel.nodes) { node in
                    LevelNodeButton(
                        level: node.id,
                        state: viewModel.state(for: node, lesson: lesson, progress: progress)
                    ) {
                        SoundManager.shared.playSound(named: "click")
                        onSelect(node.id)
                    }
                    .position(
                        x: origin.x + node.position.x * mapSize.width,
                        y: origin.y + node.position.y * mapSize.height
                    )
                }
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    LevelView(lesson: 1)
        .environment(LevelProgressStore())
}
