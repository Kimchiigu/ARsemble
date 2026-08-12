//
//  TyreStatView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct TyreStatView: View {
    let name: String
    let stats: TyreStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name)
                .font(.headline)
                .bold()

            StatBar(label: "Grip",   filledSegments: stats.grip)
            StatBar(label: "Size",   filledSegments: stats.size)
            StatBar(label: "Speed",  filledSegments: stats.speed)
            StatBar(label: "Weight", filledSegments: stats.weight)
        }
        .padding(16)
        .background(.thickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    TyreStatView(name: "Tyre 1",
                 stats: TyreStats(grip: 3, size: 2, speed: 2, weight: 2))
}
