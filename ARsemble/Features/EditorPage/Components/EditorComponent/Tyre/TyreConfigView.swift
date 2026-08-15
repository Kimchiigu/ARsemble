//
//  TyreConfigView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct TyreConfigView: View {
    let viewModel: EditorViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(tyres) { tyre in
                    TyreCell(
                        tyre: tyre,
                        isSelected: viewModel.tyre.id == tyre.id
                    )
                    .onTapGesture {
                        viewModel.selectTyre(tyre)
                    }
                }
            }
        }
        .frame(height: 350)
    }
}

#Preview {
    TyreConfigView(viewModel: EditorViewModel())
}
