//
//  ARScreenView.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 12/08/26.
//

import SwiftUI
import AVFoundation

struct SurfaceScannerView: View {
    
    /// Owns the ARSession + scanRoot entity and publishes UI state.
    @StateObject private var driver: SurfaceScanDriver
    
    /// Called when the level is completed — marks progress and leaves AR.
    private let onFinish: () -> Void

    /// Stack navigation. Everything that leaves this page goes through the
    /// Router — mixing `@Environment(\.dismiss)` with a Router-owned
    /// `NavigationStack(path:)` meant the two disagreed about the current
    /// path, and the exit buttons could end up doing nothing.
    
    /// Used by "Rebuild it" to go back to the editor page.
    @Environment(\.dismiss) private var dismiss
    
    /// Stack navigation (used to pop back to the editor deterministically).
    @Environment(Router.self) private var router
    
    /// True while the post-level summary page is covering the screen.
    @State private var showSummary = false
    
    @State private var showSuccessOverlay: Bool = false
    @State private var showfinishOverlay: Bool = false
    @State private var isDrivingState: Bool = false
    @State private var audioPlayer: AVAudioPlayer?

    /// Navigation to perform AFTER the summary cover finishes dismissing.
    /// Mutating the router path while the cover is still animating gets
    /// swallowed, so we defer it to the cover's onDismiss.
    @State private var pendingFinish = false
    @State private var pendingRebuild = false
    
    
    init(
        carSpec: CarSpecComponent = EntityFactory.placeholderCarSpec(),
        onFinish: @escaping () -> Void = {}
    ) {
        _driver = StateObject(wrappedValue: SurfaceScanDriver(carSpec: carSpec))
        self.onFinish = onFinish
    }
    
    private func startClosingCountdown() {
        showSuccessOverlay = true
        
        // Start sound
        if let url = Bundle.main.url(
            forResource: "success",
            withExtension: "mp3"
        ) {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        }
        
        Task {
            try? await Task.sleep(for: .seconds(5))
            
            await MainActor.run {
                showSuccessOverlay = false
                stopPlay()
                // Celebration done — now show the "Level Cleared" overlay with
                // the Rebuild / Continue choices.
                showfinishOverlay = true
            }
        }
    }
    
    private func playCarEngine() {
        if let url = Bundle.main.url(
            forResource: "carEngine",
            withExtension: "mp3"
        ) {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
        }
    }
    
    private func stopPlay(){
        audioPlayer?.stop()
        audioPlayer = nil
    }
    var body: some View {
        
        ZStack(alignment: .bottom) {
            
            ARContainer(driver: driver)
                .ignoresSafeArea()
            
            if driver.didTip {
                
                TipOverOverlayView()
            }
            
            // "Here goes Arlo" banner — a lightweight, NON-blocking top overlay.
            // Kept out of `controls` so the controls stay a small bottom bar; a
            // full-screen (Spacer-greedy) layer over the live camera feed forces
            // extra compositing every frame and makes the AR view lag.
            if isDrivingState {
                VStack {
                    Text("Here goes Arlo! 🚗💨")
                        .padding(12)
                        .background(.black.opacity(0.44))
                        .foregroundStyle(.white)
                        .font(.system(size: 40, weight: .bold))
                        .cornerRadius(30)
                    Spacer(minLength: 0)
                }
                .padding(.top, 40)
                .allowsHitTesting(false)
            }
            
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
                        router.dismissAR()   // back to the editor (car config kept)
                    }
                )
            }
            
            // Confirm finish marker.
            if driver.showFinishConfirm {
                MarkerConfirmView(
                    onConfirm: {
                        driver.confirmFinish()
                        isDrivingState = true
                        playCarEngine()
                    },
                    onRetry: {
                        driver.retryFinish()
                    }
                )
            }
            
            // Car toppled over (centre of gravity too high for the slope).
            
            // Success — celebrate, then "Finish" opens the summary page.
            if driver.didSucceed {
                if showSuccessOverlay {
                    InstructionOverlayView(
                        image: "arlo-success"
                    )
                }
            }
            if showfinishOverlay{
                FinishOverlayView(dismiss: {
                    router.dismissAR()
                    showfinishOverlay = false
                }, showSummary: $showSummary)
            }
            
            controls
                .padding(.bottom, 28)
            
        }
        .fullScreenCover(isPresented: $showSummary, onDismiss: {
            // Cover is fully gone now — safe to change the navigation path.
            if pendingFinish {
                pendingFinish = false
                onFinish()          // → returnToLevelMap in the real flow
            } else if pendingRebuild {
                pendingRebuild = false
                router.pop()        // back to the editor page
            }
        }) {
            SummaryPageView(
                onFinish: {
                    pendingFinish = true
                    showSummary = false
                },
                onRebuild: {
                    pendingRebuild = true
                    showSummary = false
                    router.dismissAR()   // back to the editor page
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
        .animation(
            .easeInOut(duration: 0.2),
            value: driver.didTip
        )
        // Warm the usdz wheel assets so the editor's tyres (not procedural
        // wheels) are used when the car spawns.
        .task {
            await CarBuilder.prepareWheelAssets()
        }
        // Belt-and-braces rebinds of the camera feed. ARContainer already
        // rebinds on every settled layout pass; these cover the case where the
        // bounds never change but the drawable was still sizing.
        .onAppear {
            for delay in [0.4, 1.0, 2.0] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    driver.refreshCameraFeed()
                }
            }
        }
        // Hand the camera back the moment this screen goes away, so the
        // editor's RealityView is never running next to a live ARSession.
        //
        // Presenting the summary page ON TOP of this screen also fires
        // onDisappear — skip teardown then, or coming back from the summary
        // would land on a dead session.
        .onDisappear {
            guard !showSummary else { return }
            driver.teardown()
        }
        .onChange(of: driver.didSucceed) { _, didSucceed in
            if didSucceed {
                Task {
                    stopPlay()
                    isDrivingState = false
                    startClosingCountdown()
                }
            }
        }
    }
    
    
    // MARK: - Controls
    
    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                if(!driver.didSucceed){
                    Button {
                        router.dismissAR()   // back to the editor page
                    } label: {
                        Label("Rebuild Car", systemImage: "wrench.adjustable.fill")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color("Primary"))
                            .clipShape(Capsule())
                            .foregroundStyle(.white)
                    }
                }
                Spacer()
                
                // Retry the drive (car back to start) once it's actually driving.
                
                if isDrivingState {
                    Button {
                        driver.retryDrive()
                    } label: {
                        Label("Retry Drive", systemImage: "arrow.clockwise")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        
                            .clipShape(Capsule())
                            .foregroundStyle(.gray)
                    }.buttonStyle(.glassProminent).tint(.white)
                }
                }
            
        }.padding(.horizontal, 30)
        
    }
}




#Preview {
    SurfaceScannerView()
        .environment(Router())
}
