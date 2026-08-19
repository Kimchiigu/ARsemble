//
//  StepView.swift
//  ARsemble
//
//  Created by Catherine Danielle on 17/08/26.
//

import SwiftUI

struct StepView: View {

    /// "Build Car" on the last step continues to the Editor.
    var onBuild: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(Router.self) private var router
    @StateObject private var viewModel = StepViewModel()
    @StateObject private var camera = StepCameraSession()
    @State private var isOpeningEditor = false

    // MARK: Layout

    /// Width of the left column (speech bubble + mascot). Fixed so the bubble
    /// and the mascot always share one edge instead of each sizing themselves.
    fileprivate static let mascotColumnWidth: CGFloat = 340

    /// Cap for the mascot artwork. The images have different aspect ratios, so
    /// this bounds the box and `scaledToFit` keeps each one whole inside it.
    fileprivate static let mascotHeight: CGFloat = 330

    /// How far the bubble's tail hangs below the bubble.
    fileprivate static let bubbleTailDrop: CGFloat = 18

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                header
                
                HStack(alignment: .top, spacing: 4) {
                    
                    mascotSection
                    
                    stepImageSection
                }
                .padding(.horizontal, 48)
                .padding(.top, 10)
                
                Spacer()
                
                navigationButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        // The page stays alive underneath whatever is pushed on top of it, so
        // release the camera here too — not only from the card.
        .onDisappear {
            camera.stop()
        }
    }
}


private extension StepView {
    
    var header: some View {
        ZStack {
            Image("woodenboard")
                .resizable()
                .frame(width: 329, height: 90)
                .overlay(
                    Text("Incline Plane")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                )
            
            HStack {
                BackButton {
                    router.popToLevel()
                }.padding(.leading, 24).padding(.bottom, 36)
                Spacer()
            }
        }
        
    }
}



private extension StepView {
    var step: Step { viewModel.currentStepData }
    
    var mascotSection: some View {

        VStack(alignment: .leading, spacing: 0) {

            stepBubble

            if let mascot = step.mascot {
                Image(mascot)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: Self.mascotHeight
                    )
                    // Clears the tail hanging off the bubble above.
                    .padding(.top, Self.bubbleTailDrop + 12)
            }

            Spacer(minLength: 0)
        }
        .frame(width: Self.mascotColumnWidth, alignment: .top)
    }
    
    /// The bubble sizes itself around its text.
    ///
    /// The old version drew a fixed 347×119 rounded rect and then pushed the
    /// text around with offsets, so the two moved independently: any title
    /// that needed a second line spilled straight out of the bubble. Now the
    /// rect is a `.background` of the text, so it can never be too small, and
    /// the tail is positioned relative to the bubble's real bottom edge.
    var stepBubble: some View {

        VStack(alignment: .leading, spacing: 6) {

            Text(step.title)
                .font(.system(size: 22, weight: .bold))
                // Wrap onto more lines instead of truncating.
                .fixedSize(horizontal: false, vertical: true)

            if !step.desc.isEmpty {
                Text(step.desc)
                    .font(.system(size: 19, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color("BubbleLeft"))
        )
        .overlay(alignment: .bottomLeading) {
            BubbleTailDown()
                .fill(Color("BubbleLeft"))
                .frame(width: 28, height: Self.bubbleTailDrop)
                .offset(x: 40, y: Self.bubbleTailDrop)
        }
    }
}

private struct BubbleTailDown: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private extension StepView {
    
    var stepImageSection: some View {
        let step = viewModel.currentStepData

        return RoundedRectangle(cornerRadius: 22)
            .fill(Color.white)
            .shadow(
                color: .black.opacity(0.18),
                radius: 8,
                x: 0,
                y: 5
            )
            .overlay {
                // Last step: the live camera with the ramp reference overlaid,
                // shown directly in the card (no separate camera page).
                if viewModel.isLastStep {
                    CameraCheckCard(
                        overlayImage: step.image,
                        camera: camera
                    )
                        .padding(10)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Image(step.image)
                        .resizable()
                        .aspectRatio(
                            contentMode: step.fillsFrame ? .fill : .fit
                        )
                        .padding(step.fillsFrame ? 0 : 35)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                }
            }
            .frame(width:723, height:519)
            .offset(x:50, y:30)
    }
}


private extension StepView {
    
    var navigationButtons: some View {
        HStack(spacing: 16) {
            Spacer()
            
            if !viewModel.isFirstStep {
                NextButton(title: "Previous Step", style: .secondary) {
                    viewModel.previousStep()
                }
            }
            
            if viewModel.isLastStep {
                NextButton(title: "Build Car") {
                    guard !isOpeningEditor else {
                        return
                    }

                    isOpeningEditor = true

                    // Do not push the next screen until the step camera has
                    // released the back-camera hardware for ARKit.
                    camera.stop {
                        onBuild()
                    }
                }
            } else {
                NextButton(title: "Next Step") {
                    viewModel.nextStep()
                }
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    StepView()
        .environment(Router())
}
