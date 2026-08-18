//
//  LevelNodeButton.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 18/08/26.
//

import SwiftUI

/// One island card in the level-select scroll: the island artwork with its
/// state overlay, the level title and description, and a Start button.
struct LevelIslandCard: View {
    let node: LevelNode
    let state: LevelNodeState
    let islandImage: String
    let islandHeight: CGFloat
    var action: () -> Void = {}

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Image(islandImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: islandHeight)
                    .saturation(state == .locked ? 0 : 1)
                    .brightness(state == .locked ? -0.35 : 0)

                switch state {
                case .locked:
                    Image("lock")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)

                case .completed:
                    Circle()
                        .fill(.green)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                case .unlocked:
                    EmptyView()
                }
            }
            .frame(height: islandHeight)

            VStack(spacing: 4) {
                Text("Level \(node.id): \(node.title)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(node.description)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)

            StartButton(action: state == .unlocked ? action : {})
                .grayscale(state == .unlocked ? 0 : 1)
                .opacity(state == .unlocked ? 1 : 0.55)
                .disabled(state != .unlocked)
                .padding(.top, 4)
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        LevelIslandCard(
            node: LevelNode(
                id: 1,
                title: "Hill Climb",
                description: "Learn about the center of gravity on an inclined plane."
            ),
            state: .unlocked,
            islandImage: "island1",
            islandHeight: 240
        )
        .frame(width: 280)

        LevelIslandCard(
            node: LevelNode(
                id: 2,
                title: "Down Hill",
                description: "Learn about the center of gravity on an inclined plane."
            ),
            state: .locked,
            islandImage: "island1",
            islandHeight: 240
        )
        .frame(width: 280)
    }
    .padding()
}
