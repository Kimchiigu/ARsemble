//
//  ResultView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 13/08/26.
//

import SwiftUI

struct ResultView: View {
    var onBack: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Text("Result")
                    .font(.largeTitle)
                    .bold()

                Spacer()

                Button {
                    SoundManager.shared.playSound(named: "click")
                    onBack()
                } label: {
                    Text("Back to Editor")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    ResultView(onBack: {})
}
