//  FinishOverlayView.swift
//  ARsemble
//  Created to resolve missing view for ARScreenView

import SwiftUI

struct FinishOverlayView: View {
    /// Called to dismiss the overlay (usually pops the router stack).
    var dismiss: () -> Void
    /// Binding to show the summary page.
    @Binding var showSummary: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 28) {
                Image("arlo-success")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170, height: 170)

                Text("Level Cleared!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(radius: 10)

                Text("You helped Arlo reach the finish! Ready for your summary?")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)

                HStack(spacing: 18) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Back")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(.orange)
                            .clipShape(Capsule())
                    }

                    Button {
                        showSummary = true
                    } label: {
                        Text("See Summary")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(.green)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(.systemGray6).opacity(0.95))
                    .shadow(radius: 20)
            )
        }
        .transition(.opacity)
        .animation(.easeInOut, value: showSummary)
    }
}

#if DEBUG
#Preview {
    FinishOverlayView(dismiss: {}, showSummary: .constant(false))
}
#endif
