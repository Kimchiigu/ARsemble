//
//  StructureConfigView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct StructureConfigView: View {
    private let initialValues: [Dimension: Double] = [
        .length: 5,
        .width: 5,
        .height: 5
    ]
    
    @State private var values: [Dimension: Double] = [:]
    
    init() {
        _values = State(initialValue: initialValues)
    }
    
    var body: some View {
        VStack {
            ForEach(Dimension.allCases) { dimension in
                StructureCell(
                    dimension: dimension,
                    value: Binding(
                        get: { values[dimension] ?? 0 },
                        set: { values[dimension] = $0 }
                    )
                )
            }
        }
        .padding()
    }
}

#Preview {
    StructureConfigView()
}
