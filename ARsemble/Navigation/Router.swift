//
//  Router.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 18/08/26.
//

import Foundation
import Observation

/// Every screen in the lesson flow, in push order. Associated values carry
/// the context a destination needs — the lesson/level being played, and the
/// car spec the editor built when handing off to AR.
enum Route: Hashable {
    case level(lesson: Int)
    case novel(lesson: Int, level: Int)
    case concept(lesson: Int, level: Int)
    case step(lesson: Int, level: Int)
    case editor(lesson: Int, level: Int)
    case ar(lesson: Int, level: Int, spec: CarSpecComponent)
}

/// Owns the NavigationStack path so pages can push/pop without bindings
/// being threaded through every view. Injected into the environment by
/// ContentView.
@Observable
final class Router {
    var path: [Route] = []

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    /// AR success → drop everything and land back on this lesson's level map.
    func returnToLevelMap(lesson: Int) {
        path = [.level(lesson: lesson)]
    }
}
