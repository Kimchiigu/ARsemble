//
//  ConceptViewModel.swift
//  ARsemble
//
//  Created by Catherine Danielle on 13/08/26.
//

import SwiftUI

@MainActor
final class ConceptViewModel: ObservableObject {
    
    @Published private(set) var messages: [ConceptModel] = []
    @Published private(set) var visibleCount = 0
    private let delayPerMessage: Double
    private let allMessages: [ConceptModel]
    
    init(
        message: [ConceptModel] = ConceptViewModel.defaultMessages,
        delayPerMessages: Double = 0.5
    ) {
        self.messages = message
        self.delayPerMessage = delayPerMessages
        self.allMessages = message
    }
    
    func startConversation() async{
        visibleCount = 0
        for idx in allMessages.indices {
            try? await Task.sleep(nanoseconds: UInt64(delayPerMessage * 1_000_000_000))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5)) {
                visibleCount = idx + 1
            }
        }
    }
    
    var visibleMessages: ArraySlice<ConceptModel> {
        messages.prefix(visibleCount)
    }
}

extension ConceptViewModel {
    static let defaultMessages: [ConceptModel] = [
        ConceptModel(text: "OH NO! My car fell...", side: .left),
        ConceptModel(text: "What happened?", side: .right),
        ConceptModel(text: "I think my car can’t climb the ramp because its center of gravity is off", side: .left),
        ConceptModel(text: "What is center of gravity?", side: .right)]
}
    

