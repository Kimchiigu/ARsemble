//
//  NovelView.swift
//  ARsemble
//
//  Created by Catherine Danielle on 12/08/26.
//

import SwiftUI

struct NovelView: View {
    let pages = ["novelLevel1-1", "novelLevel1-2", "novelLevel1-3", "novelLevel1-4"]

    /// "Finish" on the last page and "Skip Story" both continue to Concept.
    var onContinue: () -> Void = {}

    @State private var index = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack {
                ZStack {
                    WoodenBoardHeaderView(text: "Incline Plane")
                    
                    HStack {
                        BackButton {
                            dismiss()
                        }.padding(.leading, 24).padding(.bottom, 36)
                        Spacer()
                        NextButton(title: "Skip Story") {
                            onContinue()
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Image(uiImage: UIImage(named: pages[index]) ?? UIImage())
                    .resizable()
                    .frame(width: 1130, height: 571)
                    .cornerRadius(16)

                Spacer()

                HStack {
                    if index > 0 {
                        NextButton(title: "Previous") {
                            index -= 1
                        }
                    }
                    Spacer()
                    NextButton(title: index == pages.count - 1 ? "Finish" : "Next") {
                        if index < pages.count - 1 {
                            index += 1
                        } else {
                            onContinue()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .padding(.top, 16)
        }
    }
}

#Preview(traits: .landscapeLeft) {
    NovelView()
}
