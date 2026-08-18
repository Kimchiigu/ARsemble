//
//  TipOverOverlayView.swift
//  ARsemble
//
//  Popup shown when Arlo's car TOPPLES over — its centre of gravity was too
//  high for the incline. Lets the player rebuild a lower/wider car or try the
//  drive again. Design is intentionally simple so it's easy to restyle.
//

import SwiftUI

struct TipOverOverlayView: View {


    var body: some View {
        ZStack {
            Color.black
                .opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 50) {

                Text("Oh no! Arlo’s car Tipped over . It’s center of gravity is too high. Rebuid it lower and wider")
                    .font(.system(size:35, weight: .medium))
                    .bold()
                    .multilineTextAlignment(.center)
                
                Image("TipOverGuide")

            }
            .padding(32)
            .frame(maxWidth: 800, maxHeight: 500)
            .background(
                .white.opacity(0.8),
                in: RoundedRectangle(cornerRadius: 30)
            )
            .padding(40)
        }
        .transition(.opacity)
    }
}
#Preview {
    TipOverOverlayView()
}
