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

    var body: some View {
        VStack {
            HStack {
                CarViewerView(model: model)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)

                EditorConfigView(model: model)
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
    }
}

#Preview {
    EditorView()
}
