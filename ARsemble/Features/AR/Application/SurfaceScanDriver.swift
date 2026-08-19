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
import AVFoundation
import Foundation
import QuartzCore
import UIKit
import os
final class SurfaceScanDriver:
    NSObject,
    ObservableObject,
    ARSessionDelegate,
    ARCoachingOverlayViewDelegate {


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

    /// True while the "confirm finish marker" popup is showing.
    @Published var showFinishConfirm =
        false

    /// True once the player confirms the finish marker; the car drives after this.
    @Published var finishConfirmed =
        false

    @Published var didSucceed =
        false

    /// True once the car has toppled over (centre of gravity too high).
    @Published var didTip =
        false

    /// True once the car has driven off the edge of the play surface.
    @Published var didFall =
        false

    /// True while the "confirm car placement" popup is showing.
    @Published var showPlacementConfirm =
        false

    /// True once the car has been dragged onto the surface and confirmed.
    @Published var carPlacementConfirmed =
        false

    /// True after the first tap places the car (then it can be dragged).
    @Published var carSpawnedForPlacement =
        false

    /// After the player lifts the drag, the car enters ROTATE mode: swipe to
    /// spin it, then tap to bring up the confirm popup.
    @Published var placementRotating =
        false

    /// True once AR tracking is ready (coaching overlay finished). Only then do
    /// we prompt the player to tap a surface.
    @Published var readyToLockSurface =
        false



    // ========================================================
    // MARK: ECS root
    // ========================================================

    let scanRoot =
        Entity()


    /// The car built in the editor, spawned by CarSpawnSystem.
    let carSpec:
        CarSpecComponent


    private weak var arView:
        ARView?

    /// Apple's built-in "move device around" coaching overlay. Kept so we can
    /// dismiss it for good once the surface is locked.
    private weak var coachingOverlay:
        ARCoachingOverlayView?


    /// Rebinding the camera is retried a few times (throttled) because the
    /// NavigationStack push resizes the view several times before it settles.
    private var cameraRefreshCount = 0

    private var lastCameraRefresh = Date.distantPast

    private let maxCameraRefreshes = 8

    private let log = Logger(
        subsystem: "com.arsemble.ar",
        category: "SurfaceScanDriver"
    )


    // ========================================================
    // MARK: Init
    // ========================================================

    init(carSpec: CarSpecComponent = EntityFactory.placeholderCarSpec()) {

        self.carSpec = carSpec

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

        CarSpawnSystem
            .registerSystem()

        CarDriveSystem
            .registerSystem()


        var component =
            SurfaceScanComponent()

        component.presenter =
            self

        component.carSpec =
            carSpec

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

        log.debug(
            "attach — bounds \(Double(arView.bounds.width), privacy: .public)x\(Double(arView.bounds.height), privacy: .public), camera auth \(AVCaptureDevice.authorizationStatus(for: .video).rawValue, privacy: .public), world tracking supported \(ARWorldTrackingConfiguration.isSupported, privacy: .public)"
        )


        arView.session.delegate =
            self

        arView.session.delegateQueue =
            .main

        arView.automaticallyConfigureSession =
            false


        // Re-assert the AR camera as the scene background. The ARView is created
        // with this already, but re-applying it right before `session.run` (now
        // that the view has real bounds) guards against a black feed if the
        // background was ever left unset while the drawable was sizing.
        arView.cameraMode = .ar
        arView.environment.background = .cameraFeed()


        // Make the reconstructed LiDAR mesh a real collider, so the car can
        // ride/climb ANY real surface (ramps, books, bags) reliably — not just
        // our per-chunk obstacle colliders.
        arView.environment.sceneUnderstanding.options.insert(.collision)

        // Red LiDAR mesh wireframe overlay (required: visualises the scanned
        // reconstruction). The earlier "dark screen" was a drawable-timing bug,
        // now fixed by the deferred attach — so this debug view is safe to keep on.
        arView.debugOptions.insert(.showSceneUnderstanding)


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

        addCoachingOverlay(to: arView)
    }


    /// Adds Apple's built-in coaching overlay — the animated "move device
    /// around" guide. Goal `.tracking` so it disappears once world tracking is
    /// solid (not dependent on flaky plane detection); we then prompt the tap.
    private func addCoachingOverlay(to arView: ARView) {

        let coaching = ARCoachingOverlayView()
        coaching.session = arView.session
        coaching.goal = .tracking
        coaching.activatesAutomatically = true
        coaching.delegate = self
        coaching.translatesAutoresizingMaskIntoConstraints = false

        arView.addSubview(coaching)

        NSLayoutConstraint.activate([
            coaching.topAnchor.constraint(equalTo: arView.topAnchor),
            coaching.bottomAnchor.constraint(equalTo: arView.bottomAnchor),
            coaching.leadingAnchor.constraint(equalTo: arView.leadingAnchor),
            coaching.trailingAnchor.constraint(equalTo: arView.trailingAnchor)
        ])

        self.coachingOverlay = coaching
    }


    // ========================================================
    // MARK: ARCoachingOverlayViewDelegate
    // ========================================================

    func coachingOverlayViewDidDeactivate(
        _ coachingOverlayView: ARCoachingOverlayView
    ) {
        // Tracking is ready — let the player tap to lock their play surface.
        guard !hasLockedSurface else { return }

        readyToLockSurface = true

        statusText =
            "Tap the table or floor where Arlo will play!"
    }


    /// Re-binds the camera feed AFTER the view is fully on screen.
    ///
    /// When this screen is pushed onto a NavigationStack, `attach()` starts the
    /// session while the destination is still animating in — the camera texture
    /// binds to a transitioning/clipped layer and the feed never starts
    /// compositing (black background, though tracking works). Calling this once
    /// from `.onAppear` (after the push transition settles) re-asserts the
    /// camera background and re-runs the session so RealityKit rebinds it to the
    /// now-stable drawable. It's a no-op when launched directly (already fine).
    func refreshCameraFeed() {

        guard
            let arView,
            cameraRefreshCount < maxCameraRefreshes,
            Date().timeIntervalSince(lastCameraRefresh) > 0.35,
            arView.bounds.width > 0,
            arView.bounds.height > 0
        else {
            return
        }

        cameraRefreshCount += 1
        lastCameraRefresh = Date()

        arView.cameraMode = .ar
        arView.environment.background = .cameraFeed()

        // Deliberately NO `session.run` here any more. Restarting a healthy
        // session mid-render disturbs the passthrough pass and the console
        // shows "Attempting to enable an already-enabled session" for every
        // extra call. Restarts now happen only from the error / interruption
        // handlers, where they are actually warranted.

        log.debug(
            """
            refreshCameraFeed #\(self.cameraRefreshCount, privacy: .public) \
            bounds \(Double(arView.bounds.width), privacy: .public)x\(Double(arView.bounds.height), privacy: .public) \
            layer \(String(describing: type(of: arView.layer)), privacy: .public) \
            sublayers \(arView.layer.sublayers?.count ?? 0, privacy: .public) \
            inWindow \(arView.window != nil, privacy: .public) \
            anchors \(arView.scene.anchors.count, privacy: .public) \
            hasFrame \(arView.session.currentFrame != nil, privacy: .public)
            """
        )
    }


    // ========================================================
    // MARK: Teardown
    // ========================================================

    /// Stop the session and let go of the view. Called when the AR screen goes
    /// away, so an ARSession never outlives the screen that owns it (and never
    /// runs next to the editor's RealityView).
    func teardown() {

        guard let arView else {
            return
        }

        arView.session.pause()
        arView.session.delegate = nil

        self.arView = nil

        log.debug("teardown — ARSession paused and detached.")
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

        guard !finishPlaced else {
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

            requestNewTarget(
                point
            )

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

        requestNewTarget(
            point
        )
    }
    
    func selectTarget(
        at worldPoint: SIMD3<Float>
    ) {

        // Allow re-picking a new target until the finish is actually placed.
        guard !finishPlaced else {
            return
        }

        requestNewTarget(
            worldPoint
        )
    }


    /// Clears the previous target/finish state and requests a fresh target at
    /// the given world point. Lets the user tap a different spot when the first
    /// pick had no elevation, without needing a full rescan.
    private func requestNewTarget(
        _ point: SIMD3<Float>
    ) {

        targetLocked =
            false

        obstacleDetected =
            false

        mutate { component in

            component.requestedTargetPoint =
                point

            component.targetLocked =
                false

            component.targetCenter =
                nil

            component.finishTarget =
                nil

            component.successHeight =
                nil

            component.finishFrozen =
                false

            component.settleElapsed =
                0
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
    // MARK: Surface lock (tap)
    // ========================================================

    /// TAP-TO-LOCK: the player taps a surface and THAT becomes the play surface
    /// (the y-zero base). Raycasts the tapped screen point to a world point and
    /// hands it to SurfaceLockSystem to anchor.
    func lockSurface(
        at screenPoint: CGPoint
    ) {

        guard
            !hasLockedSurface,
            readyToLockSurface,
            let arView
        else {
            return
        }

        // Prefer a REAL detected plane: locking to it gives us the table's true
        // edges, so the car falls off at the boundary instead of floating over
        // an infinite estimated plane. Fall back to an estimated-plane point
        // only if nothing real is there yet.
        var worldPoint: SIMD3<Float>?
        var planeID: UUID?

        if let hit =
            arView.raycast(
                from: screenPoint,
                allowing: .existingPlaneGeometry,
                alignment: .horizontal
            ).first {

            worldPoint = SIMD3<Float>(
                hit.worldTransform.columns.3.x,
                hit.worldTransform.columns.3.y,
                hit.worldTransform.columns.3.z
            )
            planeID = (hit.anchor as? ARPlaneAnchor)?.identifier
        } else {
            worldPoint = surfacePoint(at: screenPoint)
            planeID = nil
        }

        guard let point = worldPoint else {
            statusText =
                "Hmm, keep moving your device so it can see the surface."
            return
        }

        // Stop the coaching overlay from coming back once we've committed.
        coachingOverlay?.activatesAutomatically = false
        coachingOverlay?.setActive(false, animated: true)

        mutate {
            $0.lockSurfaceRequest = point
            $0.lockSurfacePlaneID = planeID
        }
    }


    /// World-space Y of the locked play surface (the tapped base). Used to keep
    /// the car ON the base and reject placing it up on the obstacle.
    private func lockedSurfaceY() -> Float? {
        scanRoot.components[SurfaceScanComponent.self]?
            .surfaceAnchor?
            .position(relativeTo: nil).y
    }


    /// Is the given world point still OVER the locked play surface (the tapped
    /// table)? Tests the point against the real detected plane's boundary
    /// polygon. Returns true when we can't tell (no real plane locked), so the
    /// car never falls spuriously in the estimated-plane fallback case.
    func isWithinPlayableSurface(
        _ worldPoint: SIMD3<Float>
    ) -> Bool {

        guard
            let component =
                scanRoot.components[SurfaceScanComponent.self],
            let planeID = component.lockSurfacePlaneID,
            let plane =
                component.detectedPlanes.first(
                    where: { $0.identifier == planeID }
                )
        else {
            return true
        }

        // World → plane-local (the plane lies in local X-Z, y ≈ up).
        let inv = simd_inverse(plane.transform)
        let local4 = inv * SIMD4<Float>(worldPoint.x, worldPoint.y, worldPoint.z, 1)
        let p = SIMD2<Float>(local4.x, local4.z)

        // Test against the detected boundary polygon.
        let boundary = plane.geometry.boundaryVertices
        if boundary.count >= 3 {
            return pointInPolygon(
                p,
                polygon: boundary.map { SIMD2<Float>($0.x, $0.z) }
            )
        }

        // No polygon yet — fall back to the plane's extent rectangle.
        let half = SIMD2<Float>(
            plane.planeExtent.width * 0.5,
            plane.planeExtent.height * 0.5
        )
        let c = SIMD2<Float>(plane.center.x, plane.center.z)
        return abs(p.x - c.x) <= half.x && abs(p.y - c.y) <= half.y
    }


    /// Standard ray-casting point-in-polygon test (2D).
    private func pointInPolygon(
        _ point: SIMD2<Float>,
        polygon: [SIMD2<Float>]
    ) -> Bool {

        var inside = false
        var j = polygon.count - 1

        for i in 0..<polygon.count {
            let a = polygon[i]
            let b = polygon[j]

            if (a.y > point.y) != (b.y > point.y),
               point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x {
                inside.toggle()
            }
            j = i
        }

        return inside
    }


    // ========================================================
    // MARK: Car placement (drag to fit)
    // ========================================================

    /// FIRST tap on the surface places the car. After this, dragging repositions
    /// it. Shows the "drag to position" hint.
    func placeCar(
        at screenPoint: CGPoint
    ) {

        guard
            let component =
                scanRoot.components[
                    SurfaceScanComponent.self
                ],
            component.lockedPlaneID != nil,
            !carPlacementConfirmed,
            !carSpawnedForPlacement
        else {
            return
        }

        guard
            let raw = surfacePoint(at: screenPoint),
            let point = placementPoint(from: raw)
        else {
            return
        }

        mutate { $0.carDragPoint = point }

        carSpawnedForPlacement = true
        placementRotating = false

        statusText =
            "Drag Arlo to the perfect spot, then let go."
    }

    /// Rotate the placed car — driven by a swipe AFTER the drag is released.
    func rotateCar(
        byRadians delta: Float
    ) {

        guard
            carSpawnedForPlacement,
            !carPlacementConfirmed
        else {
            return
        }

        mutate { component in
            component.carPlacementYaw += delta
        }
    }

    /// Reposition the already-placed car while dragging.
    func dragCar(
        at screenPoint: CGPoint
    ) {

        guard
            carSpawnedForPlacement,
            !carPlacementConfirmed
        else {
            return
        }

        guard
            let raw = surfacePoint(at: screenPoint),
            let point = placementPoint(from: raw)
        else {
            return
        }

        mutate { $0.carDragPoint = point }
    }

    /// Validates a raw surface raycast for car placement: rejects points that
    /// sit up ON the obstacle (elevated above the locked base) so the car can't
    /// be placed on the ramp, and clamps valid points down onto the base plane
    /// so the car always rests flat on the play surface.
    private func placementPoint(
        from raw: SIMD3<Float>
    ) -> SIMD3<Float>? {

        guard let baseY = lockedSurfaceY() else {
            return raw
        }

        // More than ~4 cm above the base → that's the obstacle, not the floor.
        if raw.y > baseY + 0.04 {
            statusText =
                "Oops! Put Arlo on the floor, not on the ramp."
            return nil
        }

        return SIMD3<Float>(raw.x, baseY, raw.z)
    }

    /// Raycast a screen point onto the detected (or estimated) horizontal plane.
    private func surfacePoint(
        at screenPoint: CGPoint
    ) -> SIMD3<Float>? {

        guard let arView else {
            return nil
        }

        let hit =
            arView.raycast(
                from: screenPoint,
                allowing: .existingPlaneGeometry,
                alignment: .horizontal
            ).first
            ??
            arView.raycast(
                from: screenPoint,
                allowing: .estimatedPlane,
                alignment: .horizontal
            ).first

        guard let hit else {
            return nil
        }

        return SIMD3<Float>(
            hit.worldTransform.columns.3.x,
            hit.worldTransform.columns.3.y,
            hit.worldTransform.columns.3.z
        )
    }

    /// Finger lifted after a drag. Positioning is free-form (move + rotate as
    /// much as you like) and the player commits with the Ready button, so this
    /// is intentionally a no-op now.
    func endCarDrag() {}

    /// Confirm placement (from the Ready button) and move on to obstacle
    /// selection.
    func confirmPlacement() {

        guard carSpawnedForPlacement else { return }

        showPlacementConfirm = false
        carPlacementConfirmed = true
        placementRotating = false

        mutate { component in
            component.carPlacementConfirmed = true
            // Remember where the car sits, so Retry Drive can bring it back.
            component.carInitialPosition = component.carDragPoint
        }

        statusText =
            "Car placed. Now tap where you want Arlo to go!"
    }

    /// Dismiss the popup and keep adjusting the car (stay in rotate mode).
    func cancelPlacement() {
        showPlacementConfirm = false
    }


    // ========================================================
    // MARK: Terrain height (used by CarDriveSystem)
    // ========================================================

    /// World-space downward raycast onto the real (estimated) surface — the
    /// SAME ARKit mechanism placement uses, which reliably follows an incline.
    /// Returns the surface height AND its normal (for tilt / tipping).
    func surfaceInfo(
        under worldPoint: SIMD3<Float>
    ) -> (height: Float, normal: SIMD3<Float>)? {

        guard let arView else {
            return nil
        }

        let origin =
            SIMD3<Float>(
                worldPoint.x,
                worldPoint.y + 0.5,
                worldPoint.z
            )

        let query =
            ARRaycastQuery(
                origin: origin,
                direction: SIMD3<Float>(0, -1, 0),
                allowing: .estimatedPlane,
                alignment: .any
            )

        guard
            let result = arView.session.raycast(query).first
        else {
            return nil
        }

        let t = result.worldTransform

        let height = t.columns.3.y

        // The estimated plane's Y axis is its surface normal.
        let normal =
            simd_normalize(
                SIMD3<Float>(
                    t.columns.1.x,
                    t.columns.1.y,
                    t.columns.1.z
                )
            )

        return (height, normal)
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
        didTip = false
        didFall = false
        showPlacementConfirm = false
        carPlacementConfirmed = false
        carSpawnedForPlacement = false
        placementRotating = false
        readyToLockSurface = false
        showFinishConfirm = false
        finishConfirmed = false

        // Bring the coaching overlay back for the fresh scan.
        coachingOverlay?.activatesAutomatically = true
        coachingOverlay?.setActive(true, animated: true)

        statusText =
            "Move your device around to start."


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

            component.carDragPoint =
                nil

            component.carPlacementYaw =
                0

            component.carPlacementConfirmed =
                false

            component.finishConfirmed =
                false

            component.carInitialPosition =
                nil

            component.retryDriveRequested =
                false
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

        // Ask the player to confirm the marker before Arlo drives.
        if !finishConfirmed {
            showFinishConfirm = true
            statusText =
                "Finish flag set. Is this the right spot?"
        }
    }


    /// Confirm the finish marker — Arlo can now drive.
    func confirmFinish() {

        showFinishConfirm = false
        finishConfirmed = true

        mutate { component in
            component.finishConfirmed = true
            // Freeze the marker so it can't drift after being confirmed.
            component.finishFrozen = true
        }

        statusText =
            "Arlo is driving to the finish!"
    }


    /// Reject the finish marker and let the player pick the obstacle top again.
    func retryFinish() {

        showFinishConfirm = false
        finishPlaced = false
        obstacleDetected = false

        mutate { component in
            component.requestedTargetPoint = nil
            component.targetCenter = nil
            component.targetLocked = false
            component.finishTarget = nil
            component.successHeight = nil
            component.finishFrozen = false
            component.settleElapsed = 0
        }

        statusText =
            "Tap the top of the obstacle again."
    }


    /// Put the car back at its start position and drive again — no rescan.
    func retryDrive() {

        didSucceed = false
        didTip = false
        didFall = false

        mutate { component in
            component.retryDriveRequested = true
        }

        statusText =
            "Arlo is driving to the finish!"
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


    /// The car's centre of gravity was too high for the incline and it toppled.
    func reportTipOver() {

        guard !didTip else {
            return
        }

        didTip =
            true

        statusText =
            "The car tipped over! Its centre of gravity is too high — build it lower and wider."
    }


    /// The car drove off the edge of the play surface and fell.
    func reportFellOff() {

        guard !didFall else {
            return
        }

        didFall =
            true

        statusText =
            "Uh oh! Arlo drove off the edge. Tap Retry to try again."
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

    /// Fallback for enabling tap-to-lock: if tracking reaches `.normal` and the
    /// coaching overlay never fired its deactivate (e.g. tracking was already
    /// good), enable the tap prompt here so the player is never stuck.
    func session(
        _ session: ARSession,
        cameraDidChangeTrackingState camera: ARCamera
    ) {

        if case .normal = camera.trackingState,
           !hasLockedSurface,
           !readyToLockSurface {

            readyToLockSurface = true

            statusText =
                "Tap the table or floor where Arlo will play!"
        }
    }


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
    // MARK: Session health
    //
    // Without these, a session that never starts (camera still held by
    // another AVCaptureSession, permission denied, thermal/sensor failure)
    // fails SILENTLY: the SwiftUI overlays keep rendering over a black
    // background and nothing says why.
    // ========================================================

    // NOTE: do NOT implement `session(_:didUpdate frame:)` here. This delegate
    // runs on the main queue, which is already carrying the RealityKit render
    // loop and `ingest()`. Per-frame delivery backs up behind that work, ARKit
    // starts retaining ARFrames ("the delegate is retaining N ARFrames") and
    // then STOPS delivering camera images altogether — a black background with
    // tracking still running. Whether frames are arriving is logged from
    // `refreshCameraFeed()` instead, which costs nothing per frame.

    func session(
        _ session: ARSession,
        didFailWithError error: Error
    ) {

        log.error(
            "ARSession failed: \(error.localizedDescription, privacy: .public)"
        )

        statusText =
            "AR could not start: \(error.localizedDescription)"

        // A camera the app cannot get yet (another capture session is still
        // tearing down) resolves on its own within a moment — retry once.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in

            guard
                let self,
                let arView = self.arView
            else {
                return
            }

            arView.cameraMode = .ar
            arView.environment.background = .cameraFeed()

            arView.session.run(
                self.makeARConfiguration(),
                options: [
                    .resetTracking,
                    .removeExistingAnchors
                ]
            )
        }
    }


    func sessionWasInterrupted(
        _ session: ARSession
    ) {

        log.error(
            "ARSession interrupted — the camera was taken by another client or the app resigned active."
        )

        statusText =
            "Camera paused…"
    }


    func sessionInterruptionEnded(
        _ session: ARSession
    ) {

        log.debug("ARSession interruption ended — restarting.")

        guard let arView else {
            return
        }

        arView.cameraMode = .ar
        arView.environment.background = .cameraFeed()

        // Only throw the scan away if there was nothing worth keeping. A plain
        // backgrounding interruption should not cost the player their surface.
        if hasLockedSurface {
            arView.session.run(
                makeARConfiguration()
            )
        } else {
            arView.session.run(
                makeARConfiguration(),
                options: [
                    .resetTracking,
                    .removeExistingAnchors
                ]
            )

            statusText =
                "Move device slowly to scan a floor or table…"
        }
    }


    func sessionShouldAttemptRelocalization(
        _ session: ARSession
    ) -> Bool {
        true
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
