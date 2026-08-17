//
//  CarDriveSystem.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 13/08/26.
//
//  Drives the already-placed car toward the finish point. The car exists before
//  the obstacle is chosen (it's placed during the drag-to-fit phase), so this
//  system reads the finish target LIVE from SurfaceScanComponent and only starts
//  moving once placement is confirmed and a finish exists.
//

import RealityKit

struct CarDriveSystem: System {

    static let carQuery =
        EntityQuery(
            where: .has(CarComponent.self)
        )

    static let scanQuery =
        EntityQuery(
            where: .has(SurfaceScanComponent.self)
        )


    private let speed: Float = 0.3

    /// Horizontal "hit" radius around the finish that counts as reaching it.
    private let arrivalDistance: Float = 0.08

    /// How far below the finish height still counts as "climbed to it".
    private let heightTolerance: Float = 0.06

    /// How fast the car turns to face the finish (radians/second).
    private let turnRate: Float = 4.0

    /// Only drives forward once its heading is within this of the target.
    private let facingThreshold: Float = 0.35


    init(scene: RealityKit.Scene) {}


    func update(
        context: SceneUpdateContext
    ) {

        // ----------------------------------------------------
        // Pull the goal + presenter from the scan entity.
        // ----------------------------------------------------

        var target: SIMD3<Float>?
        var presenter: SurfaceScanDriver?
        var finishConfirmed = false

        for entity in context.entities(
            matching: Self.scanQuery,
            updatingSystemWhen: .rendering
        ) {
            if let component =
                entity.components[
                    SurfaceScanComponent.self
                ] {

                target = component.finishTarget
                presenter = component.presenter
                finishConfirmed = component.finishConfirmed
            }
        }


        // Only drive once the finish marker has been CONFIRMED by the player.
        guard
            finishConfirmed,
            let target
        else {
            return
        }


        // ----------------------------------------------------
        // Drive each car toward the finish.
        // ----------------------------------------------------

        for entity in context.entities(
            matching: Self.carQuery,
            updatingSystemWhen: .rendering
        ) {

            let current =
                entity.position(
                    relativeTo: nil
                )

            let toTarget =
                target - current


            var motion =
                entity.components[
                    PhysicsMotionComponent.self
                ]
                ?? PhysicsMotionComponent()


            // Reached the finish: horizontally ON the spot AND climbed up to it.
            // (The height check avoids a false success while still at the base.)
            let horizontalGap =
                simd_length(
                    SIMD3<Float>(
                        toTarget.x,
                        0,
                        toTarget.z
                    )
                )

            if horizontalGap <= arrivalDistance &&
                current.y >= target.y - heightTolerance {

                motion.linearVelocity = .zero
                entity.components.set(motion)

                presenter?.reportSuccess()

                continue
            }


            // Direction to the finish (horizontal).
            let horizontal =
                SIMD3<Float>(
                    toTarget.x,
                    0,
                    toTarget.z
                )

            let horizontalLength =
                simd_length(horizontal)

            guard horizontalLength > 1e-4 else {
                entity.components.set(motion)
                continue
            }

            let direction =
                horizontal / horizontalLength


            // ------------------------------------------------
            // Steer the heading toward the finish (yaw only).
            //
            // IMPORTANT: we no longer force the orientation flat. A
            // forced-flat box can't conform to the ramp, so it jammed
            // at the base and never climbed. Now the car is free to
            // TILT with the incline (that's what lets it climb); we
            // only steer its yaw, and preserve the pitch/roll the ramp
            // contact produces. The low centre of gravity keeps it from
            // tipping over.
            // ------------------------------------------------

            let desiredYaw =
                atan2(-direction.z, direction.x)

            let forward =
                entity.orientation(relativeTo: nil).act(
                    SIMD3<Float>(1, 0, 0)
                )

            let currentYaw =
                atan2(-forward.z, forward.x)

            var yawError =
                desiredYaw - currentYaw

            while yawError > .pi { yawError -= 2 * .pi }
            while yawError < -.pi { yawError += 2 * .pi }

            let yawSteer =
                max(-4, min(4, yawError * 6))

            motion.angularVelocity =
                SIMD3<Float>(
                    motion.angularVelocity.x,   // keep ramp-induced tilt
                    yawSteer,                    // steer toward the finish
                    motion.angularVelocity.z
                )


            // ------------------------------------------------
            // Drive horizontally toward the finish. Physics + the ramp
            // collider turn this into a climb; vertical velocity is left
            // to the simulation.
            // ------------------------------------------------

            motion.linearVelocity =
                SIMD3<Float>(
                    direction.x * speed,
                    motion.linearVelocity.y,
                    direction.z * speed
                )


            entity.components.set(motion)
        }
    }
}
