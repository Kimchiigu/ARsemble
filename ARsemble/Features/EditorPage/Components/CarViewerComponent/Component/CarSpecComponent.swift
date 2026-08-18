//
//  CarSpecComponent.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 13/08/26.
//

import RealityKit
import UIKit

struct CarSpecComponent: Component {
    var lengthCm: Float
    var widthCm: Float
    var heightCm: Float
    var bodyColor: UIColor
    var bodyColorId: UUID
    var tyreIndex: Int
}

/// Identified by its configuration, not the UIColor instance — the palette
/// id already pins the color. Lets Route carry the spec as a payload.
extension CarSpecComponent: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.lengthCm == rhs.lengthCm
            && lhs.widthCm == rhs.widthCm
            && lhs.heightCm == rhs.heightCm
            && lhs.bodyColorId == rhs.bodyColorId
            && lhs.tyreIndex == rhs.tyreIndex
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(lengthCm)
        hasher.combine(widthCm)
        hasher.combine(heightCm)
        hasher.combine(bodyColorId)
        hasher.combine(tyreIndex)
    }
}
