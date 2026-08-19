//
//  BackButton.swift
//  ARsemble
//
//  Created by Catherine Danielle on 12/08/26.
//

import SwiftUI

struct BackButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: "rectangle.portrait.and.arrow.forward")
                .font(.title)
                .frame(width: 50, height: 50)
                .padding(5)
                .foregroundStyle(Color("Primary"))
                .clipShape(Circle())
        }.buttonStyle(.glass)
    }
}

#Preview {
    BackButton()
}
