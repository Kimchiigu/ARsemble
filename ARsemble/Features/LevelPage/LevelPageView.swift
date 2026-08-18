//
//  LevelPageView.swift
//  ARsemble
//
//  Placeholder level page — the Finish button on the summary returns here.
//  Build out the level selection when ready.
//

import SwiftUI

struct LevelPageView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {

            Text("Levels")
                .font(.largeTitle)
                .bold()

            Text("Pick a challenge for Arlo.")
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }
}

#Preview {
    LevelPageView()
}
