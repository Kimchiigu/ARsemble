//
//  CarDriveSystem.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 13/08/26.
//
//  Drives the placed car toward the finish. Uses TERRAIN FOLLOWING: each frame
//  it steps horizontally toward the finish, raycasts straight down onto the
//  obstacle / floor colliders, and rides the surface height it finds. This
//  climbs any ramp deterministically (no dependence on tricky rigid-body
//  contact behaviour on noisy LiDAR meshes).
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


    private let speed: Float = 0.15            // horizontal m/s

    private let climbRate: Float = 0.25        // max upward m/s (ride ramps, not walls)
    private let fallRate: Float = 0.8          // max downward m/s

    private let turnRate: Float = 4.0          // yaw rad/s
    private let facingThreshold: Float = 0.35  // rad; drive only when facing

    private let arrivalDistance: Float = 0.08  // horizontal hit radius
    private let heightTolerance: Float = 0.06  // must be near the finish height

    private let toppleRate: Float = 3.0        // how fast it falls over (rad/s)


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


        let dt = Float(context.deltaTime)


        let worldUp = SIMD3<Float>(0, 1, 0)

        // ----------------------------------------------------
        // Drive each car toward the finish.
        // ----------------------------------------------------

        for entity in context.entities(
            matching: Self.carQuery,
            updatingSystemWhen: .rendering
        ) {

            guard var car =
                entity.components[CarComponent.self]
            else {
                continue
            }

            let current =
                entity.position(relativeTo: nil)

            // Real surface under the car: height + normal.
            let info = presenter?.surfaceInfo(under: current)
            let normal = info?.normal ?? worldUp

            let toTarget = target - current
            let horizontal =
                SIMD3<Float>(toTarget.x, 0, toTarget.z)
            let horizontalGap = simd_length(horizontal)

            let direction =
                horizontalGap > 1e-4
                ? horizontal / horizontalGap
                : entity.orientation(relativeTo: nil).act(SIMD3<Float>(1, 0, 0))

            var newPos = current


            // Is the car still over the REAL play surface (the locked table)?
            // Past the detected edge it must fall — not float on an infinite
            // estimated plane. A few consecutive off-edge frames are required so
            // plane-boundary jitter can't trigger a false fall mid-table.
            let onSurface =
                presenter?.isWithinPlayableSurface(current) ?? true

            if !car.tipped && !car.falling {
                if onSurface {
                    car.offEdgeFrames = 0
                } else {
                    car.offEdgeFrames += 1
                    if car.offEdgeFrames >= 4 {
                        car.falling = true
                    }
                }
            }


            if car.tipped {

                // Already toppled — keep falling over, no more driving.
                car.tipRoll = min(car.tipRoll + toppleRate * dt, .pi / 2)

            } else if car.falling {

                // Drove off the edge — gravity takes over and it drops.
                let gravity: Float = 3.0
                car.fallSpeed += gravity * dt
                newPos.y = current.y - car.fallSpeed * dt

                // Carry a little forward momentum off the ledge.
                newPos.x += direction.x * speed * dt * 0.4
                newPos.z += direction.z * speed * dt * 0.4

                presenter?.reportFellOff()

            } else {

                // Reached the finish?
                if horizontalGap <= arrivalDistance &&
                    current.y >= target.y - heightTolerance {

                    stop(entity)
                    presenter?.reportSuccess()
                    entity.components.set(car)
                    continue
                }

                // Step horizontally toward the finish.
                if horizontalGap > 1e-4 {
                    let stepDist = min(speed * dt, horizontalGap)
                    newPos.x += direction.x * stepDist
                    newPos.z += direction.z * stepDist
                }

                // --------------------------------------------
                // TIPPING: compare the incline angle to the car's tip
                // threshold. A tall car (high CoG) / narrow base tips at a
                // gentler slope; a low, wide car stays planted.
                // --------------------------------------------

                let inclineAngle =
                    acos(max(-1, min(1, simd_dot(normal, worldUp))))

                let cogHeight =
                    max(car.size.y * 0.5, 0.005)

                let baseHalfWidth =
                    max(min(car.size.x, car.size.z) * 0.5, 0.005)

                let tipAngle =
                    atan2(baseHalfWidth, cogHeight)

                if inclineAngle > tipAngle {
                    car.tipped = true
                    presenter?.reportTipOver()
                }
            }


            // Ride the surface height (ARKit raycast — follows the incline).
            // Skipped while falling so the car keeps dropping off the edge.
            if !car.falling, let info {
                let carLift = liftFor(entity)
                let desiredY = info.height + carLift
                let dy = desiredY - current.y
                newPos.y =
                    current.y +
                    max(-fallRate * dt, min(climbRate * dt, dy))
            }


            // Orientation: hold the current orientation while falling; otherwise
            // align to the surface + face the target (+ topple roll). Smoothed.
            if !car.falling {
                let targetOrientation =
                    surfaceOrientation(
                        forward: direction,
                        up: normal,
                        roll: car.tipped ? car.tipRoll : 0
                    )

                let smoothed =
                    simd_slerp(
                        entity.orientation(relativeTo: nil),
                        targetOrientation,
                        0.25
                    )

                entity.setOrientation(smoothed, relativeTo: nil)
            }

            entity.setPosition(newPos, relativeTo: nil)

            stop(entity)
            entity.components.set(car)
        }
    }


    // MARK: - Helpers

    /// Zeroes the car's physics velocity so gravity/contacts don't fight the
    /// kinematic terrain following.
    private func stop(_ entity: Entity) {
        var motion =
            entity.components[PhysicsMotionComponent.self]
            ?? PhysicsMotionComponent()
        motion.linearVelocity = .zero
        motion.angularVelocity = .zero
        entity.components.set(motion)
    }


    /// Distance from the car's origin to its lowest visible point, so its wheels
    /// sit on the surface.
    private func liftFor(_ entity: Entity) -> Float {
        let bounds = entity.visualBounds(relativeTo: entity)
        return max(0.01, -bounds.min.y)
    }


    /// Orientation that plants the car on the surface (up = surface normal) and
    /// faces the target (front = +X), plus an optional topple roll.
    private func surfaceOrientation(
        forward dir: SIMD3<Float>,
        up normalIn: SIMD3<Float>,
        roll: Float
    ) -> simd_quatf {

        let up =
            simd_length(normalIn) > 1e-4
            ? simd_normalize(normalIn)
            : SIMD3<Float>(0, 1, 0)

        // Project the travel direction onto the surface plane.
        var fwd = dir - up * simd_dot(dir, up)
        if simd_length(fwd) < 1e-4 {
            fwd = SIMD3<Float>(1, 0, 0)
        }
        fwd = simd_normalize(fwd)

        let side = simd_normalize(simd_cross(fwd, up))

        let basis = simd_float3x3(fwd, up, side)
        var q = simd_quatf(basis)

        if roll != 0 {
            // Roll about the forward axis to fall onto its side.
            q = simd_quatf(angle: roll, axis: fwd) * q
        }

        return q
    }
}
