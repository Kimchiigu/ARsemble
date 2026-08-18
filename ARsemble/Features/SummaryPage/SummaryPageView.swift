//
//  SummaryPageView.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 17/08/26.
//
import SwiftUI
struct SummaryPageView: View{
    @State private var showEditor = false
    @State private var showLevel = false
    var body: some View{
        VStack(spacing: 27){
            VStack(spacing:17){
                WoodenBoardHeaderView(text: "Incline Plane")
                
                HStack{
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
                        
                        Text("You helped Arlo climb the hill!")
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .font(.title3)
                            .bold()
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    
                }
            }
            
            Image("placeholder_summary")
            HStack{
                Button {
                    showEditor = true
                } label: {
                    Label("Rebuild Car", systemImage: "wrench.adjustable.fill")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(.orange)
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }

                Spacer()
                
                Button {
                    showLevel = true
                } label: {
                    Label("Finish", systemImage: "wrench.adjustable.fill")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(.orange)
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }
            }
        }.padding(32)
        .fullScreenCover(isPresented: $showEditor) {
            EditorView()
        }
        .fullScreenCover(isPresented: $showLevel) {
//            LevelPageView()
        }
    }
}

#Preview {
    SummaryPageView()
}
