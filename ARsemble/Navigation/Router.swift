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
}

/// The AR screen is deliberately NOT a `Route`. Pushing it kept every earlier
/// page — including the editor's `RealityView` and the step page's capture
/// session — alive and attached underneath it, which is what left the AR
/// camera background black. Presenting it full screen instead detaches the
/// whole lesson stack from the window while AR owns the camera.
struct ARPresentation: Identifiable, Hashable {
    let id = UUID()
    let lesson: Int
    let level: Int
    let spec: CarSpecComponent
}

/// Owns the NavigationStack path so pages can push/pop without bindings
/// being threaded through every view. Injected into the environment by
/// ContentView.
@Observable
final class Router {
    var path: [Route] = []

    /// Non-nil while the AR screen is presented over the stack.
    var arPresentation: ARPresentation?

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

    /// Show the AR screen over the whole stack.
    func presentAR(lesson: Int, level: Int, spec: CarSpecComponent) {
        arPresentation = ARPresentation(
            lesson: lesson,
            level: level,
            spec: spec
        )
    }

    /// Leave AR and reveal the editor underneath again.
    func dismissAR() {
        arPresentation = nil
    }

    /// AR success → drop everything and land back on this lesson's level map.
    func returnToLevelMap(lesson: Int) {
        arPresentation = nil
        path = [.level(lesson: lesson)]
    }

    /// Back button in Step / Editor → jump straight to the level page,
    /// trimming everything pushed after it (novel, concept, step, editor…).
    func popToLevel() {
        if let idx = path.firstIndex(where: {
            if case .level = $0 { return true }
            return false
        }) {
            path = Array(path.prefix(idx + 1))
        } else {
            path.removeAll()
        }
    }
}
