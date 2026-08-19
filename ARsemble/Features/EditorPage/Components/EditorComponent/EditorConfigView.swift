//
//  EditorConfigView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct EditorConfigView: View {
    @Bindable var viewModel: EditorViewModel

    var body: some View {
        VStack {
            Picker("Config Type", selection: $viewModel.selectedTab) {
                ForEach(EditorViewModel.ConfigTab.allCases, id: \.self) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 24)

            switch viewModel.selectedTab {
            case .structure:
                StructureConfigView(viewModel: viewModel)
            case .tyre:
                TyreConfigView(viewModel: viewModel)
            case .color:
                ColorConfigView(viewModel: viewModel)
            }
        }
        .padding(.top, 32)
        .padding(24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    EditorConfigView(viewModel: EditorViewModel())
}
