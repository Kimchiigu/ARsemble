//
//  StructureConfigView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct StructureConfigView: View {
    @Bindable var viewModel: EditorViewModel

    var body: some View {
        VStack {
            ForEach(Dimension.allCases) { dimension in
                StructureCell(
                    dimension: dimension,
                    value: binding(for: dimension),
                    minimum: minimum(for: dimension)
                )
            }
        }
        .padding()
    }

    private func binding(for dimension: Dimension) -> Binding<Double> {
        switch dimension {
        case .length: $viewModel.lengthCm
        case .width:  $viewModel.widthCm
        case .height: $viewModel.heightCm
        }
    }

    private func minimum(for dimension: Dimension) -> Double {
        switch dimension {
        case .length: viewModel.minLengthCm
        default:      5
        }
    }
}

#Preview {
    StructureConfigView(viewModel: EditorViewModel())
}
