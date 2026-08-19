//
//  EditorView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct EditorView: View {
    /// Called with the built car once the "Ready" cinematic covers the
    /// screen — hands off to the AR screen.
    var onReady: (CarSpecComponent) -> Void = { _ in }

    /// Used only to know whether the AR screen is currently pushed ON TOP of
    /// this page. SwiftUI keeps this view alive underneath, and its
    /// `RealityView` keeps a second RealityKit renderer running next to the
    /// AR one — two RealityKit views competing for the same camera/renderer is
    /// a known way to end up with a black camera background in the AR view.
    @Environment(Router.self) private var router

    @State private var viewModel = EditorViewModel()
    @State private var showResetAlert = false
    @State private var phase: Phase = .editing
    @State private var curtain = false

    /// Set once the curtain covers the screen, to tear the 3D viewer down
    /// BEFORE the AR screen is created. Confirmed cause of the black camera
    /// background: RealityKit builds its render graph per process, and a live
    /// non-AR `RealityView` next to a new `ARView` leaves the AR passthrough
    /// pass unable to build — 3D content still renders, the camera does not.
    @State private var viewerRetired = false

    private enum Phase { case editing, presenting }

    /// True while the AR screen is presented over this page.
    private var isCoveredByAR: Bool {
        router.arPresentation != nil
    }

    var body: some View {
        ZStack {
            VStack(alignment: .center){
                HStack{
                    BackButton(action: { router.popToLevel() })
                    Spacer()
                }.padding(.horizontal, 35).padding(.vertical, 20)
                editorContent
            }.background(Color("Background"))

            Color(.white)
                .ignoresSafeArea()
                .opacity(curtain ? 1 : 0)
                .allowsHitTesting(false)
        }
        .alert("Are you sure you want to reset to default?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                viewModel.reset()
            }
            Button("Continue Edit", role: .cancel) {}
        } message: {
            Text("All changes to your car will be lost")
        }
    }

    private var editorContent: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(spacing: 33){
                        FreeBubbleChat(text: "Build a car that has a low center of gravity.")
                        
                        // Unmount the 3D viewer entirely while AR is on top,
                        // so only ONE RealityKit renderer is alive at a time.
                        if isCoveredByAR || viewerRetired {
                            Color.clear
                                .frame(maxWidth: .infinity, maxHeight: 400)
                        } else {
                            CarViewerView(viewModel: viewModel, isPresenting: phase != .editing)
                                .frame(maxWidth: .infinity, maxHeight: 400)
                        }
                    }

                    if phase == .editing {
                        EditorConfigView(viewModel: viewModel)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .frame(maxHeight: .infinity)

                if phase == .editing {
                    bottomBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(phase == .editing ? 16 : 0).background(Color("Background"))
        }
    }

    private var bottomBar: some View {
        HStack {
                

            Spacer()

            Button {
                SoundManager.shared.playSound(named: "click")
                showResetAlert = true
            } label: {
                Text("Reset to Default")
                    .foregroundStyle(Color.primary)
            }
            .buttonBorderShape(.roundedRectangle)
            .padding()
            .frame(width: 200)
            .glassEffect()

            Button {
                SoundManager.shared.playSound(named: "confirm")
                startCinematic()
            } label: {
                Text("Ready")
                    .foregroundStyle(Color.white)
            }
            .buttonBorderShape(.roundedRectangle)
            .padding()
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.orange)
            )
            .glassEffect()
        }
    }

    private func startCinematic() {
        withAnimation(.easeInOut(duration: 0.55)) {
            phase = .presenting
        }

        Task {
            try? await Task.sleep(for: .seconds(0.7))
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.45)) { curtain = true }
            try? await Task.sleep(for: .seconds(0.5))
            if Task.isCancelled { return }

            // Screen is fully covered: drop the RealityView now and give
            // RealityKit a beat to dispose its renderer, so the ARView that
            // follows is the only one alive when it builds its render graph.
            viewerRetired = true
            try? await Task.sleep(for: .seconds(0.35))
            if Task.isCancelled { return }

            // Hand the built car to AR.
            onReady(viewModel.carSpec)
            try? await Task.sleep(for: .seconds(0.6))
            if Task.isCancelled { return }
            // Quietly restore the editor (hidden behind AR) so it is in an
            // editable state when the player returns via "Rebuild Car".
            // `isCoveredByAR` keeps the viewer unmounted until AR is dismissed.
            phase = .editing
            curtain = false
            viewerRetired = false
        }
    }
}

#Preview {
    EditorView()
        .environment(Router())
}
