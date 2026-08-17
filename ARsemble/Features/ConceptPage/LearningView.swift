//
//  LearningView.swift
//  ARsemble
//
//  Created by Catherine Danielle on 13/08/26.
//

import SwiftUI

struct LearningView: View {
    let message: String
    let leftImage: String
    let rightImage: String
    var leftDimmed: Bool = false
    var rightDimmed: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            BubbleLeft(text: message)

            HStack(spacing: 24) {
                DiagramCard(imageName: leftImage, isDimmed: leftDimmed)
                DiagramCard(imageName: rightImage, isDimmed: rightDimmed)
            }
            .frame(height: 320)
            .padding(.horizontal, 24)
        }
    }
}

struct DiagramCard: View {
    let imageName: String
    var isDimmed: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(isDimmed ? Color.gray.opacity(0.6) : Color.white)
            .overlay {
                loadImage(imageName)
                    .scaledToFit()
                    .padding(32)
                    .opacity(isDimmed ? 0.7 : 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
}

#Preview(traits: .landscapeLeft) {
    LearningView(
        message: "Center of gravity is the magic balancing spot that keeps an object from falling over",
        leftImage: "Frame 3",
        rightImage: "Frame 4"
    )
    .background(Color("Background"))
}
