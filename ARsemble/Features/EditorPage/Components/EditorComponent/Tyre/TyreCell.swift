//
//  TyreCell.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI
import Foundation

struct TyreCell: View {
    let tyre: Tyre
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(tyre.image)
                .font(.system(size: 48))
            Text(tyre.name)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, minHeight: 128)
        .padding()
        .background(.thinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
    }
}
