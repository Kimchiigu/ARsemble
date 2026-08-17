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


    // MARK: - Car

    var spawnCarRequested: Bool = false

    var carSpawnPoint: SIMD3<Float>?

    var resetRequested: Bool = false


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
