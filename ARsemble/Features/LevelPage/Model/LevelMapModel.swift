//
//  LevelMapModel.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 18/08/26.
//

import CoreGraphics
import Foundation

/// One stop on the level map.
struct LevelNode: Identifiable {
    /// The level number, 1...LevelMap.levelsPerLesson.
    let id: Int

    /// Position on the map image, normalized (0...1), origin top-left.
    let position: CGPoint
}

/// How a node renders on the map.
enum LevelNodeState {
    case completed
    case unlocked
    case locked
}

enum LevelMap {
    static let levelsPerLesson = 10

    static let backgroundImageName = "level1bg"

    /// Pixel size of the background image — used to aspect-fit it and keep
    /// the nodes glued to the artwork at any scale.
    static let backgroundSize = CGSize(width: 1130, height: 652)

    static let lessonTitles: [Int: String] = [
        1: "Center of Gravity",
        2: "Friction",
        3: "Momentum"
    ]

    /// Stops along the winding path: start at the mountains (bottom-left),
    /// up the left side, loop through the middle, across the bridge, finish
    /// at the cave (top-right). First pass against the artwork — tune the
    /// coordinates by eye when the map renders on device.
    static let nodes: [LevelNode] = [
        LevelNode(id: 1,  position: CGPoint(x: 0.35, y: 0.90)),
        LevelNode(id: 2,  position: CGPoint(x: 0.25, y: 0.72)),
        LevelNode(id: 3,  position: CGPoint(x: 0.20, y: 0.55)),
        LevelNode(id: 4,  position: CGPoint(x: 0.45, y: 0.45)),
        LevelNode(id: 5,  position: CGPoint(x: 0.55, y: 0.35)),
        LevelNode(id: 6,  position: CGPoint(x: 0.65, y: 0.45)),
        LevelNode(id: 7,  position: CGPoint(x: 0.75, y: 0.55)),
        LevelNode(id: 8,  position: CGPoint(x: 0.80, y: 0.65)),
        LevelNode(id: 9,  position: CGPoint(x: 0.85, y: 0.75)),
        LevelNode(id: 10, position: CGPoint(x: 0.92, y: 0.35))
    ]
}
