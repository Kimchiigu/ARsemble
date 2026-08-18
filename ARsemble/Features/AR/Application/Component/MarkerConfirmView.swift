//
//  MarkerConfirmView.swift
//  ARsemble
//
//  Popup shown after the finish marker is auto-placed on the obstacle, so the
//  player can confirm it's in the right spot before Arlo drives — or move it.
//

import SwiftUI

struct MarkerConfirmView: View {

    var onConfirm: () -> Void
    var onRetry: () -> Void

    var body: some View {

        ZStack {

            Color.black
                .opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 16) {

                Text("Is the finish flag in the right spot?")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("Confirm to let Arlo drive, or move it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {

                    Button {
                        onRetry()
                    } label: {
                        Text("Move it")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        onConfirm()
                    } label: {
                        Text("Confirm")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .frame(maxWidth: 320)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 20)
            )
            .padding(40)
        }
        .transition(.opacity)
    }
}
