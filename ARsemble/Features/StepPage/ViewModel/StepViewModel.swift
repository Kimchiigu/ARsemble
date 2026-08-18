//
//  StepViewModel.swift
//  ARsemble
//
//  Created by Catherine Danielle on 17/08/26.
//


import Foundation
import SwiftUI

final class StepViewModel: ObservableObject {

    @Published var currentStep: Int = 0

    let steps: [Step] = [
        Step(
            id: UUID(),
            title: "Clear Space.",
            desc: "Make sure your table is clear.",
            image: "step1",
            mascot: "mascot2"
        ),
        Step(
            id: UUID(),
            title: "Get 5 Books!",
            desc: "You may use other similar flat objects.",
            image: "step2",
            mascot: "mascot3"
        ),
        Step(
            id: UUID(),
            title: "Build the stack.",
            desc: "Stack 4 books on top of each other.",
            image: "step3",
            mascot: "mascot4"
        ),
        Step(
            id: UUID(),
            title: "Create the slope.",
            desc: "Lean the 5th book against the stack.",
            image: "step4",
            mascot: "mascot5"
        ),
        Step(
            id: UUID(),
            title: "Does your ramp look like this?",
            desc: "",
            image: "step5-2",
            mascot: "step4",
            fillsFrame: true
        )
    ]

    var currentStepData: Step {
        steps[currentStep]
    }

    var isFirstStep: Bool {
        currentStep == 0
    }

    var isLastStep: Bool {
        currentStep == steps.count - 1
    }

    func nextStep() {
        guard !isLastStep else { return }
        currentStep += 1
    }

    func previousStep() {
        guard !isFirstStep else { return }
        currentStep -= 1
    }
}
