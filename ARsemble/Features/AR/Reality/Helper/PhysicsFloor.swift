//
//  PhysicsFloor.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 12/08/26.
//

import RealityKit
import SwiftUI
import ARKit
enum PhysicsFloor {

    private static let name = "SurfacePhysicsFloor"
    private static let thickness: Float = 0.01

    /// Adds (or resizes) an invisible static collider covering the plane.
    static func attach(to anchor: AnchorEntity, for plane: ARPlaneAnchor) {
        anchor.children
            .filter { $0.name == name }
            .forEach { $0.removeFromParent() }

        let w = max(plane.planeExtent.width, 0.05)
        let h = max(plane.planeExtent.height, 0.05)

        // No mesh/material — a collider + physics body only, so it stays truly
        // invisible. (A .clear UnlitMaterial renders as a solid black box.)
        let floor = ModelEntity()
        floor.name = name

        // Sit the slab just under the surface so objects rest on the plane.
        floor.position = plane.center + [0, -thickness * 0.5, 0]
        floor.orientation = simd_quatf(angle: plane.planeExtent.rotationOnYAxis, axis: [0, 1, 0])

        floor.collision = CollisionComponent(shapes: [.generateBox(size: [w, thickness, h])])
        floor.physicsBody = PhysicsBodyComponent(
            massProperties: .default,
            material: .generate(friction: 0.6, restitution: 0.1),
            mode: .static
        )

        anchor.addChild(floor)
    }
}
