//
//  CreateHalfCapsuleMesh.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 17/08/26.
//

import RealityKit

func makeHalfCapsuleMesh(
    width: Float,
    height: Float,
    depth: Float,
    radius: Float
) -> MeshResource {

    let halfDepth = depth / 2

    // ------------------------------------------------------------
    // Profile
    //
    // Start at top-left and travel clockwise.
    //
    //       0────────1
    //       │        │
    //       │        │
    //       │        │
    //       7        2
    //        ╲      ╱
    //         ╲____╱
    // ------------------------------------------------------------

    var profile: [SIMD2<Float>] = []

    let arcSegments = 16

    // Top-left
    profile.append(
        SIMD2(
            -width / 2,
            height
        )
    )

    // Top-right
    profile.append(
        SIMD2(
            width / 2,
            height
        )
    )

    // Right side
    profile.append(
        SIMD2(
            width / 2,
            radius
        )
    )

    // Rounded bottom
    for i in 0...arcSegments {

        let t = Float(i) / Float(arcSegments)

        let angle = t * Float.pi

        let x = cos(angle) * radius
        let y = radius - sin(angle) * radius

        profile.append(
            SIMD2(
                x,
                y
            )
        )
    }

    // Left side
    profile.append(
        SIMD2(
            -width / 2,
            radius
        )
    )

    // ------------------------------------------------------------
    // Create front/back vertices
    // ------------------------------------------------------------

    var vertices: [SIMD3<Float>] = []

    for point in profile {

        vertices.append(
            SIMD3(
                point.x,
                point.y,
                halfDepth
            )
        )
    }

    for point in profile {

        vertices.append(
            SIMD3(
                point.x,
                point.y,
                -halfDepth
            )
        )
    }

    let count = profile.count

    // ------------------------------------------------------------
    // Add center vertices for front/back faces
    // ------------------------------------------------------------

    let frontCenterIndex = UInt32(vertices.count)

    vertices.append(
        SIMD3(
            0,
            height * 0.5,
            halfDepth
        )
    )

    let backCenterIndex = UInt32(vertices.count)

    vertices.append(
        SIMD3(
            0,
            height * 0.5,
            -halfDepth
        )
    )

    // ------------------------------------------------------------
    // Triangle indices
    // ------------------------------------------------------------

    var indices: [UInt32] = []

    // Front face
    for i in 0..<count {

        let next = (i + 1) % count

        indices.append(frontCenterIndex)
        indices.append(UInt32(i))
        indices.append(UInt32(next))
    }

    // Back face
    for i in 0..<count {

        let next = (i + 1) % count

        indices.append(backCenterIndex)
        indices.append(UInt32(count + next))
        indices.append(UInt32(count + i))
    }

    // ------------------------------------------------------------
    // Side walls
    // ------------------------------------------------------------

    for i in 0..<count {

        let next = (i + 1) % count

        let frontA = UInt32(i)
        let frontB = UInt32(next)

        let backA = UInt32(count + i)
        let backB = UInt32(count + next)

        // First triangle
        indices.append(frontA)
        indices.append(backA)
        indices.append(frontB)

        // Second triangle
        indices.append(frontB)
        indices.append(backA)
        indices.append(backB)
    }

    // ------------------------------------------------------------
    // RealityKit mesh
    // ------------------------------------------------------------

    var descriptor = MeshDescriptor()

    descriptor.positions = MeshBuffer(vertices)
    descriptor.primitives = .triangles(indices)

    do {
        return try MeshResource.generate(
            from: [descriptor]
        )
    } catch {
        fatalError(
            "Failed to create half-capsule marker mesh: \(error)"
        )
    }
}
