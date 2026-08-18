//
//  LevelNodeButton.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 18/08/26.
//

import SwiftUI

/// One circular stop on the level map: the level number while playable, a
/// checkmark once completed, a lock icon when still locked (not tappable).
struct LevelNodeButton: View {
    let level: Int
    let state: LevelNodeState
    var action: () -> Void = {}

    var body: some View {
        switch state {
        case .completed:
            node(fill: .green) {
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            .allowsHitTesting(false)

        case .unlocked:
            Button(action: action) {
                node(fill: Color("Primary")) {
                    Text("\(level)")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

        case .locked:
            node(fill: Color(.systemGray3)) {
                Image("lock")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundStyle(.white)
            }
            .allowsHitTesting(false)
        }
    }

    private func node<Content: View>(
        fill: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Circle()
            .fill(fill)
            .frame(width: 64, height: 64)
            .overlay {
                Circle().stroke(.white, lineWidth: 3)
                content()
            }
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        LevelNodeButton(level: 1, state: .unlocked)
        LevelNodeButton(level: 2, state: .completed)
        LevelNodeButton(level: 3, state: .locked)
    }
    .padding(40)
}
