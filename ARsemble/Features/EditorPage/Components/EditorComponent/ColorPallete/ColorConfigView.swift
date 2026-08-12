//
//  TyreConfigView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct ColorConfigView: View {
    @State private var selectedColor: ColorPallete? = nil
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)
    
    init() {
        _selectedColor = State(initialValue: colorPalletes.first)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(colorPalletes) { colorPallete in
                    ColorPalleteCell(
                        colorPallete: colorPallete,
                        isSelected: colorPallete.id == selectedColor?.id
                    )
                    .onTapGesture {
                        selectedColor = colorPallete
                    }
                }
            }
        }
        .frame(height: 350)
    }
}

#Preview {
    ColorConfigView()
}
