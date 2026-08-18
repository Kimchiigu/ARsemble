//
//  ColorConfigView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct ColorConfigView: View {
    let viewModel: EditorViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(colorPalletes) { colorPallete in
                    ColorPalleteCell(
                        colorPallete: colorPallete,
                        isSelected: viewModel.bodyColor.id == colorPallete.id
                    )
                    .onTapGesture {
                        viewModel.selectColor(colorPallete)
                    }
                }
            }
        }
        .frame(height: 350)
    }
}

#Preview {
    ColorConfigView(viewModel: EditorViewModel())
}
