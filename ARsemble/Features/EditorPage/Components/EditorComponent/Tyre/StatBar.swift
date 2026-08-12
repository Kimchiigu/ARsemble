//
//  TyreStat.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct StatBar: View {
    let label: String
    let filledSegments: Int
    let totalSegments: Int = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .bold()

            HStack(spacing: 3) {
                ForEach(0..<totalSegments, id: \.self) { index in
                    Capsule()
                        .fill(index < filledSegments ? Color.orange : Color.gray.opacity(0.4))
                        .frame(height: 7)
                }
            }
        }
    }
}

#Preview {
    StatBar(label: "Grip", filledSegments: 3)
}
