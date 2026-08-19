//
//  InstructionOverlayView.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 17/08/26.
//

import SwiftUI

struct FinishOverlayView: View {
    var dismiss: (() -> Void)
    @Binding var showSummary: Bool
    var body: some View {
            ZStack(alignment: .center) {
                Color.black
                    .opacity(0.35)
                    .ignoresSafeArea()

                VStack(alignment: .center, spacing: 134) {
                    Text("Level Cleared")
                    .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 20){
                        Button {
                            dismiss()   // back to the editor page
                        } label: {
                            Label("Rebuild Car", systemImage: "wrench.adjustable.fill")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .glassEffect()
                                .clipShape(Capsule())
                                .foregroundStyle(.gray)
                                .frame(width: 220)
                        }
                        
                            Button {
                              showSummary = true
                            } label: {
                                Label("Continue", systemImage: "arrow.right")
                                    .font(.title2)
                                    .bold()
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(Color("Primary"))
                                    .clipShape(Capsule())
                                    .foregroundStyle(.white)
                                    .frame(width: 220)
                            }
                        
                        
                        }
                    }
                }
        
        }
}

#Preview {
    FinishOverlayView(dismiss: {
        
    }, showSummary: .constant(false))
}
