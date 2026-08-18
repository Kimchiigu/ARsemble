//
//  SummaryPageView.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 17/08/26.
//
import SwiftUI
struct SummaryPageView: View{

    /// "Finish" — the level is done; mark progress and leave for the level map.
    var onFinish: () -> Void = {}

    /// "Rebuild Car" — go back to the editor (current car config is kept).
    var onRebuild: () -> Void = {}

    var body: some View{
        VStack(alignment: .center, spacing: 27){
            FreeBubbleChat(text: "You mastered center of gravity to keep your car from rolling over!")
            GIFView(gifName: "review").frame(width: 994, height: 520).clipShape(RoundedRectangle(cornerRadius: 30))
            HStack{
                Button {
                    onRebuild()
                } label: {
                    Label("Rebuild Car", systemImage: "wrench.adjustable.fill")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .clipShape(Capsule())
                        .foregroundStyle(Color.gray)
                        .frame(width: 240)
                }.buttonStyle(.glassProminent).tint(.clear)

                Spacer()

                Button {
                    onFinish()
                } label: {
                    Label("Finish", systemImage: "iphone.and.arrow.right.outward")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                            .frame(width: 190)
                }.buttonStyle(.glassProminent).tint(Color("Primary"))
            }
        }.padding(32)
    }
}

#Preview {
    SummaryPageView()
}
