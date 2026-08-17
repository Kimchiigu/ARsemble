//
//  ARContainer.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 15/08/26.
//


import SwiftUI
import RealityKit
import ARKit

struct ARContainer: UIViewRepresentable {

    @ObservedObject var driver: SurfaceScanDriver

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {

        let arView = ARView(
            frame: .zero
        )

        // Give the driver ownership of the AR session.
        driver.attach(
            to: arView
        )

        // Store references in coordinator.
        context.coordinator.driver = driver
        context.coordinator.arView = arView

        // --------------------------------------------------
        // TAP GESTURE
        // --------------------------------------------------

        let tapGesture =
            UITapGestureRecognizer(
                target:
                    context.coordinator,

                action:
                    #selector(
                        Coordinator.handleTap(_:)
                    )
            )

        arView.addGestureRecognizer(
            tapGesture
        )

        return arView
    }

    func updateUIView(
        _ uiView: ARView,
        context: Context
    ) {
        // Nothing needs to be updated here.
        //
        // ARKit + RealityKit are driven by SurfaceScanDriver.
    }


    // ======================================================
    // MARK: Coordinator
    // ======================================================

    final class Coordinator: NSObject {

        weak var arView: ARView?

        weak var driver: SurfaceScanDriver?


        // ==================================================
        // MARK: Tap
        // ==================================================

        @objc
        func handleTap(
            _ gesture: UITapGestureRecognizer
        ) {

            guard
                let arView = arView,
                let driver = driver
            else {
                return
            }

            // IMPORTANT:
            //
            // This is a SCREEN coordinate.
            //
            // CGPoint is NOT a world-space position.
            let screenPoint =
                gesture.location(
                    in: arView
                )


            // ==================================================
            // STATE 1
            //
            // No target selected yet.
            //
            // First tap selects the obstacle.
            // ==================================================

            if !driver.targetLocked {

                selectTarget(
                    screenPoint:
                        screenPoint,

                    arView:
                        arView,

                    driver:
                        driver
                )

                return
            }


            // ==================================================
            // STATE 2
            //
            // Target already selected.
            //
            // Second tap drops the car.
            // ==================================================

            spawnCar(
                screenPoint:
                    screenPoint,

                arView:
                    arView,

                driver:
                    driver
            )
        }


        // ==================================================
        // MARK: Target Selection
        // ==================================================

        private func selectTarget(
            screenPoint:
                CGPoint,

            arView:
                ARView,

            driver:
                SurfaceScanDriver
        ) {

            // --------------------------------------------------
            // Try an existing horizontal plane first.
            // --------------------------------------------------

            if let result =
                arView.raycast(
                    from:
                        screenPoint,

                    allowing:
                        .existingPlaneGeometry,

                    alignment:
                        .horizontal
                ).first {

                let worldPoint =
                    worldPosition(
                        from:
                            result
                    )

                driver.selectTarget(
                    at:
                        worldPoint
                )

                return
            }


            // --------------------------------------------------
            // If there is no plane hit, try estimated geometry.
            // --------------------------------------------------

            if let result =
                arView.raycast(
                    from:
                        screenPoint,

                    allowing:
                        .estimatedPlane,

                    alignment:
                        .horizontal
                ).first {

                let worldPoint =
                    worldPosition(
                        from:
                            result
                    )

                driver.selectTarget(
                    at:
                        worldPoint
                )

                return
            }


            // --------------------------------------------------
            // No horizontal plane hit.
            //
            // Let the driver try the LiDAR mesh fallback.
            // --------------------------------------------------

            driver.selectTarget(
                at:
                    screenPoint
            )
        }


        // ==================================================
        // MARK: Car Spawn
        // ==================================================

        private func spawnCar(
            screenPoint:
                CGPoint,

            arView:
                ARView,

            driver:
                SurfaceScanDriver
        ) {

            // Car should be placed on the scanned surface.
            //
            // We therefore try existing horizontal geometry first.

            if let result =
                arView.raycast(
                    from:
                        screenPoint,

                    allowing:
                        .existingPlaneGeometry,

                    alignment:
                        .horizontal
                ).first {

                let worldPoint =
                    worldPosition(
                        from:
                            result
                    )

                driver.spawnCar(
                    at:
                        worldPoint
                )

                return
            }


            // Fallback to estimated horizontal plane.

            if let result =
                arView.raycast(
                    from:
                        screenPoint,

                    allowing:
                        .estimatedPlane,

                    alignment:
                        .horizontal
                ).first {

                let worldPoint =
                    worldPosition(
                        from:
                            result
                    )

                driver.spawnCar(
                    at:
                        worldPoint
                )

                return
            }


            driver.warn(
                "Cannot find the surface. Point the camera at the table."
            )
        }


        // ==================================================
        // MARK: Raycast → World Position
        // ==================================================

        private func worldPosition(
            from result:
                ARRaycastResult
        ) -> SIMD3<Float> {

            let transform =
                result.worldTransform

            return SIMD3<Float>(
                transform.columns.3.x,
                transform.columns.3.y,
                transform.columns.3.z
            )
        }
    }
}
