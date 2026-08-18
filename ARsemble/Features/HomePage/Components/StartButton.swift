//
//  startButton.swift
//  ARsemble
//
//  Created by Catherine Danielle on 12/08/26.
//

import SwiftUI

struct StartButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text("Start Learning")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding()
                .frame(width: 199, height: 50)
                .background(Color("Primary"))
                .cornerRadius(1000)
        }
        .padding()
    }
}

#Preview {
    StartButton()
}
