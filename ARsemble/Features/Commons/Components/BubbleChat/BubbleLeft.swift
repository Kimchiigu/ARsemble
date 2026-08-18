//
//  BubbleLeft.swift
//  ARsemble
//
//  Created by Catherine Danielle on 13/08/26.
//

import SwiftUI

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct BubbleLeft: View {
    let text: String
    var mascot: String = "mascot"

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(mascot)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .background(Circle().fill(Color.gray.opacity(0.15)))

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("BubbleLeft"))

                Text(text)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .padding()
            }
            .fixedSize(horizontal: true, vertical: true)
            .overlay(alignment: .leading) {
                Triangle()
                    .fill(Color("BubbleLeft"))
                    .frame(width: 16, height: 24)
                    .offset(x: -14)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    BubbleLeft(text: "OH NO! My car fell...")
}
