//
//  CarAssemblySystem.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 13/08/26.
//

import RealityKit

struct CarAssemblySystem: System {
    static let dependencies: [SystemDependency] = []

    init(scene: Scene) {}

    mutating func update(context: SceneUpdateContext) {
        let query = EntityQuery(where: .has(CarSpecComponent.self))
        for car in context.entities(matching: query, updatingSystemWhen: .rendering) {
            guard let spec = car.components[CarSpecComponent.self] else { continue }
            if let state = car.components[CarBuildStateComponent.self], state.matches(spec) {
                continue
            }
            CarBuilder.assemble(car, spec: spec)
            car.components[CarBuildStateComponent.self] = CarBuildStateComponent(spec)
        }
    }
}
