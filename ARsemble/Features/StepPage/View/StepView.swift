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
    @StateObject private var viewModel = StepViewModel()

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
                    dismiss()
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
                    .frame(width: 336, height: 369)
                    .padding(.top, 50)
            }
        }
        .frame(width: 280)
    }
    
    var stepBubble: some View {
        
        return VStack(alignment: .leading, spacing: 4) {
            Text(step.title)
                .font(.system(size: 24, weight: .bold))
            
            if !step.desc.isEmpty {
                Text(step.desc)
                    .font(.system(size: 24, weight: .medium))
            }
        }.offset(x: -20, y: 20)
        .foregroundStyle(.white)
        .multilineTextAlignment(.leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color("BubbleLeft"))
                .frame(width: 347, height:119)
                .padding(.top, 30)
        )
        .overlay(alignment: .bottomLeading) {
            BubbleTailDown()
                .fill(Color("BubbleLeft"))
                .frame(width: 30, height: 30)
                .offset(x:40, y: 40)
                
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
                    CameraCheckCard(overlayImage: step.image)
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
                    onBuild()
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
}
