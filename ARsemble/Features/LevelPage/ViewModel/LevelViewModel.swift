//
//  LevelViewModel.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 18/08/26.
//

import Foundation
import Observation

/// Derives each node's on-map state from the shared progress store.
/// The unlock logic itself lives in LevelProgressStore.
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

        // Level has not been implemented yet.
        // It must remain locked regardless of progress.
        guard node.isImplemented else {
            return .locked
        }

        // Completed levels remain playable so the user
        // can replay them.
        if progress.isCompleted(node.id, lesson: lesson) {
            return .completed
        }

        // Implemented and unlocked level.
        if progress.isUnlocked(node.id, lesson: lesson) {
            return .unlocked
        }

        // Implemented but not yet unlocked.
        return .locked
    }
}
