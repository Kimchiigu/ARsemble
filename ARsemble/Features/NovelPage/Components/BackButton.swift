//
//  BackButton.swift
//  ARsemble
//
//  Created by Catherine Danielle on 12/08/26.
//

import SwiftUI

struct BackButton: View {
    /// What happens on tap. Passed in by the parent so this button stays reusable.
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color("Primary"))
                .cornerRadius(1000)
        }
    }
}

#Preview {
    BackButton()
}
