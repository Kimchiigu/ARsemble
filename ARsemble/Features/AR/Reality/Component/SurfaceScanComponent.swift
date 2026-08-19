//
//  TableComponent.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 12/08/26.
//
import SwiftUI
import RealityKit
import ARKit


import Foundation
import ARKit
import RealityKit
import simd

struct SurfaceScanComponent: Component {

    // MARK: - Surface

    var detectedPlanes: [ARPlaneAnchor] = []

    var lockedPlaneID: UUID?

    var surfaceAnchor: AnchorEntity?

    var lockedExtent: SIMD2<Float>?

    /// World point the player TAPPED to lock the play surface. The lock system
    /// anchors the y-zero base here (tap-to-lock, instead of auto-picking the
    /// largest detected plane).
    var lockSurfaceRequest: SIMD3<Float>?

    /// The REAL detected plane the tap landed on (if any). Locking to it lets us
    /// know the table's true boundary, so the car falls off at the edge instead
    /// of floating over an infinite estimated plane.
    var lockSurfacePlaneID: UUID?


    // MARK: - Car

    /// The car to spawn, as built in the editor. Nil falls back to the
    /// placeholder spec.
    var carSpec: CarSpecComponent?

    var spawnCarRequested: Bool = false

    var carSpawnPoint: SIMD3<Float>?

    var resetRequested: Bool = false


    // MARK: - Car placement (drag to fit, before obstacle selection)

    /// World point the user is currently dragging the car to.
    var carDragPoint: SIMD3<Float>?

    /// Yaw (radians) the user has rotated the car to during placement.
    var carPlacementYaw: Float = 0

    /// True once the player confirms the car fits the surface.
    var carPlacementConfirmed: Bool = false

    /// Where the car was placed — used to reset it for "Retry Drive".
    var carInitialPosition: SIMD3<Float>?

    /// Set to put the car back at its start position and re-run the drive.
    var retryDriveRequested: Bool = false

    /// True once the player confirms the finish marker position. The car only
    /// drives after this.
    var finishConfirmed: Bool = false


    // MARK: - Target Selection

    /// World-space point selected by the user.
    var requestedTargetPoint: SIMD3<Float>?

    /// Center of the region that the obstacle detector should inspect.
    var targetCenter: SIMD3<Float>?

    /// True after TargetSelectionSystem accepts the user's tap.
    var targetLocked: Bool = false


    // MARK: - LiDAR Mesh

    var meshAnchors: [UUID: ARMeshAnchor] = [:]

    var dirtyMeshIDs: Set<UUID> = []

    var removedMeshIDs: Set<UUID> = []


    // MARK: - Finish

    var finishTarget: SIMD3<Float>?

    var successHeight: Float?

    var finishFrozen: Bool = false

    var settleElapsed: Float = 0


    // MARK: - UI

    weak var presenter: SurfaceScanDriver?
}
