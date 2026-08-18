//
//  ObstacleShapeCache.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 13/08/26.
//
import SwiftUI
import RealityKit

final class ObstacleShapeCache {

    private let lock = NSLock()
    private var shapes: [UUID: ShapeResource] = [:]
    private var inFlight: Set<UUID> = []

    func shape(for id: UUID) -> ShapeResource? {
        lock.lock(); defer { lock.unlock() }
        return shapes[id]
    }

    func requestGeneration(id: UUID, positions: [SIMD3<Float>], faceIndices: [UInt16]) {
        lock.lock()
        if inFlight.contains(id) { lock.unlock(); return }
        inFlight.insert(id)
        lock.unlock()

        Task.detached(priority: .utility) { [weak self] in
            let shape = try? await ShapeResource.generateStaticMesh(
                positions: positions, faceIndices: faceIndices)
            guard let self else { return }
            self.lock.lock()
            if let shape { self.shapes[id] = shape }
            self.inFlight.remove(id)
            self.lock.unlock()
        }
    }

    func invalidate(_ id: UUID) {
        lock.lock()
        shapes[id] = nil
        inFlight.remove(id)
        lock.unlock()
    }
}




