//
//  ARScreenView.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 12/08/26.
//

import SwiftUI
struct SurfaceScannerView: View {

    /// Owns the ARSession + scanRoot entity and publishes UI state.
    @StateObject private var driver: SurfaceScanDriver

    /// Called when the level is completed — marks progress and leaves AR.
    private let onFinish: () -> Void

    /// Used by "Rebuild it" to go back to the editor page.
    @Environment(\.dismiss) private var dismiss

    /// Stack navigation (used to pop back to the editor deterministically).
    @Environment(Router.self) private var router

    /// True while the post-level summary page is covering the screen.
    @State private var showSummary = false

    init(
        carSpec: CarSpecComponent = EntityFactory.placeholderCarSpec(),
        onFinish: @escaping () -> Void = {}
    ) {
        _driver = StateObject(wrappedValue: SurfaceScanDriver(carSpec: carSpec))
        self.onFinish = onFinish
    }

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
                        dismiss()   // back to the editor page (car config kept)
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

            // Success — celebrate, then "Finish" opens the summary page.
            if driver.didSucceed {
                InstructionOverlayView(
                    image: "arlo-success"
                )
            }

        }
        .fullScreenCover(isPresented: $showSummary) {
            SummaryPageView(
                onFinish: {
                    showSummary = false
                    onFinish()
                },
                onRebuild: {
                    showSummary = false
                    router.pop()   // back to the editor page
                }
            )
        }
        .animation(
            .easeInOut(duration: 0.2),
            value: driver.showPlacementConfirm
        )
        .animation(
            .easeInOut(duration: 0.2),
            value: driver.showFinishConfirm
        )
        .animation(
            .easeInOut(duration: 0.2),
            value: driver.didSucceed
        )
        // Warm the usdz wheel assets so the editor's tyres (not procedural
        // wheels) are used when the car spawns.
        .task {
            await CarBuilder.prepareWheelAssets()
        }
    }


    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {
                    dismiss()   // back to the editor page
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
                if driver.finishConfirmed && !driver.didSucceed {
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

                // Finish → summary page, once Arlo has reached the finish.
                if driver.didSucceed {
                    Button {
                        showSummary = true
                    } label: {
                        Label("Finish", systemImage: "flag.checkered")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(.green)
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
        .environment(Router())
}
