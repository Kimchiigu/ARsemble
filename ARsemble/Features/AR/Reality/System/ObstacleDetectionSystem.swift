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
    /// elevated geometry.
    private let minimumHeight: Float = 0.035

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
        // Find all obstacle chunks near the user's target.
        // --------------------------------------------------------

        var nearbyObstacles:
            [(ObstacleComponent, MeshReader)] =
                []


        for child in root.children {

            guard
                let obstacle =
                    child.components[
                        ObstacleComponent.self
                    ]
            else {
                continue
            }


            let distance =
                horizontalDistance(
                    obstacle.centroid,
                    target
                )


            guard
                distance <=
                    searchRadius
            else {
                continue
            }


            guard
                obstacle.aabbMax.y >
                    planeY +
                    minimumHeight
            else {
                continue
            }


            guard
                let mesh =
                    component.meshAnchors[
                        obstacle.meshID
                    ],
                let data =
                    MeshReader.read(mesh)
            else {
                continue
            }


            nearbyObstacles.append(
                (
                    obstacle,
                    data
                )
            )
        }


        // --------------------------------------------------------
        // Nothing elevated near the target.
        // --------------------------------------------------------

        guard
            !nearbyObstacles.isEmpty
        else {

            component.presenter?.warn(
                "No elevated object detected there. Tap the obstacle and scan around it."
            )

            return
        }


        // --------------------------------------------------------
        // Find the local highest point.
        //
        // We intentionally use REAL vertices rather than the
        // AABB maximum.
        // --------------------------------------------------------

        var candidates: [SIMD3<Float>] = []

        for (_, data) in nearbyObstacles {
            for vertex in data.worldPositions {

                let dx = vertex.x - target.x
                let dz = vertex.z - target.z

                guard sqrt(dx * dx + dz * dz) <= searchRadius else {
                    continue
                }

                guard vertex.y - planeY >= minimumHeight else {
                    continue
                }

                candidates.append(vertex)
            }
        }


        guard !candidates.isEmpty else {

            component.presenter?.warn(
                "The selected area has not been scanned enough yet."
            )

            return
        }


        // Robust top estimate.
        //
        // A single stray LiDAR vertex can spike way above the real
        // surface and throw the finish into the air. So instead of
        // trusting the highest vertex, sort by height, DROP the extreme
        // top (likely noise), then AVERAGE the remaining top band. This
        // gives a stable point centred on the obstacle's top surface.
        candidates.sort { $0.y < $1.y }

        let candidateCount = candidates.count

        // Discard the top 3% as potential outlier spikes.
        let trimmedEnd = max(1, candidateCount - Int(Float(candidateCount) * 0.03))

        // Average the top 15% of what remains.
        let bandSize = max(1, Int(Float(candidateCount) * 0.15))
        let bandStart = max(0, trimmedEnd - bandSize)

        var topSum = SIMD3<Float>(repeating: 0)
        for i in bandStart..<trimmedEnd {
            topSum += candidates[i]
        }

        let robustTop = topSum / Float(trimmedEnd - bandStart)


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
    // MARK: Horizontal distance
    // ============================================================

    private func horizontalDistance(
        _ a:
            SIMD3<Float>,

        _ b:
            SIMD3<Float>
    ) -> Float {

        let dx =
            a.x -
            b.x

        let dz =
            a.z -
            b.z

        return sqrt(
            dx * dx +
            dz * dz
        )
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

