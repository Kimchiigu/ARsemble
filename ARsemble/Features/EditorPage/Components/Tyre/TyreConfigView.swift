//
//  TyreConfigView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct TyreConfigView: View {
    @State private var selectedTyre: Tyre? = nil
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    
    init() {
        _selectedTyre = State(initialValue: tyres.first)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(tyres) { tyre in
                    TyreCell(
                        tyre: tyre,
                        isSelected: tyre.id == selectedTyre?.id,
                    )
                    .onTapGesture {
                        if selectedTyre?.id == tyre.id {
                            selectedTyre = nil
                        } else {
                            selectedTyre = tyre
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    TyreConfigView()
}
