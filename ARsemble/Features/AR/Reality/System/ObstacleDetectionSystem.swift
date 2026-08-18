//
//  ObstacleDetectionSystem.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 12/08/26.
//

import Foundation
import ARKit
import RealityKit
import simd
import UIKit


struct ObstacleDetectionSystem: System {

    static let query =
        EntityQuery(
            where:
                .has(SurfaceScanComponent.self)
        )

    // ============================================================
    // MARK: Detection parameters
    // ============================================================

    /// Horizontal radius around the user's selected target.
    ///
    /// 0.35 m = 35 cm.
    ///
    /// This is deliberately local so background walls/furniture
    /// don't become the finish target.
    private let searchRadius: Float = 0.35

    /// Height above the locked surface that counts as actual
    /// elevated geometry. Kept low so a thin incline (a book) qualifies.
    private let minimumHeight: Float = 0.02

    /// Tight radius around the exact tapped point used to estimate the finish
    /// height. Much smaller than searchRadius so a wall/object BEHIND the target
    /// can't drag the finish up.
    private let finishRadius: Float = 0.08

    /// Anything taller than this above the plane is treated as background
    /// (a wall, furniture) and ignored when placing the finish.
    private let maxFinishHeight: Float = 0.40

    /// Once elevated geometry has been found, neighboring mesh
    /// chunks within this distance are considered part of the
    /// same physical obstacle.
    private let clusterRadius: Float = 0.30

    /// Finish marker sits slightly above the real LiDAR vertex.
    private let finishOffset: Float = 0.015

    /// Height fraction used by CarDriveSystem.
    private let successHeightFraction: Float = 0.85

    /// Number of frames for which we allow the selected obstacle
    /// to refine before freezing the finish.
    private let settleDuration: Float = 1.5

    private let obstacleRootName =
        "ObstacleRoot"

    private let finishName =
        "FinishPoint"

    private let shapeCache =
        ObstacleShapeCache()


    init(scene: RealityKit.Scene) {}


    // ============================================================
    // MARK: Update
    // ============================================================

    func update(
        context: SceneUpdateContext
    ) {

        for entity in context.entities(
            matching:
                Self.query,

            updatingSystemWhen:
                .rendering
        ) {

            guard var component =
                entity.components[
                    SurfaceScanComponent.self
                ]
            else {
                continue
            }


            guard
                component.lockedPlaneID != nil,
                let surface =
                    component.surfaceAnchor
            else {
                continue
            }


            let planeY =
                surface.position(
                    relativeTo:
                        nil
                ).y


            let root =
                obstacleRoot(
                    in:
                        context.scene
                )


            // ====================================================
            // 1. Remove deleted mesh chunks
            // ====================================================

            for id in component.removedMeshIDs {

                root
                    .findEntity(
                        named:
                            obstacleName(id)
                    )?
                    .removeFromParent()

                shapeCache.invalidate(id)
            }

            component.removedMeshIDs.removeAll()


            // ====================================================
            // 2. Process changed LiDAR mesh
            // ====================================================

            for id in component.dirtyMeshIDs {

                guard
                    let mesh =
                        component.meshAnchors[id]
                else {
                    continue
                }

                buildOrUpdateObstacle(
                    mesh:
                        mesh,

                    planeY:
                        planeY,

                    root:
                        root
                )
            }

            component.dirtyMeshIDs.removeAll()


            // ====================================================
            // 3. TARGET-DRIVEN DETECTION
            //
            // This is the important part.
            //
            // We do NOT ask:
            //
            // "Does this mesh chunk look like a ramp?"
            //
            // We ask:
            //
            // "Is there elevated geometry around the point
            //  the user explicitly selected?"
            // ====================================================

            if component.targetLocked {

                if component.finishTarget == nil ||
                    !component.finishFrozen {

                    evaluateTarget(
                        component:
                            &component,

                        root:
                            root,

                        target:
                            component.targetCenter,

                        planeY:
                            planeY
                    )
                }
            }


            entity.components.set(
                component
            )
        }
    }


    // ============================================================
    // MARK: Mesh → RealityKit obstacle
    // ============================================================

    private func buildOrUpdateObstacle(
        mesh:
            ARMeshAnchor,

        planeY:
            Float,

        root:
            Entity
    ) {

        guard
            let data =
                MeshReader.read(mesh)
        else {
            return
        }


        let height =
            data.worldMax.y -
            planeY


        // Ignore geometry that is essentially the locked
        // horizontal surface itself.
        guard
            height >=
                minimumHeight
        else {

            root
                .findEntity(
                    named:
                        obstacleName(
                            mesh.identifier
                        )
                )?
                .removeFromParent()

            shapeCache.invalidate(
                mesh.identifier
            )

            return
        }


        let entity =
            (
                root.findEntity(
                    named:
                        obstacleName(
                            mesh.identifier
                        )
                )
                as? ModelEntity
            )
            ??
            EntityFactory.createObstacle(
                mesh.identifier,
                in:
                    root
            )


        // Keep the obstacle in the exact transform
        // reported by ARKit.
        entity.transform =
            Transform(
                matrix:
                    mesh.transform
            )


        // --------------------------------------------------------
        // Collider
        // --------------------------------------------------------

        if let shape =
            shapeCache.shape(
                for:
                    mesh.identifier
            ) {

            entity.collision =
                CollisionComponent(
                    shapes:
                        [shape]
                )


            entity.physicsBody =
                PhysicsBodyComponent(
                    massProperties:
                        .default,

                    material:
                        .generate(
                            friction:
                                0.8,

                            restitution:
                                0.0
                        ),

                    mode:
                        .static
                )
        }


        shapeCache.requestGeneration(
            id:
                mesh.identifier,

            positions:
                data.localPositions,

            faceIndices:
                data.faceIndices
        )


        // --------------------------------------------------------
        // Store geometric information.
        //
        // We still calculate incline information because it can
        // be useful later, but it NO LONGER determines whether
        // this is a valid obstacle.
        // --------------------------------------------------------

        let inclineFraction =
            data.inclinedFaceFraction(
                minDeg:
                    15,

                maxDeg:
                    65
            )


        var obstacle =
            entity.components[
                ObstacleComponent.self
            ]
            ??
            ObstacleComponent(
                meshID:
                    mesh.identifier
            )


        obstacle.aabbMin =
            data.worldMin

        obstacle.aabbMax =
            data.worldMax

        obstacle.centroid =
            data.worldCentroid

        obstacle.highestPoint =
            data.worldHighest

        obstacle.isInclineSurface =
            inclineFraction >=
                0.15


        entity.components.set(
            obstacle
        )
    }


    // ============================================================
    // MARK: Target evaluation
    // ============================================================

    private func evaluateTarget(
        component:
            inout SurfaceScanComponent,

        root:
            Entity,

        target:
            SIMD3<Float>?,

        planeY:
            Float
    ) {

        guard
            let target
        else {
            return
        }


        // --------------------------------------------------------
        // The tapped point IS the exact surface point on the obstacle
        // (from the collider hit-test), so place the finish right there.
        // We only validate it's genuinely elevated above the locked
        // surface and not up on a tall wall/background.
        // --------------------------------------------------------

        let heightAbovePlane = target.y - planeY

        guard
            heightAbovePlane >= minimumHeight,
            heightAbovePlane <= maxFinishHeight
        else {

            component.presenter?.warn(
                "Tap the top of the ramp or box — that spot isn't on the obstacle."
            )

            return
        }

        let robustTop = target


        // --------------------------------------------------------
        // Finish sits just above the robust top surface point.
        // --------------------------------------------------------

        let finish =
            robustTop +
            SIMD3<Float>(
                0,
                finishOffset,
                0
            )


        component.finishTarget =
            finish


        component.successHeight =
            planeY +
            successHeightFraction *
            (
                robustTop.y -
                planeY
            )


        // --------------------------------------------------------
        // Finish marker
        // --------------------------------------------------------

        let marker =
            (
                root.findEntity(
                    named:
                        finishName
                )
                as? ModelEntity
            )
            ??
        EntityFactory.createFinishMarker(
                in: root,
                finishName: finishName
            )


        marker.position =
            finish


        // --------------------------------------------------------
        // UI
        // --------------------------------------------------------

        component.presenter?
            .reportObstacleDetected()

        component.presenter?
            .reportFinishPlaced()


        // --------------------------------------------------------
        // Allow LiDAR to refine the point briefly.
        // --------------------------------------------------------

        component.settleElapsed +=
            Float(
                1.0 / 60.0
            )


        if component.settleElapsed >=
            settleDuration {

            component.finishFrozen =
                true
        }
    }


    // ============================================================
    // MARK: Scene helpers
    // ============================================================

    private func obstacleRoot(
        in scene:
            RealityKit.Scene
    ) -> Entity {

        if let root =
            scene.anchors.first(
                where:
                    {
                        $0.name ==
                            obstacleRootName
                    }
            ) {

            return root
        }


        let anchor =
            AnchorEntity(
                world:
                    .zero
            )


        anchor.name =
            obstacleRootName


        scene.addAnchor(
            anchor
        )


        return anchor
    }


    private func obstacleName(
        _ id:
            UUID
    ) -> String {

        "obstacle_\(id.uuidString)"
    }
}

