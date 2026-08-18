//
//  FreeBubbleChat.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 19/08/26.
//
import SwiftUI
struct FreeBubbleChat : View {
    var text: String
    var body: some View {
        HStack(spacing: 32){
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 64, height: 64)
                
                Image("armadillo-editor")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
            }
            Text(text)
                .foregroundStyle(Color.white)
                .font(.title3)
                .bold()
            // 8pt padding around the text — the bubble hugs this.
                .padding(20)
                .background(alignment: .leading) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.blue)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.blue.opacity(0.7), lineWidth: 1)
                            )
                        
                        BubbleTail()
                            .fill(Color.blue)
                            .frame(width: 20, height: 24)
                            .offset(x: -18)
                    }
                }
            // Hug the text so the bubble width tracks the text length.
                .fixedSize(horizontal: true, vertical: true)
        }
    }
}

#Preview {
    FreeBubbleChat(text: "Hello, world!")
}
