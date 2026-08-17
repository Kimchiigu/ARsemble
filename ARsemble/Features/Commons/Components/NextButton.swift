//
//  NextButton.swift
//  ARsemble
//
//  Created by Catherine Danielle on 12/08/26.
//

import SwiftUI

struct NextButton: View {
    var title: String = "Next"
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .padding()
                .foregroundColor(.white)
                .frame(width: 185, height: 67)
                .background(Color("Primary"))
                .cornerRadius(1000)
        }
    }
}

#Preview {
    NextButton()
}
