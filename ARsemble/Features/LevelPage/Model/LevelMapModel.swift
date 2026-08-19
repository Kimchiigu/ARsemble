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

    /// Island artwork for THIS level.
    let islandImage: String

    /// Whether this level has actually been implemented
    /// and can be played.
    let isImplemented: Bool
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

    /// The levels of one lesson, in map order.
    ///
    /// Lessons without their own artwork yet fall back to lesson 1's set,
    /// so the screen still renders instead of coming up empty.
    static func nodes(for lesson: Int) -> [LevelNode] {
        lessonNodes[lesson] ?? lesson1
    }

    private static let lessonNodes: [Int: [LevelNode]] = [
        1: lesson1
    ]

    // MARK: - Lesson 1 — Center of Gravity

    private static let lesson1: [LevelNode] = [
        LevelNode(
            id: 1,
            title: "Hill Climb",
            description: "Help Arlo drive up the hill without flipping backward.",
            islandImage: "island1-1",
            isImplemented: true
        ),
        LevelNode(
            id: 2,
            title: "Down Hill",
            description: "Guide Arlo safely down the hill without tumbling.",
            islandImage: "island1-2",
            isImplemented: false
        ),
        LevelNode(
            id: 3,
            title: "Log Disaster",
            description: "Help Arlo cross logs and rocks without rolling over.",
            islandImage: "island1-3",
            isImplemented: false
        ),
        LevelNode(
            id: 4,
            title: "Tilted Trail",
            description: "Keep Arlo steady as he navigates a tilted cliffside road.",
            islandImage: "island1-4",
            isImplemented: false
        ),
        LevelNode(
            id: 5,
            title: "The Bridge",
            description: "Help Arlo cross a narrow wooden log over a deep river.",
            islandImage: "island1-5",
            isImplemented: false
        )
    ]
}
