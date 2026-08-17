//
//  PlacementConfirmView.swift
//  ARsemble
//
//  Confirmation popup shown after the player places + positions the car on the
//  locked surface. They can send the car off ("Ready") or go back to the
//  editor to rebuild it ("Rebuild it").
//

import SwiftUI

struct PlacementConfirmView: View {

    var onConfirm: () -> Void
    var onCancel: () -> Void
    var onRebuild: () -> Void

    var body: some View {

        ZStack {

            // Dimmed backdrop. Tapping it keeps positioning the car (cancel).
            Color.black
                .opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }

            VStack(spacing: 16) {

                Text("How does Arlo’s car look?")
                    .font(.headline)

                Text("Ready to drive, or want to rebuild it?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {

                    Button {
                        onRebuild()
                    } label: {
                        Text("Rebuild it")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        onConfirm()
                    } label: {
                        Text("Ready")
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
