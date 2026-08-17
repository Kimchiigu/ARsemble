//
//  BuildView.swift
//  ARsemble
//
//  Created by Catherine Danielle on 13/08/26.
//


import SwiftUI

struct BuildView: View {
    let message: String
    let imageName: String
    
    
    var body: some View {
        VStack(spacing: 24) {
            BubbleLeft(text: message)
            
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white)
                    .frame(width: 1130, height: 408)
                
                loadImage(imageName)
                    .scaledToFit()
                    .padding(30)
            }
        }
        .frame(height: 320)
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private func loadImage(_ name: String) -> some View {
        if let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
        } else {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.gray)
                .frame(width: 80, height: 80)
        }
    }
}

#Preview {
    BuildView(message: "String", imageName: "Frame 11")
}
