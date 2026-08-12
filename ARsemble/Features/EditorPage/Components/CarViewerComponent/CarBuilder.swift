//
//  CarBuilder.swift
//  ARsemble
//
//  Builds the procedural robot-car as a RealityKit entity tree. Pure data in
//  → entity tree out; it knows nothing about SwiftUI. Inspired by the reference
//  `Editor/RobotBuilder`, but rebuilt for the new models (Dimension /
//  ColorPallete / Tyre) and rendered with `UnlitMaterial` so colours show
//  exactly without any scene lighting (a non-AR RealityView has none by default).
//

import Foundation
import RealityKit
import SwiftUI
import UIKit

enum CarBuilder {

    /// Centimetres → world units. A ~18 cm car ends up roughly 0.5 units, which
    /// the RealityView default virtual camera frames comfortably.
    static let displayScale: Float = 3.0

    /// Everything `apply` needs to (re)build the car.
    struct Config: Equatable {
        let lengthCm: Float
        let widthCm: Float
        let heightCm: Float
        let bodyColor: Color
        let bodyColorId: UUID
        let tyreIndex: Int

        // Equality is by the identifying fields only — `bodyColor` (a SwiftUI
        // Color) is carried for rendering but ignored for change detection.
        static func == (lhs: Config, rhs: Config) -> Bool {
            lhs.lengthCm == rhs.lengthCm
                && lhs.widthCm == rhs.widthCm
                && lhs.heightCm == rhs.heightCm
                && lhs.bodyColorId == rhs.bodyColorId
                && lhs.tyreIndex == rhs.tyreIndex
        }
    }

    /// A visual style for a tyre, derived from the selected `Tyre`.
    private struct WheelStyle {
        let radiusMultiplier: Float
        let widthMultiplier: Float
        let tyreColor: UIColor
    }

    /// Rebuild `holder`'s children from `config`. Idempotent: if nothing
    /// changed since the last call, it returns immediately, so it is cheap to
    /// run on every SwiftUI update (e.g. during an orbit drag).
    static func apply(to holder: Entity, config: Config) {
        guard holder.components[CarBuildState.self]?.didChange(config) ?? true else { return }

        holder.children.forEach { $0.removeFromParent() }

        let unit = 0.01 * displayScale          // cm → world units
        let length = config.lengthCm * unit      // X
        let width  = config.widthCm  * unit      // Z
        let height = config.heightCm * unit      // Y

        // Body
        holder.addChild(makeBody(length: length, width: width, height: height, color: config.bodyColor))
        // Cabin / windshield on top
        holder.addChild(makeCabin(length: length, width: width, height: height))
        // Friendly robot eyes on the front face
        makeEyes(length: length, width: width, height: height).forEach { holder.addChild($0) }

        // Four wheels at the bottom corners
        let style = wheelStyle(for: config.tyreIndex)
        let baseRadius = min(min(length, width), height) * 0.24
        let radius = max(baseRadius * style.radiusMultiplier, 0.01)
        let axle = max(radius * 0.65 * style.widthMultiplier, 0.01)

        let wheelY = -height / 2 + radius * 0.5
        let wheelX = length / 2 - radius
        let wheelZ = width / 2 + axle / 2

        for (sx, sz) in [(Float(1), Float(1)), (1, -1), (-1, 1), (-1, -1)] {
            let wheel = makeWheel(radius: radius, axle: axle, style: style)
            wheel.position = [sx * wheelX, wheelY, sz * wheelZ]
            holder.addChild(wheel)
        }

        holder.components[CarBuildState.self] = CarBuildState(config)
    }

    // MARK: - Parts

    private static func makeBody(length: Float, width: Float, height: Float, color: Color) -> ModelEntity {
        let corner = min(min(length, width, height) * 0.14, 0.06)
        let mesh = MeshResource.generateBox(size: [length, height, width], cornerRadius: corner)
        return ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: UIColor(color))])
    }

    private static func makeCabin(length: Float, width: Float, height: Float) -> ModelEntity {
        let cabinLength = length * 0.5
        let cabinWidth  = width  * 0.82
        let cabinHeight = height * 0.45
        let corner = min(min(cabinLength, cabinWidth, cabinHeight) * 0.18, 0.04)
        let mesh = MeshResource.generateBox(size: [cabinLength, cabinHeight, cabinWidth], cornerRadius: corner)
        let glass = ModelEntity(
            mesh: mesh,
            materials: [UnlitMaterial(color: UIColor(red: 0.80, green: 0.89, blue: 0.98, alpha: 1))]
        )
        // Sit on the roof, nudged slightly toward the back.
        glass.position = [-length * 0.06, height / 2 + cabinHeight / 2, 0]
        return glass
    }

    private static func makeEyes(length: Float, width: Float, height: Float) -> [ModelEntity] {
        let radius = min(min(length, width), height) * 0.06
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = UnlitMaterial(color: UIColor(white: 0.98, alpha: 1))
        let x = length / 2 + radius * 0.6   // protrude slightly from the front face
        let y = height * 0.12
        let z = width * 0.2
        return [Float(-1), 1].map { sign in
            let eye = ModelEntity(mesh: mesh, materials: [material])
            eye.position = [x, y, z * sign]
            return eye
        }
    }

    /// A wheel = dark tyre cylinder + lighter hubcaps on both faces, assembled
    /// axle-along-Y then rotated so the axle lies along Z (the car's width).
    private static func makeWheel(radius: Float, axle: Float, style: WheelStyle) -> Entity {
        let group = Entity()

        let tyre = ModelEntity(
            mesh: .generateCylinder(height: axle, radius: radius),
            materials: [UnlitMaterial(color: style.tyreColor)]
        )
        group.addChild(tyre)

        let capHeight = max(axle * 0.18, 0.004)
        let capRadius = radius * 0.5
        let capMaterial = UnlitMaterial(color: UIColor(white: 0.92, alpha: 1))
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

    // MARK: - Tyre styles

    /// Map the selected tyre (by its position in the `tyres` list) to a 3D
    /// style, so each tyre option produces a visibly different wheel.
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

/// Caches the last-built config on the entity so `apply` can skip redundant
/// rebuilds (e.g. while orbit-dragging, when only the camera/zoom changed).
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

    func didChange(_ config: CarBuilder.Config) -> Bool {
        lengthCm == config.lengthCm
            && widthCm == config.widthCm
            && heightCm == config.heightCm
            && bodyColorId == config.bodyColorId
            && tyreIndex == config.tyreIndex
    }
}
