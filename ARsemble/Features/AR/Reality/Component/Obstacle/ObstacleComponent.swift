//
//  ObstacleComponent.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 12/08/26.
//


import RealityKit
import ARKit
import Foundation

struct ObstacleComponent: Component {

    let meshID: UUID

    // World-space bounds of this mesh chunk.
    var aabbMin: SIMD3<Float> = .zero
    var aabbMax: SIMD3<Float> = .zero

    // Average position of the chunk.
    var centroid: SIMD3<Float> = .zero

    // Highest actual vertex in the chunk.
    var highestPoint: SIMD3<Float> = .zero

    // True when this chunk contains enough inclined faces.
    var isInclineSurface: Bool = false

    // True when this chunk contains a sufficiently large
    // approximately-horizontal elevated surface.
    var isTopSurface: Bool = false

    // Number of useful faces detected in this chunk.
    var faceCount: Int = 0

    // Highest point relative to the locked plane.
    var heightAbovePlane: Float = 0
}

