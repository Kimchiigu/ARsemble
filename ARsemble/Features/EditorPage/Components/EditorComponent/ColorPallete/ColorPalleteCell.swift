//
//  TyreCell.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI
import Foundation

struct ColorPalleteCell: View {
    let colorPallete: ColorPallete
    let isSelected: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(colorPallete.color)
            .frame(maxWidth: .infinity, minHeight: 128)
            .overlay(
                Color.black.opacity(isSelected ? 0.25 : 0)
            )
            .overlay {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
    }
}
