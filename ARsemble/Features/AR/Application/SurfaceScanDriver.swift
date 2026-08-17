//
//  SurfaceScanDriver.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 12/08/26.
//

// MARK: - Driver (ARSession + delegate + SwiftUI state)

/// Owns the ARSession and feeds plane data into the ECS world. Also publishes
/// display state so the (upcoming) RealityView can bind to it. Makes NO
///
import RealityKit
import ARKit
import Foundation
final class SurfaceScanDriver:
    NSObject,
    ObservableObject,
    ARSessionDelegate {


    // ========================================================
    // MARK: Published state
    // ========================================================

    @Published var statusText =
        "Move device slowly to scan a floor or table…"

    @Published var hasLockedSurface =
        false

    @Published var targetLocked =
        false

    @Published var obstacleDetected =
        false

    @Published var finishPlaced =
        false

    @Published var didSucceed =
        false
    


    // ========================================================
    // MARK: ECS root
    // ========================================================

    let scanRoot =
        Entity()


    private weak var arView:
        ARView?


    // ========================================================
    // MARK: Init
    // ========================================================

    override init() {

        super.init()


        SurfaceScanComponent
            .registerComponent()

        ObstacleComponent
            .registerComponent()

        CarComponent
            .registerComponent()


        SurfaceLockSystem
            .registerSystem()

        TargetSelectionSystem
            .registerSystem()

        ObstacleDetectionSystem
            .registerSystem()

        CarDriveSystem
            .registerSystem()


        var component =
            SurfaceScanComponent()

        component.presenter =
            self

        scanRoot.components.set(
            component
        )
    }


    // ========================================================
    // MARK: AR configuration
    // ========================================================

    func makeARConfiguration()
        -> ARWorldTrackingConfiguration {

        let config =
            ARWorldTrackingConfiguration()


        config.planeDetection =
            [.horizontal]


        if ARWorldTrackingConfiguration
            .supportsSceneReconstruction(
                .mesh
            ) {

            config.sceneReconstruction =
                .mesh
        }


        config.environmentTexturing =
            .automatic


        return config
    }


    // ========================================================
    // MARK: Attach
    // ========================================================

    func attach(
        to arView: ARView
    ) {

        self.arView =
            arView


        arView.session.delegate =
            self

        arView.session.delegateQueue =
            .main

        arView.automaticallyConfigureSession =
            false


        arView.debugOptions.insert(
            .showSceneUnderstanding
        )


        let root =
            AnchorEntity(
                world: .zero
            )

        root.addChild(
            scanRoot
        )

        arView.scene.addAnchor(
            root
        )


        arView.session.run(
            makeARConfiguration(),
            options: [
                .resetTracking,
                .removeExistingAnchors
            ]
        )
    }


    // ========================================================
    // MARK: Target selection
    // ========================================================

    func selectTarget(
        at screenPoint: CGPoint
    ) {

        guard let arView else {
            return
        }

        guard
            let component =
                scanRoot.components[
                    SurfaceScanComponent.self
                ]
        else {
            return
        }

        guard component.lockedPlaneID != nil else {
            statusText =
                "Lock a surface first."
            return
        }

        guard !component.targetLocked else {
            return
        }

        // First try RealityKit's existing geometry.
        if let result =
            arView.raycast(
                from:
                    screenPoint,

                allowing:
                    .existingPlaneGeometry,

                alignment:
                    .horizontal
            ).first {

            let point =
                SIMD3<Float>(
                    result.worldTransform.columns.3.x,
                    result.worldTransform.columns.3.y,
                    result.worldTransform.columns.3.z
                )

            mutate { component in
                component.requestedTargetPoint =
                    point
            }

            return
        }

        // If ARKit cannot raycast the horizontal plane,
        // fall back to the LiDAR mesh.
        guard
            let ray =
                arView.ray(
                    through:
                        screenPoint
                )
        else {
            statusText =
                "Could not create camera ray."
            return
        }

        guard
            let point =
                nearestMeshPoint(
                    origin:
                        ray.origin,

                    direction:
                        ray.direction
                )
        else {

            statusText =
                "No scanned surface there. Move closer and scan again."

            return
        }

        mutate { component in
            component.requestedTargetPoint =
                point
        }
    }
    
    func selectTarget(
        at worldPoint: SIMD3<Float>
    ) {

        guard !targetLocked else {
            return
        }

        mutate { component in

            component.requestedTargetPoint =
                worldPoint
        }
    }


    private func nearestMeshPoint(
        origin:
            SIMD3<Float>,
        direction:
            SIMD3<Float>
    ) -> SIMD3<Float>? {

        guard
            let component =
                scanRoot.components[
                    SurfaceScanComponent.self
                ]
        else {
            return nil
        }

        let normalized =
            simd_normalize(
                direction
            )

        var bestPoint:
            SIMD3<Float>?

        var bestDistance =
            Float.greatestFiniteMagnitude


        for mesh in component.meshAnchors.values {

            guard
                let data =
                    MeshReader.read(mesh)
            else {
                continue
            }


            let toPoint =
                data.worldCentroid -
                origin

            let projection =
                simd_dot(
                    toPoint,
                    normalized
                )


            guard projection > 0 else {
                continue
            }


            let closest =
                origin +
                normalized *
                projection


            let distance =
                simd_distance(
                    closest,
                    data.worldCentroid
                )


            if distance < bestDistance {

                bestDistance =
                    distance

                bestPoint =
                    data.worldCentroid
            }
        }

        return bestPoint
    }


    // ========================================================
    // MARK: Car
    // ========================================================

    func spawnCar(
        at point: SIMD3<Float>
    ) {

        mutate {

            $0.spawnCarRequested =
                true

            $0.carSpawnPoint =
                point
        }
    }


    // ========================================================
    // MARK: Reset
    // ========================================================

    func restartScan() {

        // --------------------------------------------------
        // Reset SwiftUI state FIRST.
        // --------------------------------------------------

        targetLocked = false
        obstacleDetected = false
        finishPlaced = false
        didSucceed = false

        statusText =
            "Move device slowly to scan a floor or table…"


        // --------------------------------------------------
        // Reset ECS state.
        // --------------------------------------------------

        mutate { component in

            component.resetRequested =
                true

            component.requestedTargetPoint =
                nil

            component.targetCenter =
                nil

            component.targetLocked =
                false

            component.finishTarget =
                nil

            component.successHeight =
                nil

            component.finishFrozen =
                false

            component.settleElapsed =
                0

            component.spawnCarRequested =
                false

            component.carSpawnPoint =
                nil
        }


        // --------------------------------------------------
        // Reset ARKit tracking + scene reconstruction.
        // --------------------------------------------------

        arView?.session.run(
            makeARConfiguration(),

            options: [
                .resetTracking,
                .removeExistingAnchors,
                .resetSceneReconstruction
            ]
        )
    }


    // ========================================================
    // MARK: Reports
    // ========================================================

    func reportTargetLocked() {

        guard !targetLocked else {
            return
        }

        targetLocked =
            true

        statusText =
            "Target selected. Move around it to scan the obstacle."
    }


    func reportObstacleDetected() {

        obstacleDetected =
            true

        if !didSucceed {

            statusText =
                "Obstacle detected. Finish point locked."
        }
    }


    func reportFinishPlaced() {

        finishPlaced =
            true
    }


    func reportSuccess() {

        guard !didSucceed else {
            return
        }

        didSucceed =
            true

        statusText =
            "Success! The car reached the finish."
    }


    func warn(
        _ message: String
    ) {

        guard !didSucceed else {
            return
        }

        statusText =
            message
    }


    // ========================================================
    // MARK: ARSessionDelegate
    // ========================================================

    func session(
        _ session: ARSession,
        didAdd anchors: [ARAnchor]
    ) {

        ingest(
            anchors
        )
    }


    func session(
        _ session: ARSession,
        didUpdate anchors: [ARAnchor]
    ) {

        ingest(
            anchors
        )
    }


    func session(
        _ session: ARSession,
        didRemove anchors: [ARAnchor]
    ) {

        drop(
            anchors
        )
    }


    // ========================================================
    // MARK: Deposit ARKit data
    // ========================================================

    private func ingest(
        _ anchors: [ARAnchor]
    ) {

        mutate { component in

            for anchor in anchors {

                switch anchor {

                case let plane as ARPlaneAnchor
                    where plane.alignment == .horizontal:

                    if let index =
                        component.detectedPlanes
                            .firstIndex(
                                where: {
                                    $0.identifier ==
                                    plane.identifier
                                }
                            ) {

                        component.detectedPlanes[index] =
                            plane

                    } else {

                        component.detectedPlanes.append(
                            plane
                        )
                    }


                case let mesh as ARMeshAnchor:

                    component.meshAnchors[
                        mesh.identifier
                    ] = mesh

                    component.dirtyMeshIDs.insert(
                        mesh.identifier
                    )


                default:
                    break
                }
            }
        }
    }


    private func drop(
        _ anchors: [ARAnchor]
    ) {

        let ids =
            anchors.compactMap {
                ($0 as? ARMeshAnchor)?.identifier
            }


        guard !ids.isEmpty else {
            return
        }


        mutate { component in

            for id in ids {

                component.meshAnchors[id] =
                    nil

                component.dirtyMeshIDs.remove(
                    id
                )

                component.removedMeshIDs.insert(
                    id
                )
            }
        }
    }


    // ========================================================
    // MARK: Component mutation
    // ========================================================

    private func mutate(
        _ body:
        (inout SurfaceScanComponent) -> Void
    ) {

        guard var component =
            scanRoot.components[
                SurfaceScanComponent.self
            ]
        else {
            return
        }


        body(
            &component
        )


        scanRoot.components.set(
            component
        )
    }
}
