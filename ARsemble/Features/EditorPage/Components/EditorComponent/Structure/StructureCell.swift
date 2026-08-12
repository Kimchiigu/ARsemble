//
//  TyreCell.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI
import Foundation

struct StructureCell: View {
    let dimension: Dimension
    @Binding var value: Double
    
    var body: some View {
        HStack {
            Text(dimension.rawValue)
            Spacer()
            Text("\(Int(value)) cm")
        }
        
        Slider(
            value: $value,
            in: 5...30,
            step: 1
        ) {
            Text("Structure Config")
        } minimumValueLabel: {
            Text("5")
        } maximumValueLabel: {
            Text("30")
        }
        .padding(.bottom, 40)
    }
}
