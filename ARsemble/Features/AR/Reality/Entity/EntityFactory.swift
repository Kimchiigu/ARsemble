//
//  EntityFactory.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 12/08/26.
//
import SwiftUI
import RealityKit
struct EntityFactory {
    static func createCar(length: Float, width: Float, height: Float, color: Color) -> ModelEntity {
        let size = SIMD3<Float>(length, height, width)

        let shape = MeshResource.generateBox(size: size)
        let material = SimpleMaterial(color: UIColor(color), isMetallic: false)

        let carEntity = ModelEntity(mesh: shape, materials: [material])
        carEntity.name = "VirtualCar"

        // Collider from the body box.
        let collisionShape = ShapeResource.generateBox(size: size)
        carEntity.components.set(CollisionComponent(shapes: [collisionShape]))

        // Mass properties with a LOW centre of gravity, so the car stays
        // planted on the incline instead of tipping over while climbing.
        var massProperties = PhysicsMassProperties(shape: collisionShape, mass: 0.3)
        massProperties.centerOfMass.position = SIMD3<Float>(0, -height * 0.4, 0)

        var body = PhysicsBodyComponent(
            massProperties: massProperties,
            material: .generate(friction: 0.7, restitution: 0.0),
            mode: .dynamic
        )
        body.isAffectedByGravity = true
        carEntity.components.set(body)

        // Lets CarDriveSystem set the car's velocity each frame.
        carEntity.components.set(PhysicsMotionComponent())

        return carEntity
    }
    
    static func createObstacle(_ id: UUID, in root: Entity) -> ModelEntity {
        let entity = ModelEntity()               // invisible — the real object is already visible
        entity.name = "obstacle_\(id.uuidString)"
        entity.components.set(ObstacleComponent(meshID: id))
        root.addChild(entity)
        return entity
    }

    
}
