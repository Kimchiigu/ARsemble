//
//  EditorView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct EditorView: View {
    @State private var viewModel = EditorViewModel()

    var body: some View {
        VStack {
            HStack {
                CarViewerView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)

                EditorConfigView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .layoutPriority(1)
            }

            HStack {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 64, height: 64)

                    Image("armadillo-editor")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                }

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.blue.opacity(0.7), lineWidth: 1)
                        )

                    BubbleTail()
                        .fill(Color.blue)
                        .frame(width: 20, height: 24)
                        .offset(x: -18)

                    Text("Design a car that has a low center of gravity.")
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .font(.title3)
                        .bold()
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button {
                    viewModel.reset()
                } label: {
                    Text("Reset to Default")
                        .foregroundStyle(Color.black)
                }
                .buttonBorderShape(.roundedRectangle)
                .padding()
                .frame(width: 200)
                .glassEffect()

                Button {} label: {
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
