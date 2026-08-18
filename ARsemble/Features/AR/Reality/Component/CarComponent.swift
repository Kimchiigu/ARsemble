//
//  CarComponent.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 13/08/26.
//


import RealityKit

struct CarComponent: Component {

    var target: SIMD3<Float>?

    var hasStarted = false

    /// Car dimensions in metres (x = length, y = height, z = width). Used to
    /// work out the centre-of-gravity height vs. base width for tipping.
    var size: SIMD3<Float> = .zero

    /// Latches true once the car has toppled over on too-steep an incline.
    var tipped = false

    /// Current topple roll angle (radians), animated up to ~90°.
    var tipRoll: Float = 0
}
