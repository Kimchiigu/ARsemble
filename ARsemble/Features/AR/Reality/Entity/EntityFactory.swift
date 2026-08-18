//
//  EntityFactory.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 12/08/26.
//
import SwiftUI
import RealityKit
import UIKit

struct EntityFactory {

    /// Placeholder spec for testing before the editor's saved car is wired in.
    /// Swap this for the real CarSpecComponent coming out of the editor.
    static func placeholderCarSpec() -> CarSpecComponent {
        CarSpecComponent(
            lengthCm: 12,
            widthCm: 7,
            heightCm: 4,
            bodyColor: .systemRed,
            bodyColorId: UUID(),
            tyreIndex: 0
        )
    }

    /// Builds the editor's car model (via CarBuilder) at real-world size and
    /// attaches the physics body + collider with a low centre of gravity so it
    /// stays planted while climbing the ramp.
    ///
    /// The returned root is what carries CarComponent / physics; the visual
    /// model lives as a child so physics moves the whole car together.
    static func createCar(spec: CarSpecComponent) -> ModelEntity {

        let carRoot = ModelEntity()
        carRoot.name = "VirtualCar"

        // Build the visual model, then scale it from the editor's display scale
        // (CarBuilder.displayScale, 3×) down to real-world size.
        let visual = Entity()
        CarBuilder.assemble(visual, spec: spec)
        visual.scale = SIMD3<Float>(repeating: 1.0 / CarBuilder.displayScale)
        carRoot.addChild(visual)

        // Physics collider sized to the real car (cm -> m).
        let size = SIMD3<Float>(spec.lengthCm, spec.heightCm, spec.widthCm) * 0.01
        let shape = ShapeResource.generateBox(size: size)
        carRoot.components.set(CollisionComponent(shapes: [shape]))

        // Centre of gravity at the BASE of the car, so a tall/narrow body
        // doesn't lean when it hits the incline. (CarDriveSystem also keeps the
        // car upright while driving.)
        var mass = PhysicsMassProperties(shape: shape, mass: 0.3)
        mass.centerOfMass.position = SIMD3<Float>(0, -size.y * 0.5, 0)

        var body = PhysicsBodyComponent(
            massProperties: mass,
            material: .generate(friction: 0.7, restitution: 0.0),
            mode: .dynamic
        )
        body.isAffectedByGravity = true
        carRoot.components.set(body)

        // Lets CarDriveSystem set the car's velocity each frame.
        carRoot.components.set(PhysicsMotionComponent())

        // Red arrow pointing down at the car's centre of gravity.
        carRoot.addChild(makeCoGArrow(carHeight: size.y))

        return carRoot
    }


    // MARK: - Centre-of-gravity arrow

    /// A red arrow that sits just above the car and points straight down at it,
    /// visualising where the weight pulls (the centre of gravity).
    private static func makeCoGArrow(carHeight: Float) -> Entity {

        let arrow = Entity()
        let red = UnlitMaterial(color: .red)

        let headHeight: Float = 0.02
        let headRadius: Float = 0.012
        let shaftHeight: Float = 0.05
        let shaftRadius: Float = 0.004

        // Cone: apex at local (0,0,0), base at +headHeight → points DOWN.
        let head = ModelEntity(
            mesh: makeConeMesh(radius: headRadius, height: headHeight),
            materials: [red]
        )
        arrow.addChild(head)

        // Shaft above the cone base.
        let shaft = ModelEntity(
            mesh: .generateCylinder(height: shaftHeight, radius: shaftRadius),
            materials: [red]
        )
        shaft.position = [0, headHeight + shaftHeight / 2, 0]
        arrow.addChild(shaft)

        // Tip at the BASE of the car (its centre of gravity), pointing down.
        arrow.position = [0, -carHeight * 0.5, 0]

        return arrow
    }

    /// Builds a simple cone mesh (apex at the origin, base at +height). Faces are
    /// double-sided so it renders from any angle. RealityKit has no cone
    /// primitive, so we generate one.
    private static func makeConeMesh(
        radius: Float,
        height: Float,
        segments: Int = 16
    ) -> MeshResource {

        var positions: [SIMD3<Float>] = []
        var triangles: [UInt32] = []

        positions.append(SIMD3<Float>(0, 0, 0))   // 0: apex (tip)

        for i in 0..<segments {
            let a = Float(i) / Float(segments) * 2 * .pi
            positions.append(
                SIMD3<Float>(cos(a) * radius, height, sin(a) * radius)
            )
        }

        let baseCenter = UInt32(positions.count)
        positions.append(SIMD3<Float>(0, height, 0))   // base centre

        for i in 0..<segments {
            let a = UInt32(1 + i)
            let b = UInt32(1 + (i + 1) % segments)

            // Side (both windings so it's visible from any side).
            triangles += [0, a, b]
            triangles += [0, b, a]

            // Base cap.
            triangles += [baseCenter, b, a]
            triangles += [baseCenter, a, b]
        }

        var descriptor = MeshDescriptor(name: "cone")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.primitives = .triangles(triangles)

        return (try? MeshResource.generate(from: [descriptor]))
            ?? .generateSphere(radius: radius)
    }

    static func createObstacle(_ id: UUID, in root: Entity) -> ModelEntity {
        let entity = ModelEntity()               // invisible — the real object is already visible
        entity.name = "obstacle_\(id.uuidString)"
        entity.components.set(ObstacleComponent(meshID: id))
        root.addChild(entity)
        return entity
    }
    
    
    static func createFinishMarker(
        in root: Entity
        , finishName: String
    ) -> ModelEntity {

        let marker = ModelEntity()
        marker.name = finishName

        // ============================================================
        // MARK: Appearance
        // ============================================================

        let green = UIColor.systemGreen

        // Main translucent material
        var material = UnlitMaterial(
            color: green.withAlphaComponent(0.72)
        )

        material.blending = .transparent(opacity: 0.72)

        // ============================================================
        // MARK: Half-capsule geometry
        //
        // Shape:
        //
        //        ┌──────────┐
        //        │          │
        //        │          │
        //        │          │
        //        ╰──────────╯
        //
        // Flat top + vertical sides + rounded bottom.
        // ============================================================

        let width: Float = 0.06
        let height: Float = 0.05
        let depth: Float = 0.02

        let radius = width / 2

        let mesh = makeHalfCapsuleMesh(
            width: width,
            height: height,
            depth: depth,
            radius: radius
        )

        let body = ModelEntity(
            mesh: mesh,
            materials: [material]
        )

        marker.addChild(body)

        // ============================================================
        // MARK: Inner glow
        // ============================================================

        var glowMaterial = UnlitMaterial(
            color: green.withAlphaComponent(0.16)
        )

        glowMaterial.blending = .transparent(opacity: 0.16)

        let glowMesh = MeshResource.generateBox(
            size: [
                width * 0.92,
                height * 0.80,
                depth * 1.5
            ]
        )

        let glow = ModelEntity(
            mesh: glowMesh,
            materials: [glowMaterial]
        )

        glow.position.y = height * 0.38
        marker.addChild(glow)

        // ============================================================
        // MARK: Point light
        // ============================================================

        let light = PointLight()

        light.light.color = green
        light.light.intensity = 2500
        light.light.attenuationRadius = 0.45

        light.position = [
            0,
            height * 0.45,
            0.04
        ]

        marker.addChild(light)

        // ============================================================
        // Add to scene
        // ============================================================

        root.addChild(marker)

        return marker
    }
    
    
}
