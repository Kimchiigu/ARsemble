//
//  CarBuildStateComponent.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 13/08/26.
//

import Foundation
import RealityKit

struct CarBuildStateComponent: Component {
    var lengthCm: Float
    var widthCm: Float
    var heightCm: Float
    var bodyColorId: UUID
    var tyreIndex: Int

    init(_ spec: CarSpecComponent) {
        lengthCm = spec.lengthCm
        widthCm = spec.widthCm
        heightCm = spec.heightCm
        bodyColorId = spec.bodyColorId
        tyreIndex = spec.tyreIndex
    }

    func matches(_ spec: CarSpecComponent) -> Bool {
        lengthCm == spec.lengthCm
            && widthCm == spec.widthCm
            && heightCm == spec.heightCm
            && bodyColorId == spec.bodyColorId
            && tyreIndex == spec.tyreIndex
    }
}
