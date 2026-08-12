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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                
                EditorConfigView()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .layoutPriority(1)
            }
            
            HStack {
                Spacer()
                Button {
                    
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
