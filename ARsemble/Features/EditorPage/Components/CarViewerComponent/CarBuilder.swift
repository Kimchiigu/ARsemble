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

    private struct WheelAsset {
        let model: ModelEntity
        let center: SIMD3<Float>
        let maxDim: Float
    }

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
        let length = config.lengthCm * unit      // X (front–back)
        let width  = config.widthCm  * unit      // Z (side–side)
        let height = config.heightCm * unit      // Y (up)

        holder.addChild(makeBody(length: length, width: width, height: height, color: config.bodyColor))
        makeEyes(length: length, width: width, height: height).forEach { holder.addChild($0) }

        let style = wheelStyle(for: config.tyreIndex)

        let mm: Float = 0.001 * displayScale
        let diameter = tyreDiameterMm(for: config.tyreIndex) * mm
        let radius = diameter / 2
        let axle = tyreWidthMm(for: config.tyreIndex) * mm

        let wheelY = -height / 2 + radius * 0.5
        let wheelX = length / 2 - radius
        let wheelZ = width / 2 + axle / 2

        for (sx, sz) in [(Float(1), Float(1)), (1, -1), (-1, 1), (-1, -1)] {
            let wheel = usdzWheel(for: config.tyreIndex, diameter: diameter)
                ?? makeWheel(radius: radius, axle: axle, style: style)
            wheel.position = [sx * wheelX, wheelY, sz * wheelZ]
            
            if sz < 0 {
                wheel.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0]) * wheel.orientation
            }

            holder.addChild(wheel)
        }

        holder.components[CarBuildState.self] = CarBuildState(config)
    }

    @MainActor static func prepareWheelAssets() async {
        guard !wheelAssetsPrepared else { return }
        wheelAssetsPrepared = true

        for index in 0..<6 {
            let name = "tyre\(index + 1)"
            do {
                let model = try await ModelEntity(named: name)
                model.transform = Transform()

                let bounds = model.visualBounds(recursive: true, relativeTo: nil)
                let dim = bounds.max - bounds.min
                let maxDim = max(dim.x, dim.y, dim.z)

                makeLitMaterials(on: model)

                wheelAssets[index] = WheelAsset(model: model, center: bounds.center, maxDim: maxDim)
            } catch {
                print("CarBuilder: ✗ failed to load wheel '\(name)': \(error)")
            }
        }
    }

    private static func usdzWheel(for index: Int, diameter: Float) -> Entity? {
        guard let asset = wheelAssets[index] else { return nil }
        
        let clone = asset.model.clone(recursive: true)
        clone.position = -asset.center

        let wrapper = Entity()
        wrapper.addChild(clone)

        let scale = asset.maxDim > 0 ? diameter / asset.maxDim : 1
        wrapper.scale = SIMD3(repeating: scale)

        wrapper.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        return wrapper
    }

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
        case 1:  return .init(tyreColor: UIColor(white: 0.18, alpha: 1))            // Sport
        case 2:  return .init(tyreColor: UIColor(red: 0.36, green: 0.25, blue: 0.16, alpha: 1)) // Offroad
        case 3:  return .init(tyreColor: UIColor(white: 0.22, alpha: 1))            // Heavy
        case 4:  return .init(tyreColor: UIColor(white: 0.12, alpha: 1))            // Monster
        case 5:  return .init(tyreColor: UIColor(white: 0.50, alpha: 1))            // Slim
        default: return .init(tyreColor: UIColor(white: 0.32, alpha: 1))            // City
        }
    }

    private static func tyreDiameterMm(for index: Int) -> Float {
        switch index {
        case 0:  return 43.2
        case 1:  return 56
        case 2:  return 94.8
        case 3:  return 105
        case 4:  return 81.6
        case 5:  return 14
        default: return 43.2
        }
    }

    private static func tyreWidthMm(for index: Int) -> Float {
        switch index {
        case 0:  return 22
        case 1:  return 28
        case 2:  return 42
        case 3:  return 60
        case 4:  return 13.6
        case 5:  return 6
        default: return 22
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
