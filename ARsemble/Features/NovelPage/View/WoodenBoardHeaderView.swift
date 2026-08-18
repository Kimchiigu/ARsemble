//
//  WoodenBoardHeaderView.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 17/08/26.
//

import SwiftUI
struct WoodenBoardHeaderView: View {
    var text: String
    var body: some View {
        Image("woodenboard")
        .resizable()
        .frame(width: 329, height: 90)
        .overlay(
            Text(text)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        )
    }
}

