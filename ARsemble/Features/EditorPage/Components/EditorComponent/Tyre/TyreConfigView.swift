//
//  TyreConfigView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct TyreConfigView: View {
    @Bindable var model: CarEditorModel
    @Binding var previewedTyre: Tyre?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(tyres) { tyre in
                    TyreCell(
                        tyre: tyre,
                        isSelected: model.tyre.id == tyre.id
                    )
                    .onTapGesture {
                        model.tyre = tyre
                        previewedTyre = (previewedTyre?.id == tyre.id) ? nil : tyre
                    }
                }
            }
        }
        .frame(height: 350)
    }
}

#Preview {
    TyreConfigView(model: CarEditorModel(), previewedTyre: .constant(nil))
}
