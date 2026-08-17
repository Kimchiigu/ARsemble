//
//  SurfaceLockSystem.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 12/08/26.
//


import RealityKit
import ARKit


// MARK: - System (behaviour)

/// Runs every frame. Locks the first horizontal plane, keeps the red rectangle
/// and physics floor in sync with it, and services spawn/reset requests.

struct SurfaceLockSystem: System {

    static let query =
        EntityQuery(
            where:
                .has(
                    SurfaceScanComponent.self
                )
        )


    init(scene: RealityKit.Scene) {}


    func update(
        context: SceneUpdateContext
    ) {

        for entity in context.entities(
            matching: Self.query,
            updatingSystemWhen: .rendering
        ) {

            guard var component =
                    entity.components[
                        SurfaceScanComponent.self
                    ]
            else {
                continue
            }


            if component.resetRequested {

                reset(
                    &component,
                    scene:
                        context.scene
                )

            }
            else if component.lockedPlaneID == nil {

                tryLock(
                    &component,
                    scene:
                        context.scene
                )

            }
            else {

                // Keep the surface pinned to the largest (base) plane until
                // the user commits a target, so the obstacle stays above y=0.
                if !component.targetLocked {
                    relockIfLargerPlaneAppeared(
                        &component,
                        scene:
                            context.scene
                    )
                }

                follow(
                    &component
                )
                // Car spawning is handled by CarSpawnSystem.
            }


            entity.components.set(
                component
            )
        }
    }


    // MARK: Lock

    private func tryLock(
        _ component:
            inout SurfaceScanComponent,

        scene:
            RealityKit.Scene
    ) {

        guard
            let plane =
                largestPlane(
                    component.detectedPlanes
                )
        else {
            return
        }


        let anchor =
            AnchorEntity(
                anchor:
                    plane
            )


        scene.addAnchor(
            anchor
        )


        PhysicsFloor.attach(
            to:
                anchor,

            for:
                plane
        )


        component.surfaceAnchor =
            anchor

        component.lockedPlaneID =
            plane.identifier

        component.lockedExtent =
            extent(
                of:
                    plane
            )


        component.presenter?
            .hasLockedSurface = true


        component.presenter?
            .statusText =
            "Tap anywhere on the table to place Arlo’s car"
    }


    // MARK: Follow

    private func follow(
        _ component:
            inout SurfaceScanComponent
    ) {

        guard
            let anchor =
                component.surfaceAnchor,

            let plane =
                component.detectedPlanes.first(
                    where:
                        {
                            $0.identifier ==
                                component.lockedPlaneID
                        }
                )
        else {
            return
        }


        let current =
            extent(
                of:
                    plane
            )


        if let previous =
            component.lockedExtent,

           simd_distance(
                previous,
                current
           ) < 0.005 {

            return
        }


        PhysicsFloor.attach(
            to:
                anchor,

            for:
                plane
        )


        component.lockedExtent =
            current
    }


    // MARK: Reset

    private func reset(
        _ component: inout SurfaceScanComponent,
        scene: RealityKit.Scene
    ) {

        // ==================================================
        // SURFACE
        // ==================================================

        component.surfaceAnchor?
            .removeFromParent()

        component.surfaceAnchor =
            nil

        component.lockedPlaneID =
            nil

        component.lockedExtent =
            nil

        component.detectedPlanes =
            []


        // ==================================================
        // TARGET
        // ==================================================

        component.requestedTargetPoint =
            nil

        component.targetCenter =
            nil

        component.targetLocked =
            false


        // ==================================================
        // OBSTACLE MESH
        // ==================================================

        scene.anchors
            .first(
                where: {
                    $0.name ==
                    "ObstacleRoot"
                }
            )?
            .removeFromParent()

        component.meshAnchors =
            [:]

        component.dirtyMeshIDs =
            []

        component.removedMeshIDs =
            []


        // ==================================================
        // FINISH
        // ==================================================

        component.finishTarget =
            nil

        component.successHeight =
            nil

        component.finishFrozen =
            false

        component.settleElapsed =
            0


        // ==================================================
        // CAR
        // ==================================================

        component.spawnCarRequested =
            false

        component.carSpawnPoint =
            nil


        // ==================================================
        // RESET REQUEST
        // ==================================================

        component.resetRequested =
            false


        // ==================================================
        // UI
        // ==================================================

        component.presenter?
            .hasLockedSurface =
            false

        component.presenter?
            .targetLocked =
            false

        component.presenter?
            .obstacleDetected =
            false

        component.presenter?
            .finishPlaced =
            false

        component.presenter?
            .didSucceed =
            false

        component.presenter?
            .statusText =
            "Move device slowly to scan a floor or table…"
    }

    private func extent(
        of plane:
            ARPlaneAnchor
    ) -> SIMD2<Float> {

        SIMD2<Float>(
            plane.planeExtent.width,
            plane.planeExtent.height
        )
    }


    // MARK: Plane selection

    /// The biggest horizontal plane — the base surface (table/floor) the car
    /// sits on. Small planes on top of the obstacle won't win, so the obstacle
    /// stays ABOVE the y=0 reference used for elevation.
    private func largestPlane(
        _ planes: [ARPlaneAnchor]
    ) -> ARPlaneAnchor? {

        planes.max(
            by: {
                planeArea($0) <
                    planeArea($1)
            }
        )
    }

    private func planeArea(
        _ plane: ARPlaneAnchor
    ) -> Float {

        plane.planeExtent.width *
        plane.planeExtent.height
    }


    // MARK: Re-lock

    /// Until a target is committed, keep the surface pinned to the LARGEST
    /// plane. Fixes the camera-order problem where a small plane on the
    /// obstacle is detected first and wrongly becomes the y=0 surface.
    private func relockIfLargerPlaneAppeared(
        _ component:
            inout SurfaceScanComponent,

        scene:
            RealityKit.Scene
    ) {

        guard
            let best =
                largestPlane(
                    component.detectedPlanes
                ),

            best.identifier !=
                component.lockedPlaneID
        else {
            return
        }


        let currentArea =
            component.detectedPlanes
                .first(
                    where: {
                        $0.identifier ==
                            component.lockedPlaneID
                    }
                )
                .map(planeArea) ?? 0


        // Only switch for a meaningfully bigger plane (avoids flip-flopping).
        guard
            planeArea(best) >
                currentArea * 1.2
        else {
            return
        }


        component.surfaceAnchor?
            .removeFromParent()


        let anchor =
            AnchorEntity(
                anchor:
                    best
            )

        scene.addAnchor(
            anchor
        )

        PhysicsFloor.attach(
            to:
                anchor,

            for:
                best
        )


        component.surfaceAnchor =
            anchor

        component.lockedPlaneID =
            best.identifier

        component.lockedExtent =
            extent(
                of:
                    best
            )
    }
}
