//
//  BubbleRight.swift
//  ARsemble
//
//  Created by Catherine Danielle on 13/08/26.
//

import SwiftUI

struct BubbleRight: View {
    let text: String

    var body: some View {
        HStack {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("BubbleRight"))

                Text(text)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .padding()
            }
            .fixedSize(horizontal: true, vertical: true)
            .overlay(alignment: .trailing) {
                Triangle()
                    .fill(Color("BubbleRight"))
                    .frame(width: 16, height: 24)
                    .scaleEffect(x: -1)
                    .offset(x: 14)
            }
        }
        .padding()
    }
}

#Preview {
    BubbleRight(text: "What happened?")
}
