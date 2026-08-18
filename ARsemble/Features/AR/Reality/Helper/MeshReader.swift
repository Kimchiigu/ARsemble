//
//  MeshReader.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 12/08/26.
//

import Foundation
import ARKit
import RealityKit
import simd

struct MeshReader {

    // MARK: - Mesh data

    /// Original vertices in the ARMeshAnchor's local coordinate space.
    let localPositions: [SIMD3<Float>]

    /// Same vertices transformed into world space.
    ///
    /// This is important for the new target-based obstacle detector:
    /// it can search the REAL LiDAR vertices around the user's tap
    /// instead of relying only on a mesh chunk's bounding box.
    let worldPositions: [SIMD3<Float>]

    /// Triangle indices.
    let faceIndices: [UInt16]

    /// World-space axis-aligned bounding box.
    let worldMin: SIMD3<Float>
    let worldMax: SIMD3<Float>

    /// Average position of all vertices in world space.
    let worldCentroid: SIMD3<Float>

    /// Highest real vertex in world space.
    let worldHighest: SIMD3<Float>

    /// Rotation portion of the mesh transform.
    let worldRotation: simd_float3x3


    // MARK: - Read ARMeshAnchor

    static func read(
        _ mesh: ARMeshAnchor
    ) -> MeshReader? {

        let geometry =
            mesh.geometry

        let vSource =
            geometry.vertices

        guard vSource.count > 0 else {
            return nil
        }


        // ========================================================
        // MARK: Local vertices
        // ========================================================

        var positions =
            [SIMD3<Float>]()

        positions.reserveCapacity(
            vSource.count
        )

        let vBase =
            vSource.buffer.contents()


        for i in 0..<vSource.count {

            let p =
                vBase
                    .advanced(
                        by:
                            vSource.offset +
                            vSource.stride * i
                    )
                    .assumingMemoryBound(
                        to:
                            Float.self
                    )

            positions.append(
                SIMD3<Float>(
                    p[0],
                    p[1],
                    p[2]
                )
            )
        }


        // ========================================================
        // MARK: Face indices
        // ========================================================

        let fSource =
            geometry.faces

        let perPrimitive =
            fSource.indexCountPerPrimitive

        let bytesPerIndex =
            fSource.bytesPerIndex

        let indexCount =
            fSource.count *
            perPrimitive


        var indices =
            [UInt16]()

        indices.reserveCapacity(
            indexCount
        )


        let fBase =
            fSource.buffer.contents()


        for k in 0..<indexCount {

            let ptr =
                fBase.advanced(
                    by:
                        k * bytesPerIndex
                )


            let value: UInt32

            if bytesPerIndex == 2 {

                value =
                    UInt32(
                        ptr
                            .assumingMemoryBound(
                                to:
                                    UInt16.self
                            )
                            .pointee
                    )

            } else {

                value =
                    ptr
                        .assumingMemoryBound(
                            to:
                                UInt32.self
                        )
                        .pointee
            }


            indices.append(
                UInt16(
                    truncatingIfNeeded:
                        value
                )
            )
        }


        // ========================================================
        // MARK: Transform
        // ========================================================

        let transform =
            mesh.transform


        // ========================================================
        // MARK: World-space vertices
        // ========================================================

        var worldPositions =
            [SIMD3<Float>]()

        worldPositions.reserveCapacity(
            positions.count
        )


        var worldMin =
            SIMD3<Float>(
                repeating:
                    .greatestFiniteMagnitude
            )

        var worldMax =
            SIMD3<Float>(
                repeating:
                    -.greatestFiniteMagnitude
            )

        var sum =
            SIMD3<Float>(
                repeating:
                    0
            )

        var worldHighest =
            SIMD3<Float>(
                0,
                -.greatestFiniteMagnitude,
                0
            )


        for p in positions {

            // simd_float4x4 * SIMD4<Float>
            //
            // IMPORTANT:
            // Do NOT use a 3x3 matrix here.
            // We need the translation contained in the
            // 4x4 ARMeshAnchor transform.
            let world4 =
                transform *
                SIMD4<Float>(
                    p.x,
                    p.y,
                    p.z,
                    1
                )


            let worldPoint =
                SIMD3<Float>(
                    world4.x,
                    world4.y,
                    world4.z
                )


            // Keep the actual transformed vertex.
            //
            // This is what the new obstacle detector will use
            // to determine the highest REAL point around the
            // user's selected target.
            worldPositions.append(
                worldPoint
            )


            // Update bounds.
            worldMin =
                simd_min(
                    worldMin,
                    worldPoint
                )

            worldMax =
                simd_max(
                    worldMax,
                    worldPoint
                )


            // Update centroid accumulator.
            sum +=
                worldPoint


            // Keep highest REAL vertex.
            if worldPoint.y >
                worldHighest.y {

                worldHighest =
                    worldPoint
            }
        }


        let worldCentroid =
            sum /
            Float(
                positions.count
            )


        // ========================================================
        // MARK: Rotation matrix
        // ========================================================

        let worldRotation =
            simd_float3x3(

                SIMD3<Float>(
                    transform.columns.0.x,
                    transform.columns.0.y,
                    transform.columns.0.z
                ),

                SIMD3<Float>(
                    transform.columns.1.x,
                    transform.columns.1.y,
                    transform.columns.1.z
                ),

                SIMD3<Float>(
                    transform.columns.2.x,
                    transform.columns.2.y,
                    transform.columns.2.z
                )
            )


        // ========================================================
        // MARK: Return
        // ========================================================

        return MeshReader(

            localPositions:
                positions,

            worldPositions:
                worldPositions,

            faceIndices:
                indices,

            worldMin:
                worldMin,

            worldMax:
                worldMax,

            worldCentroid:
                worldCentroid,

            worldHighest:
                worldHighest,

            worldRotation:
                worldRotation
        )
    }


    // MARK: - Incline analysis

    /// Calculates the fraction of triangles whose normals are
    /// tilted between minDeg and maxDeg away from vertical.
    ///
    /// This is still available for descriptive/diagnostic use.
    /// The NEW target-based obstacle detector should NOT depend
    /// on this value to decide whether the user's target is valid.
    func inclinedFaceFraction(
        minDeg:
            Float,

        maxDeg:
            Float
    ) -> Float {

        let up =
            SIMD3<Float>(
                0,
                1,
                0
            )


        let vertexCount =
            localPositions.count


        var inclined =
            0

        var total =
            0

        var f =
            0


        while f + 2 <
                faceIndices.count {

            let i0 =
                Int(
                    faceIndices[f]
                )

            let i1 =
                Int(
                    faceIndices[f + 1]
                )

            let i2 =
                Int(
                    faceIndices[f + 2]
                )

            f += 3


            guard
                i0 < vertexCount,
                i1 < vertexCount,
                i2 < vertexCount
            else {
                continue
            }


            var normal =
                simd_cross(
                    localPositions[i1] -
                        localPositions[i0],

                    localPositions[i2] -
                        localPositions[i0]
                )


            guard
                simd_length(normal) >
                    1e-8
            else {
                continue
            }


            normal =
                simd_normalize(
                    worldRotation *
                    normal
                )


            let cosAngle =
                min(
                    max(
                        abs(
                            simd_dot(
                                normal,
                                up
                            )
                        ),
                        0
                    ),
                    1
                )


            let degrees =
                acos(
                    cosAngle
                ) *
                180 /
                .pi


            total += 1


            if degrees >= minDeg &&
                degrees <= maxDeg {

                inclined += 1
            }
        }


        guard total > 0 else {
            return 0
        }


        return Float(inclined) /
            Float(total)
    }
}
