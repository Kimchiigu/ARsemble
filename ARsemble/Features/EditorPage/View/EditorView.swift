//
//  EditorView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct EditorView: View {
    var body: some View {
        VStack {
            HStack {
                Text("Car Model Here")
                Spacer()
                EditorConfigView()
            }
            
            HStack {
                Spacer()
                Button {
                    
                } label: {
                    Text("Ready")
                }
                .buttonBorderShape(.roundedRectangle)
                .padding()
                .background(Color.orange)
                .glassEffect()
            }
        }
        .padding()
    }
}

#Preview {
    EditorView()
}
