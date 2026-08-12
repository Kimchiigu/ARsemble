//
//  EditorConfigView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct EditorConfigView: View {
    @State private var configOption = 0

    // Shared editor state — forwarded to whichever panel is showing, so every
    // change flows straight into the 3D viewer.
    var model: CarEditorModel

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
                    StructureConfigView(model: model)
                case 1:
                    TyreConfigView(model: model)
                case 2:
                    ColorConfigView(model: model)
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
    EditorConfigView(model: CarEditorModel())
}
