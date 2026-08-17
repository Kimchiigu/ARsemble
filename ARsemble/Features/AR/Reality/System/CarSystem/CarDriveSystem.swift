//
//  CarDriveSystem.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 13/08/26.
//

import RealityKit

struct CarDriveSystem: System {

    static let query =
        EntityQuery(
            where: .has(CarComponent.self)
        )


    private let speed: Float = 0.3

    private let arrivalDistance: Float = 0.06


    init(scene: RealityKit.Scene) {}


    func update(
        context: SceneUpdateContext
    ) {

        for entity in context.entities(
            matching: Self.query,
            updatingSystemWhen: .rendering
        ) {

            guard var car =
                entity.components[
                    CarComponent.self
                ]
            else {
                continue
            }


            guard
                let target =
                    car.target
            else {
                continue
            }


            let current =
                entity.position(
                    relativeTo: nil
                )


            let toTarget =
                target -
                current


            let distance =
                simd_length(
                    toTarget
                )


            var motion =
                entity.components[
                    PhysicsMotionComponent.self
                ]
                ?? PhysicsMotionComponent()


            // ------------------------------------------------
            // Arrived — stop pushing, let physics settle it.
            // ------------------------------------------------

            if distance <= arrivalDistance {

                motion.linearVelocity =
                    .zero

                entity.components.set(
                    motion
                )

                car.target =
                    nil

                entity.components.set(
                    car
                )

                continue
            }


            // ------------------------------------------------
            // Drive HORIZONTALLY toward the target and let physics
            // (gravity + the ramp collider) do the actual climbing.
            // The vertical velocity is left to the simulation.
            // ------------------------------------------------

            let horizontal =
                SIMD3<Float>(
                    toTarget.x,
                    0,
                    toTarget.z
                )


            let horizontalLength =
                simd_length(
                    horizontal
                )


            let direction =
                horizontalLength > 1e-4
                ? horizontal / horizontalLength
                : SIMD3<Float>(0, 0, 0)


            motion.linearVelocity =
                SIMD3<Float>(
                    direction.x * speed,
                    motion.linearVelocity.y,
                    direction.z * speed
                )


            entity.components.set(
                motion
            )
        }
    }
}
