//
//  EditorView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct EditorView: View {
    // The one source of truth for the editor. Owned here, shared with both the
    // 3D viewer and the configuration panels.
    @State private var model = CarEditorModel()

    /// The tyre whose stats are shown over the car. Owned here so a tap in
    /// `TyreConfigView` (right panel) can drive an overlay in `CarViewerView`
    /// (left panel).
    @State private var previewedTyre: Tyre?

    var body: some View {
        VStack {
            HStack {
                CarViewerView(model: model, previewedTyre: $previewedTyre)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)

                EditorConfigView(model: model, previewedTyre: $previewedTyre)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .layoutPriority(1)
            }

            HStack {
                Spacer()
                Button {
                    model.reset()
                } label: {
                    Text("Reset to Default")
                        .foregroundStyle(Color.black)
                }
                .buttonBorderShape(.roundedRectangle)
                .padding()
                .frame(width: 200)
                .glassEffect()

                Button {

                } label: {
                    Text("Ready")
                        .foregroundStyle(Color.white)
                }
                .buttonBorderShape(.roundedRectangle)
                .padding()
                .frame(width: 200)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.orange)
                )
                .glassEffect()
            }
        }
        .padding()
        // Leaving the tyre tab closes the stats popup.
        .onChange(of: model.selectedTab) { _, _ in previewedTyre = nil }
    }
}

#Preview {
    EditorView()
}
