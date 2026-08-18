//
//  InstructionOverlayView.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 17/08/26.
//

import SwiftUI

struct InstructionOverlayView: View {
    var text: String? = nil
    var image: String? = nil
    @State var isPresented: Bool = true

    var body: some View {
        if isPresented {
            ZStack(alignment: .center) {
                Color.black
                    .opacity(0.35)
                    .ignoresSafeArea()

                VStack(alignment: .center, spacing: 10) {

                    if let image {
                        Image(image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 700, maxHeight: 350)
                    }

                    if let text {
                        Text(text)
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .onTapGesture {
                isPresented = false
            }
        }
    }
}
