//
//  LevelViewModel.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 18/08/26.
//

import Foundation
import Observation

/// Derives each node's on-map state from the shared progress store. The
/// unlock logic itself lives in LevelProgressStore (single source of truth).
@Observable
final class LevelViewModel {

    /// The levels of one lesson, each carrying its own island artwork.
    func nodes(for lesson: Int) -> [LevelNode] {
        LevelMap.nodes(for: lesson)
    }

    func state(
        for node: LevelNode,
        lesson: Int,
        progress: LevelProgressStore
    ) -> LevelNodeState {
        if progress.isCompleted(node.id, lesson: lesson) {
            return .completed
        }
        return progress.isUnlocked(node.id, lesson: lesson) ? .unlocked : .locked
    }
}
