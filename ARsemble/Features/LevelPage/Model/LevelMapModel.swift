//
//  LevelMapModel.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 18/08/26.
//

import Foundation

/// One stop on the level map.
struct LevelNode: Identifiable {
    let id: Int
    let title: String
    let description: String
}

/// How a node renders on the level scroll.
enum LevelNodeState {
    case completed
    case unlocked
    case locked
}

enum LevelMap {
    static let levelsPerLesson = 5

    static let lessonTitles: [Int: String] = [
        1: "Center of Gravity",
        2: "Friction",
        3: "Momentum"
    ]

    /// Island image name per lesson — update to match your actual asset names.
    static let lessonImages: [Int: String] = [
        1: "island1",
        2: "island2",
        3: "island3"
    ]

    static let nodes: [LevelNode] = [
        LevelNode(id: 1, title: "Hill Climb",   description: "Learn about the center of gravity on an inclined plane."),
        LevelNode(id: 2, title: "Down Hill",    description: "Learn about the center of gravity on an inclined plane."),
        LevelNode(id: 3, title: "Log Disaster", description: "Learn about the center of gravity on an inclined plane."),
        LevelNode(id: 4, title: "Down Hill",    description: "Learn about the center of gravity on an inclined plane."),
        LevelNode(id: 5, title: "Log Disaster", description: "Learn about the center of gravity on an inclined plane.")
    ]
}
