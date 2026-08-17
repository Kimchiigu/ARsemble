//
//  TargetSelectionSystem.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 15/08/26.
//

import RealityKit

struct TargetSelectionSystem: System {

    static let query =
        EntityQuery(
            where: .has(
                SurfaceScanComponent.self
            )
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

            // We already have a target.
            guard !component.targetLocked else {
                continue
            }

            // User hasn't tapped anything yet.
            guard let requested =
                component.requestedTargetPoint
            else {
                continue
            }

            // A surface must already be locked.
            guard component.lockedPlaneID != nil else {
                component.requestedTargetPoint = nil
                entity.components.set(component)
                continue
            }

            // -------------------------------------------------
            // LOCK TARGET
            // -------------------------------------------------

            component.targetCenter =
                requested

            component.targetLocked =
                true

            component.requestedTargetPoint =
                nil

            component.presenter?
                .reportTargetLocked()

            entity.components.set(
                component
            )
        }
    }
}
