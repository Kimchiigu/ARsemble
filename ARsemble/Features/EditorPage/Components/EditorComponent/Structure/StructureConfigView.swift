//
//  StructureConfigView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct StructureConfigView: View {
    @Bindable var model: CarEditorModel

    var body: some View {
        VStack {
            ForEach(Dimension.allCases) { dimension in
                StructureCell(
                    dimension: dimension,
                    value: binding(for: dimension)
                )
            }
        }
        .padding()
    }

    private func binding(for dimension: Dimension) -> Binding<Double> {
        switch dimension {
        case .length: $model.lengthCm
        case .width:  $model.widthCm
        case .height: $model.heightCm
        }
    }
}

#Preview {
    StructureConfigView(model: CarEditorModel())
}
