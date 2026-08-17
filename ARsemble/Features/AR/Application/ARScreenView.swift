//
//  ARScreenView.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 12/08/26.
//

import SwiftUI
struct SurfaceScannerView: View {

    /// Owns the ARSession + scanRoot entity and publishes UI state.
    @StateObject private var driver = SurfaceScanDriver()

    /// Used by "Rebuild it" to go back to the editor page.
    @Environment(\.dismiss) private var dismiss

    var body: some View {

        ZStack(alignment: .bottom) {

            ARContainer(driver: driver)
                .ignoresSafeArea()

            controls
                .padding(.bottom, 28)
          

            // ==================================================
            // Instruction overlays.
            //
            // These are NON-BLOCKING (allowsHitTesting false) so the
            // tap / drag they describe actually reaches the AR view.
            // They auto-hide when the phase advances.
            // ==================================================

            if !driver.hasLockedSurface {

                InstructionOverlayView(
                    text: "Move device to start",
                    image: "move-device"
                )
            }

            // Tap to place the car.
            if driver.hasLockedSurface &&
                !driver.carSpawnedForPlacement &&
                !driver.carPlacementConfirmed {

                InstructionOverlayView(
                    text: "Tap anywhere on the table to place Arlo’s car"
                )
                .allowsHitTesting(false)
            }

            // Drag to position the car.
            if driver.hasLockedSurface &&
                driver.carSpawnedForPlacement &&
                !driver.carPlacementConfirmed {

                InstructionOverlayView(
                    text: "Drag the car around to find the best spot!"
                )
                .allowsHitTesting(false)
            }

            // Tap the obstacle to set the finish.
            if driver.carPlacementConfirmed &&
                !driver.finishPlaced {

                InstructionOverlayView(
                    text: "Tap where you want Arlo to go!"
                )
                .allowsHitTesting(false)
            }


            // ==================================================
            // Modal popups (blocking decisions).
            // ==================================================

            // Confirm car placement.
            if driver.showPlacementConfirm {
                PlacementConfirmView(
                    onConfirm: {
                        driver.confirmPlacement()
                    },
                    onCancel: {
                        driver.cancelPlacement()
                    },
                    onRebuild: {
                        driver.cancelPlacement()
                        dismiss()   // back to the editor page
                    }
                )
            }

            // Confirm finish marker.
            if driver.showFinishConfirm {
                MarkerConfirmView(
                    onConfirm: {
                        driver.confirmFinish()
                    },
                    onRetry: {
                        driver.retryFinish()
                    }
                )
            }

            // Success.
            if driver.didSucceed {
                InstructionOverlayView(
                    image: "arlo-success"
                )
            }
            
        }
        .animation(
            .easeInOut(duration: 0.2),
            value: driver.showPlacementConfirm
        )
        .animation(
            .easeInOut(duration: 0.2),
            value: driver.showFinishConfirm
        )
    }


    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {
                    
                } label: {
                    Label("Rebuild Car", systemImage: "wrench.adjustable.fill")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(.orange)
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }

                Spacer()

                // Retry the drive (car back to start) once it's actually driving.
                if driver.finishConfirmed {
                    Button {
                        driver.retryDrive()
                    } label: {
                        Label("Retry Drive", systemImage: "arrow.2.circlepath.circle.fill")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(.orange)
                            .clipShape(Capsule())
                            .foregroundStyle(.white)
                    }
                }
                
            }
        }.padding(.horizontal, 30)
    }
}



#Preview {
    SurfaceScannerView()
}
