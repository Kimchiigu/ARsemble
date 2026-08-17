//
//  CarSpawnSystem.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 15/08/26.
//
import RealityKit
import ARKit

struct CarSpawnSystem: System {

    static let query =
        EntityQuery(
            where: .has(SurfaceScanComponent.self)
        )


    init(scene: RealityKit.Scene) {}


    func update(
        context: SceneUpdateContext
    ) {

        for entity in context.entities(
            matching: Self.query,
            updatingSystemWhen: .rendering
        ) {

            guard var component =
                entity.components[
                    SurfaceScanComponent.self
                ]
            else {
                continue
            }


            guard
                component.spawnCarRequested,
                let anchor =
                    component.surfaceAnchor
            else {
                continue
            }


            // Remove previous car.
            anchor.children
                .filter {
                    $0.name == "VirtualCar"
                }
                .forEach {
                    $0.removeFromParent()
                }


            let car =
                EntityFactory.createCar(
                    length: 0.12,
                    width: 0.07,
                    height: 0.04,
                    color: .red
                )


            car.name =
                "VirtualCar"


            // Wire the car's goal to the finish point placed earlier.
            var carComponent =
                CarComponent()

            carComponent.target =
                component.finishTarget

            car.components.set(
                carComponent
            )


            if let spawn =
                component.carSpawnPoint {

                car.setPosition(
                    spawn +
                    SIMD3<Float>(
                        0,
                        0.02,
                        0
                    ),
                    relativeTo: nil
                )

            } else {

                car.position =
                    SIMD3<Float>(
                        0,
                        0.02,
                        0
                    )
            }


            anchor.addChild(
                car
            )


            component.spawnCarRequested =
                false

            component.carSpawnPoint =
                nil


            entity.components.set(
                component
            )
        }
    }
}
