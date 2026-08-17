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

                follow(
                    &component
                )

                serviceSpawnRequest(
                    &component
                )
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
                component.detectedPlanes.first
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
            "Surface locked. Tap the TOP of the obstacle."
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


    // MARK: Spawn

    private func serviceSpawnRequest(
        _ component:
            inout SurfaceScanComponent
    ) {

        guard
            component.spawnCarRequested,

            let anchor =
                component.surfaceAnchor
        else {
            return
        }


        anchor.children
            .filter {
                $0.name ==
                    "VirtualCar"
            }
            .forEach {
                $0.removeFromParent()
            }


        let car =
            EntityFactory.createCar(
                length:
                    0.12,

                width:
                    0.07,

                height:
                    0.04,

                color:
                    .red
            )


        car.name =
            "VirtualCar"


        // Wire the car's goal to the finish point placed during scanning.
        // Without this, CarDriveSystem has no target and the car never moves.
        var carComponent =
            CarComponent()

        carComponent.target =
            component.finishTarget

        car.components.set(
            carComponent
        )


        anchor.addChild(
            car
        )


        let restOffset =
            SIMD3<Float>(
                0,
                0.02,
                0
            )


        if let spawn =
            component.carSpawnPoint {

            car.setPosition(
                spawn +
                    restOffset,

                relativeTo:
                    nil
            )

        } else {

            car.position =
                restOffset
        }


        component.spawnCarRequested =
            false

        component.carSpawnPoint =
            nil

        component.presenter?
            .didSucceed = false

        component.presenter?
            .statusText =
            "Car placed — driving to the finish."
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
}
