//
//  CarSpawnSystem.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 15/08/26.
//
//  Handles the CAR PLACEMENT phase: once a surface is locked, the player drags
//  a (kinematic) car around the surface to check it fits. When they confirm,
//  the car is handed to the physics simulation (dynamic) and CarDriveSystem
//  takes over once a finish point exists.
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
                let anchor =
                    component.surfaceAnchor
            else {
                continue
            }


            let existingCar =
                anchor.children.first(
                    where: {
                        $0.name == "VirtualCar"
                    }
                ) as? ModelEntity


            if !component.carPlacementConfirmed {

                // ----------------------------------------------
                // PLACEMENT: follow the drag point (kinematic).
                // ----------------------------------------------

                guard
                    let dragPoint =
                        component.carDragPoint
                else {
                    continue
                }

                let car =
                    existingCar ??
                    makePlacementCar(in: anchor)

                // Sit just above the surface at the drag point.
                car.setPosition(
                    dragPoint +
                    SIMD3<Float>(0, 0.02, 0),
                    relativeTo: nil
                )

                // Apply the rotation the user has dialed in.
                car.setOrientation(
                    simd_quatf(
                        angle: component.carPlacementYaw,
                        axis: SIMD3<Float>(0, 1, 0)
                    ),
                    relativeTo: nil
                )

            } else if let car = existingCar {

                // ----------------------------------------------
                // CONFIRMED phase.
                // ----------------------------------------------

                // Hand the car to physics once (kinematic -> dynamic).
                if var body =
                    car.components[
                        PhysicsBodyComponent.self
                    ],
                    body.mode != .dynamic {

                    body.mode = .dynamic
                    car.components.set(body)

                    var motion =
                        car.components[
                            PhysicsMotionComponent.self
                        ]
                        ?? PhysicsMotionComponent()

                    motion.linearVelocity = .zero
                    motion.angularVelocity = .zero
                    car.components.set(motion)
                }


                // Retry Drive: put the car back at its start and re-run.
                if component.retryDriveRequested,
                   let start = component.carInitialPosition {

                    car.setPosition(
                        start + SIMD3<Float>(0, 0.02, 0),
                        relativeTo: nil
                    )

                    var motion =
                        car.components[
                            PhysicsMotionComponent.self
                        ]
                        ?? PhysicsMotionComponent()

                    motion.linearVelocity = .zero
                    motion.angularVelocity = .zero
                    car.components.set(motion)

                    component.retryDriveRequested = false
                    entity.components.set(component)
                }
            }
        }
    }


    /// Builds the car and adds it to the anchor as a KINEMATIC body so it stays
    /// exactly where it's dragged (no gravity) until placement is confirmed.
    private func makePlacementCar(
        in anchor: Entity
    ) -> ModelEntity {

        let car =
            EntityFactory.createCar(
                spec: EntityFactory.placeholderCarSpec()
            )

        car.name = "VirtualCar"

        car.components.set(
            CarComponent()
        )

        if var body =
            car.components[
                PhysicsBodyComponent.self
            ] {

            body.mode = .kinematic
            car.components.set(body)
        }

        anchor.addChild(car)

        return car
    }
}
