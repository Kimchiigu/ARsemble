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
