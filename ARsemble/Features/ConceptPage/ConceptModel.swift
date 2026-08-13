//
//  ConceptModel.swift
//  ARsemble
//
//  Created by Catherine Danielle on 13/08/26.
//

import Foundation

enum BubbleSide{
    case left
    case right
}

struct ConceptModel: Identifiable{
    let id = UUID()
    let text: String
    let side: BubbleSide
}

