//
//  CarBuilder.swift
//  ARsemble
//

import Foundation
import RealityKit
import SwiftUI
import UIKit

enum CarBuilder {
    static let displayScale: Float = 3.0

    private static let referenceFootprint: Float = 0.36

    /// A loaded USDZ wheel plus the geometry info needed to scale/center it.
    private struct WheelAsset {
        let model: ModelEntity
        let center: SIMD3<Float>
        let maxDim: Float
    }

    /// USDZ wheel cache, one entry per tyre index (0–5). Loaded once on the
    /// main actor, then cloned per wheel so loading never blocks a rebuild.
    private static var wheelAssets: [Int: WheelAsset] = [:]
    private static var wheelAssetsPrepared = false

    struct Config: Equatable {
        let lengthCm: Float
        let widthCm: Float
        let heightCm: Float
        let bodyColor: Color
        let bodyColorId: UUID
        let tyreIndex: Int

        static func == (lhs: Config, rhs: Config) -> Bool {
            lhs.lengthCm == rhs.lengthCm
                && lhs.widthCm == rhs.widthCm
                && lhs.heightCm == rhs.heightCm
                && lhs.bodyColorId == rhs.bodyColorId
                && lhs.tyreIndex == rhs.tyreIndex
        }
    }

    private struct WheelStyle {
        let radiusMultiplier: Float
        let widthMultiplier: Float
        let tyreColor: UIColor
    }

    static func apply(to holder: Entity, config: Config) {
        if let state = holder.components[CarBuildState.self], state.matches(config) {
            return
        }

        for child in Array(holder.children) {
            child.removeFromParent()
        }

        let unit = 0.01 * displayScale           // cm → world units
        let length = config.lengthCm * unit      // X
        let width  = config.widthCm  * unit      // Z
        let height = config.heightCm * unit      // Y

        holder.addChild(makeBody(length: length, width: width, height: height, color: config.bodyColor))
        makeEyes(length: length, width: width, height: height).forEach { holder.addChild($0) }

        let style = wheelStyle(for: config.tyreIndex)
        let baseRadius = referenceFootprint * 0.24
        let radius = max(baseRadius * style.radiusMultiplier, 0.01)
        let axle = max(radius * 0.65 * style.widthMultiplier, 0.01)

        let wheelY = -height / 2 + radius * 0.5
        let wheelX = length / 2 - radius
        let wheelZ = width / 2 + axle / 2

        for (sx, sz) in [(Float(1), Float(1)), (1, -1), (-1, 1), (-1, -1)] {
            // Use the USDZ wheel for the selected tyre when its asset is cached;
            // fall back to a procedural wheel only if it hasn't loaded yet.
            let wheel = usdzWheel(for: config.tyreIndex, radius: radius)
                ?? makeWheel(radius: radius, axle: axle, style: style)
            wheel.position = [sx * wheelX, wheelY, sz * wheelZ]
            holder.addChild(wheel)
        }

        holder.components[CarBuildState.self] = CarBuildState(config)
    }

    /// Loads every USDZ wheel (tyre1…tyre6) once on the main actor, records each
    /// one's raw bounds, and converts its PBR materials to lit ones. Call this
    /// (async) from the RealityView `make` closure before the first `apply`;
    /// it's a no-op after the first call.
    @MainActor static func prepareWheelAssets() async {
        guard !wheelAssetsPrepared else { return }
        wheelAssetsPrepared = true

        for index in 0..<6 {
            let name = "tyre\(index + 1)"
            do {
                let model = try await ModelEntity(named: name)
                // Entity is @MainActor-isolated, so every access below must run
                // on the main actor — hence this whole function is @MainActor.
                model.transform = Transform()                 // ignore authored root transform

                let bounds = model.visualBounds(recursive: true, relativeTo: nil)
                let dim = bounds.max - bounds.min
                let maxDim = max(dim.x, dim.y, dim.z)

                makeLitMaterials(on: model)                   // avoid PBR / env-probe crash

                wheelAssets[index] = WheelAsset(model: model, center: bounds.center, maxDim: maxDim)
                print("CarBuilder: ✓ cached wheel '\(name)' — maxDim \(String(format: "%.3f", maxDim))")
            } catch {
                print("CarBuilder: ✗ failed to load wheel '\(name)': \(error)")
            }
        }
    }

    /// Builds one car wheel from the cached USDZ for the given tyre, sized to
    /// the car's wheel radius and centered/oriented. Returns nil if the asset
    /// isn't loaded yet (caller falls back to a procedural wheel).
    private static func usdzWheel(for index: Int, radius: Float) -> Entity? {
        guard let asset = wheelAssets[index] else { return nil }

        // Clone the raw model and offset it so its geometry is centered at the
        // clone's origin — done on the child so the wrapper can scale/rotate
        // freely without breaking the centering.
        let clone = asset.model.clone(recursive: true)
        clone.position = -asset.center

        let wrapper = Entity()
        wrapper.addChild(clone)

        // Size the wheel so its largest dimension equals the wheel diameter.
        let diameter = max(radius * 2, 0.01)
        let scale = asset.maxDim > 0 ? diameter / asset.maxDim : 1
        wrapper.scale = SIMD3(repeating: scale)

        // Point the axle along Z so wheels sit on the sides of the car. If your
        // USDZ wheels come in oriented differently, this is the line to change.
        wrapper.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        return wrapper
    }

    /// Recursively replaces every PBR material with a lit `SimpleMaterial` (one
    /// per submesh) so the USDZ never runs the PBR/env-probe shader, which
    /// aborts without an image-based-lighting environment.
    @MainActor private static func makeLitMaterials(on entity: Entity) {
        if let modelEntity = entity as? ModelEntity, var component = modelEntity.model {
            component.materials = component.materials.map { _ in
                SimpleMaterial(color: UIColor(white: 0.18, alpha: 1),
                               roughness: 0.75,
                               isMetallic: false)
            }
            modelEntity.model = component
        }
        for child in entity.children {
            makeLitMaterials(on: child)
        }
    }

    private static func makeBody(length: Float, width: Float, height: Float, color: Color) -> ModelEntity {
        let corner = min(min(length, width, height) * 0.14, 0.06)
        let mesh = MeshResource.generateBox(size: [length, height, width], cornerRadius: corner)
        return ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: UIColor(color), roughness: 0.45, isMetallic: false)])
    }

    private static func makeEyes(length: Float, width: Float, height: Float) -> [ModelEntity] {
        let radius = referenceFootprint * 0.06
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: UIColor(white: 0.98, alpha: 1), roughness: 0.35, isMetallic: false)
        let x = length / 2 + radius * 0.6
        let y = height * 0.12
        let z = width * 0.2
        return [Float(-1), 1].map { sign in
            let eye = ModelEntity(mesh: mesh, materials: [material])
            eye.position = [x, y, z * sign]
            return eye
        }
    }

    private static func makeWheel(radius: Float, axle: Float, style: WheelStyle) -> Entity {
        let group = Entity()

        let tyre = ModelEntity(
            mesh: .generateCylinder(height: axle, radius: radius),
            materials: [SimpleMaterial(color: style.tyreColor, roughness: 0.9, isMetallic: false)]
        )
        group.addChild(tyre)

        let capHeight = max(axle * 0.18, 0.004)
        let capRadius = radius * 0.5
        let capMaterial = SimpleMaterial(color: UIColor(white: 0.92, alpha: 1), roughness: 0.3, isMetallic: true)
        for sign in [Float(1), -1] {
            let cap = ModelEntity(
                mesh: .generateCylinder(height: capHeight, radius: capRadius),
                materials: [capMaterial]
            )
            cap.position = [0, sign * (axle / 2 + capHeight / 2), 0]
            group.addChild(cap)
        }

        group.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        return group
    }

    private static func wheelStyle(for index: Int) -> WheelStyle {
        switch index {
        case 1:  return .init(radiusMultiplier: 1.00, widthMultiplier: 1.00,
                              tyreColor: UIColor(white: 0.18, alpha: 1))            // Sport
        case 2:  return .init(radiusMultiplier: 1.25, widthMultiplier: 1.40,
                              tyreColor: UIColor(red: 0.36, green: 0.25, blue: 0.16, alpha: 1)) // Offroad
        case 3:  return .init(radiusMultiplier: 1.35, widthMultiplier: 1.60,
                              tyreColor: UIColor(white: 0.22, alpha: 1))            // Heavy
        case 4:  return .init(radiusMultiplier: 1.55, widthMultiplier: 1.50,
                              tyreColor: UIColor(white: 0.12, alpha: 1))            // Monster
        case 5:  return .init(radiusMultiplier: 0.80, widthMultiplier: 0.60,
                              tyreColor: UIColor(white: 0.50, alpha: 1))            // Slim
        default: return .init(radiusMultiplier: 0.90, widthMultiplier: 0.80,
                              tyreColor: UIColor(white: 0.32, alpha: 1))            // City
        }
    }
}

private struct CarBuildState: Component {
    var lengthCm: Float
    var widthCm: Float
    var heightCm: Float
    var bodyColorId: UUID
    var tyreIndex: Int

    init(_ config: CarBuilder.Config) {
        lengthCm = config.lengthCm
        widthCm = config.widthCm
        heightCm = config.heightCm
        bodyColorId = config.bodyColorId
        tyreIndex = config.tyreIndex
    }

    func matches(_ config: CarBuilder.Config) -> Bool {
        lengthCm == config.lengthCm
            && widthCm == config.widthCm
            && heightCm == config.heightCm
            && bodyColorId == config.bodyColorId
            && tyreIndex == config.tyreIndex
    }
}
