//
//  LevelProgressStore.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 18/08/26.
//

import Foundation
import Observation

/// Persists which levels the player has completed, per lesson. A level is
/// unlocked when the previous one is completed (level 1 is always unlocked).
/// Injected into the environment by ContentView; Home and LevelPage read it,
/// ContentView marks levels complete when AR reports success.
@Observable
final class LevelProgressStore {

    private static let storageKey = "levelProgress.v1"

    /// Lesson number → completed level numbers.
    private(set) var completed: [Int: Set<Int>]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: Self.storageKey),
           let stored = try? JSONDecoder().decode([Int: [Int]].self, from: data) {
            completed = stored.mapValues { Set($0) }
        } else {
            completed = [:]
        }
    }

    func isCompleted(_ level: Int, lesson: Int) -> Bool {
        completed[lesson, default: []].contains(level)
    }

    func isUnlocked(_ level: Int, lesson: Int) -> Bool {
        level <= 1 || isCompleted(level - 1, lesson: lesson)
    }

    func completedCount(lesson: Int) -> Int {
        completed[lesson]?.count ?? 0
    }

    func complete(level: Int, lesson: Int) {
        guard !isCompleted(level, lesson: lesson) else { return }
        completed[lesson, default: []].insert(level)
        persist()
    }

    /// Dev/QA convenience — clear a lesson's progress.
    func reset(lesson: Int) {
        guard completed[lesson] != nil else { return }
        completed[lesson] = nil
        persist()
    }

    private func persist() {
        let storable = completed.mapValues { Array($0).sorted() }
        if let data = try? JSONEncoder().encode(storable) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
