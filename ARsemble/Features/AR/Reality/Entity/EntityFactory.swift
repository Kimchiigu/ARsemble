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
    
    
    /// Height (metres) the loaded flag is normalised to.
    private static let flagHeight: Float = 0.18

    /// Cached flag model so it's only loaded from disk once.
    @MainActor private static var flagTemplate: ModelEntity?

    /// Finish marker = the "bendera" flag usdz standing on the obstacle top.
    ///
    /// The usdz loads asynchronously, so the marker entity is returned
    /// immediately (empty) and the flag is attached as a child once it's ready.
    /// CarDriveSystem keeps moving/positioning the marker, and the flag rides
    /// along as a child.
    static func createFinishMarker(
        in root: Entity,
        finishName: String
    ) -> ModelEntity {

        let marker = ModelEntity()
        marker.name = finishName

        root.addChild(marker)

        // Load + attach the flag model (cached after the first load).
        attachFlag(to: marker)

        return marker
    }


    /// Attaches the flag model to the marker, cloning the cached template if
    /// already loaded, otherwise loading it asynchronously first. Nonisolated so
    /// it can be called from the (nonisolated) ECS update; all RealityKit work
    /// happens inside the main-actor Task.
    private static func attachFlag(to marker: ModelEntity) {

        Task { @MainActor in

            let template: ModelEntity

            if let cached = flagTemplate {
                template = cached
            } else {
                do {
                    template = try await ModelEntity(named: "bendera")
                    flagTemplate = template
                } catch {
                    print("EntityFactory: ✗ failed to load flag 'bendera': \(error)")
                    return
                }
            }

            addFlagClone(template, to: marker)
        }
    }


    /// Clones the flag, scales it to `flagHeight`, and stands its base at the
    /// marker origin (which sits on the obstacle's top surface).
    @MainActor
    private static func addFlagClone(
        _ template: ModelEntity,
        to marker: ModelEntity
    ) {

        // Don't double-add if this runs twice.
        guard marker.findEntity(named: "FinishFlagModel") == nil else { return }

        let flag = template.clone(recursive: true)
        flag.name = "FinishFlagModel"

        // Measure the model at its native size, then normalise.
        let bounds = flag.visualBounds(recursive: true, relativeTo: nil)
        let dim = bounds.max - bounds.min
        let nativeHeight = max(dim.y, 0.0001)
        let scale = flagHeight / nativeHeight
        flag.scale = SIMD3<Float>(repeating: scale)

        // Centre it horizontally over the marker and sit its base at y = 0.
        flag.position = SIMD3<Float>(
            -bounds.center.x * scale,
            -bounds.min.y * scale,
            -bounds.center.z * scale
        )

        marker.addChild(flag)
    }
}
