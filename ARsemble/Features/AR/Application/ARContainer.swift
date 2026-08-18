//
//  ARContainer.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 15/08/26.
//


import SwiftUI
import RealityKit
import ARKit

/// ARView that reports when it is actually READY to host the ARSession: in a
/// window AND laid out with non-zero bounds. Starting the session earlier binds
/// the camera feed to a zero-size Metal layer — the background then stays black
/// (dark screen) even though tracking and 3D content keep working.
final class AttachAwareARView: ARView {

    var onReadyToAttach: (() -> Void)?

    private var hasReportedReady = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        reportIfReady()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        reportIfReady()
    }

    private func reportIfReady() {
        guard !hasReportedReady,
              window != nil,
              bounds.width > 0,
              bounds.height > 0
        else {
            return
        }

        hasReportedReady = true

        onReadyToAttach?()
    }
}

struct ARContainer: UIViewRepresentable {

    @ObservedObject var driver: SurfaceScanDriver

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> AttachAwareARView {

        let arView = AttachAwareARView(
            frame: .zero
        )

        // Store references in coordinator.
        context.coordinator.driver = driver
        context.coordinator.arView = arView

        // Give the driver ownership of the AR session — but only once the
        // view is in a window AND has real bounds (zero-bounds attach leaves
        // the camera background black).
        arView.onReadyToAttach = { [weak coordinator = context.coordinator] in
            coordinator?.attachIfNeeded()
        }

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


        // --------------------------------------------------
        // PAN GESTURE (drag the car during placement)
        // --------------------------------------------------

        let panGesture =
            UIPanGestureRecognizer(
                target:
                    context.coordinator,

                action:
                    #selector(
                        Coordinator.handlePan(_:)
                    )
            )

        // One-finger pan; two fingers are reserved for rotation.
        panGesture.maximumNumberOfTouches = 1

        arView.addGestureRecognizer(
            panGesture
        )


        // --------------------------------------------------
        // ROTATION GESTURE (two-finger rotate the car)
        // --------------------------------------------------

        let rotationGesture =
            UIRotationGestureRecognizer(
                target:
                    context.coordinator,

                action:
                    #selector(
                        Coordinator.handleRotate(_:)
                    )
            )

        arView.addGestureRecognizer(
            rotationGesture
        )

        return arView
    }

    func updateUIView(
        _ uiView: AttachAwareARView,
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

        /// Attach once — didMoveToWindow can fire again if the view is
        /// re-parented, and re-attaching would reset the session.
        private var hasAttached = false

        func attachIfNeeded() {
            guard !hasAttached,
                  let arView,
                  let driver
            else {
                return
            }

            hasAttached = true

            driver.attach(
                to: arView
            )
        }


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


            // PLACEMENT: the first tap places the car on the surface; after
            // that it's positioned by dragging.
            if driver.hasLockedSurface,
               !driver.carPlacementConfirmed {

                if !driver.carSpawnedForPlacement {
                    driver.placeCar(at: screenPoint)
                }

                return
            }

            // TARGET: once the car is placed, taps pick the obstacle top,
            // until the finish is set (then the car drives itself).
            guard !driver.finishPlaced else {
                return
            }

            selectTarget(
                screenPoint:
                    screenPoint,

                arView:
                    arView,

                driver:
                    driver
            )
        }


        // ==================================================
        // MARK: Pan (drag the car onto the surface)
        // ==================================================

        @objc
        func handlePan(
            _ gesture: UIPanGestureRecognizer
        ) {

            guard
                let arView = arView,
                let driver = driver
            else {
                return
            }

            // Only while positioning an already-placed car (tap places first).
            guard
                driver.hasLockedSurface,
                !driver.carPlacementConfirmed,
                driver.carSpawnedForPlacement
            else {
                return
            }

            let screenPoint =
                gesture.location(in: arView)

            switch gesture.state {

            case .began, .changed:
                driver.dragCar(at: screenPoint)

            case .ended, .cancelled, .failed:
                driver.endCarDrag()

            default:
                break
            }
        }


        // ==================================================
        // MARK: Rotate (two-finger rotate the car)
        // ==================================================

        @objc
        func handleRotate(
            _ gesture: UIRotationGestureRecognizer
        ) {

            guard let driver = driver else {
                return
            }

            // Only while positioning an already-placed car.
            guard
                driver.hasLockedSurface,
                !driver.carPlacementConfirmed,
                driver.carSpawnedForPlacement
            else {
                return
            }

            if gesture.state == .changed {

                // Apply the incremental rotation, then reset so the next
                // callback gives us the next delta.
                driver.rotateCar(
                    byRadians: Float(gesture.rotation)
                )

                gesture.rotation = 0
            }
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
            // MOST ACCURATE: hit the actual obstacle surface the user
            // tapped (its mesh collider), so the finish sits exactly on
            // the book/box — not on a flat plane in the air.
            // --------------------------------------------------

            let colliderHits =
                arView.hitTest(
                    screenPoint,
                    query: .all,
                    mask: .all
                )

            // Nearest real surface that isn't the car / marker. This can be an
            // obstacle collider OR the reconstructed LiDAR mesh. The driver
            // validates it's actually elevated (on the obstacle, not the floor).
            if let hit =
                colliderHits.first(where: {
                    $0.entity.name != "VirtualCar" &&
                    $0.entity.name != "FinishPoint"
                }) {

                driver.selectTarget(
                    at: hit.position
                )

                return
            }


            // --------------------------------------------------
            // Fallback: an existing horizontal plane.
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
