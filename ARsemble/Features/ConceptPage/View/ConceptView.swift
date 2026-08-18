//
//  ConceptView.swift
//  ARsemble
//
//  Created by Catherine Danielle on 13/08/26.
//


import SwiftUI

struct ConceptView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ConceptViewModel()

    @State private var currentPage = 0
    private let totalPages = 6

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Spacer(minLength: 20)

                pageContent
                    .transition(.opacity)

                Spacer(minLength: 20)

                bottomBar
            }
        }
        .task {
            await viewModel.startConversation()
        }
    }


    @ViewBuilder
    private var pageContent: some View {
        switch currentPage {

        case 0:
            conversationPage

        case 1:
            LearningView(
                message: "Center of gravity is the magic balancing spot that keeps an object from falling over.",
                leftImage: "Frame 3",
                rightImage: "Frame 4"
            )

        case 2:
            LearningView(
                message: "A lower car tends to have a low center of gravity.",
                leftImage: "Frame 3",
                rightImage: "Frame 4",
                rightDimmed: true
            )

        case 3:
            LearningView(
                message: "While a higher car tends to have a higher center of gravity.",
                leftImage: "Frame 3",
                rightImage: "Frame 4",
                leftDimmed: true
            )

        case 4:
            LearningView(
                message: "Higher center of gravity makes the car flip over easily on a slope.",
                leftImage: "Frame 9",
                rightImage: "Frame 10"
            )

        case 5:
            BuildView(
                message: "Next, we are going to build an environment to test this.",
                imageName: "Frame 11"
            )

        default:
            EmptyView()
        }
    }


    private var conversationPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(viewModel.visibleMessages) { message in
                    bubble(for: message)
                        .transition(
                            .asymmetric(
                                insertion: .move(
                                    edge: message.side == .left
                                        ? .leading
                                        : .trailing
                                )
                                .combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
        }
    }


    private var header: some View {
        ZStack {
            Image("woodenboard")
                .resizable()
                .scaledToFit()
                .frame(width: 329, height: 90)
                .overlay {
                    Text("Incline Plane")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }

            HStack {
                BackButton {
                    dismiss()
                }
                .padding(.leading, 24)

                Spacer()

                if currentPage < totalPages - 1 {
                    NextButton(title: "Skip Lesson") {
                        dismiss()
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var bottomBar: some View {
        HStack {
            NextButton(title: "Previous") {
                goPrevious()
            }
            .opacity(currentPage == 0 ? 0 : 1)
            .disabled(currentPage == 0)

            Spacer()

            NextButton(
                title: currentPage == totalPages - 1
                    ? "Build"
                    : "Next"
            ) {
                goNext()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }


    private func goNext() {
        if currentPage < totalPages - 1 {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentPage += 1
            }
        }
    }

    private func goPrevious() {
        if currentPage > 0 {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentPage -= 1
            }
        }
    }

    @ViewBuilder
    private func loadImage(_ name: String) -> some View {
        if let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
        } else {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.gray)
                .frame(width: 80, height: 80)
        }
    }
    
    @ViewBuilder
    private func bubble(for message: ConceptModel) -> some View {
        switch message.side {
        case .left:
            BubbleLeft(text: message.text)

        case .right:
            BubbleRight(text: message.text)
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ConceptView()
}
