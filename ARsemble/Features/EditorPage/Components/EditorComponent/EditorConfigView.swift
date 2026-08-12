//
//  EditorConfigView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct EditorConfigView: View {
    @Bindable var model: CarEditorModel
    @Binding var previewedTyre: Tyre?

    var body: some View {
        VStack {
            Picker("Config Type", selection: $model.selectedTab) {
                ForEach(CarEditorModel.ConfigTab.allCases, id: \.self) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 24)

            switch model.selectedTab {
            case .structure:
                StructureConfigView(model: model)
            case .tyre:
                TyreConfigView(model: model, previewedTyre: $previewedTyre)
            case .color:
                ColorConfigView(model: model)
            }
        }
        .padding(.top, 32)
        .padding(24)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    EditorConfigView(model: CarEditorModel(), previewedTyre: .constant(nil))
}
