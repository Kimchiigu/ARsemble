//
//  EditorConfigView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct EditorConfigView: View {
    @State private var configOption = 0
    
    var body: some View {
        VStack {
            Picker("Config Type", selection: $configOption) {
                Text("Structure").tag(0)
                Text("Tyre").tag(1)
                Text("Color").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 24)
            
            switch configOption {
                case 0:
                    StructureConfigView()
                case 1:
                    TyreConfigView()
                case 2:
                    ColorConfigView()
                default:
                    Text("Invalid")
            }
        }
        .padding(.top, 32)
        .padding(24)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    EditorConfigView()
}
