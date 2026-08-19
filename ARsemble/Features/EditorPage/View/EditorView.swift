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

    @Environment(Router.self) private var router

    @State private var viewModel = EditorViewModel()
    @State private var showResetAlert = false
    @State private var phase: Phase = .editing
    @State private var curtain = false

    /// Set once the curtain covers the screen, to tear the 3D viewer down
    /// BEFORE the AR screen is created.
    @State private var viewerRetired = false

    private enum Phase {
        case editing
        case presenting
    }

    /// True while the AR screen is presented over this page.
    private var isCoveredByAR: Bool {
        router.arPresentation != nil
    }

    var body: some View {
        ZStack {
            if phase == .editing {
                VStack(alignment: .center) {
                    HStack {
                        BackButton {
                            router.popToLevel()
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 35)
                    .padding(.vertical, 20)

                    editorContent
                }
                .background(Color("Background"))
            } else {
                // Full-screen cinematic
                editorContent
                    .ignoresSafeArea()
            }

            // White curtain used only for the transition to AR.
            Color.white
                .ignoresSafeArea()
                .opacity(curtain ? 1 : 0)
                .allowsHitTesting(false)
        }
        .alert(
            "Are you sure you want to reset to default?",
            isPresented: $showResetAlert
        ) {
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
            if phase == .editing {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }

            VStack(spacing: phase == .presenting ? 0 : 16) {

                if phase == .editing {
                    HStack(
                        alignment: .center,
                        spacing: 12
                    ) {
                        VStack(spacing: 33) {
                            FreeBubbleChat(
                                text: "Build a car that has a low center of gravity."
                            )

                            if isCoveredByAR || viewerRetired {
                                Color.clear
                                    .frame(
                                        maxWidth: .infinity,
                                        maxHeight: 400
                                    )
                            } else {
                                CarViewerView(
                                    viewModel: viewModel,
                                    isPresenting: false
                                )
                                .frame(
                                    maxWidth: .infinity,
                                    maxHeight: 400
                                )
                            }
                        }

                        EditorConfigView(viewModel: viewModel)
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                            .transition(
                                .move(edge: .trailing)
                                .combined(with: .opacity)
                            )
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    // MARK: - Full-screen car cinematic

                    if isCoveredByAR || viewerRetired {
                        Color.clear
                            .ignoresSafeArea()
                    } else {
                        CarViewerView(
                            viewModel: viewModel,
                            isPresenting: true
                        )
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                        .ignoresSafeArea()
                    }
                }

                if phase == .editing {
                    bottomBar
                        .transition(
                            .move(edge: .bottom)
                            .combined(with: .opacity)
                        )
                }
            }
            .padding(phase == .editing ? 16 : 0)
            .background(
                phase == .editing
                ? Color("Background")
                : Color.clear
            )
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

            if Task.isCancelled {
                return
            }

            withAnimation(.easeInOut(duration: 0.45)) {
                curtain = true
            }

            try? await Task.sleep(for: .seconds(0.5))

            if Task.isCancelled {
                return
            }

            // Screen is fully covered:
            // remove the RealityKit viewer before AR starts.
            viewerRetired = true

            try? await Task.sleep(for: .seconds(0.35))

            if Task.isCancelled {
                return
            }

            onReady(viewModel.carSpec)

            try? await Task.sleep(for: .seconds(0.6))

            if Task.isCancelled {
                return
            }

            // Restore editor state behind AR.
            phase = .editing
            curtain = false
            viewerRetired = false
        }
    }
}

#Preview(traits: .landscapeLeft) {
    EditorView()
        .environment(Router())
}
