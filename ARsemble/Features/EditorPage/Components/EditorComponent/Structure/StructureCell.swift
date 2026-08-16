//
//  StructureCell.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI
import Foundation

struct StructureCell: View {
    let dimension: Dimension
    @Binding var value: Double
    let minimum: Double

    var body: some View {
        HStack {
            Text(dimension.rawValue)
            Spacer()
            Text("\(Int(value)) cm")
        }

        Slider(
            value: $value,
            in: minimum...30,
            step: 1
        ) {
            Text("Structure Config")
        } minimumValueLabel: {
            Text("\(Int(minimum))")
        } maximumValueLabel: {
            Text("30")
        }
        .padding(.bottom, 40)
    }
}
