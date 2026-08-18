//
//  HomeViewModel.swift
//  ARsemble
//
//  Created by Catherine Danielle on 12/08/26.
//

import Foundation
import Observation

/// VIEWMODEL — owns the lesson list for the home carousel. Completion counts
/// and the locked state come from `LevelProgressStore` in the view.
@Observable
final class HomeViewModel {
    private(set) var lessons: [HomeModel]

    init(lessons: [HomeModel] = HomeViewModel.sample) {
        self.lessons = lessons
    }

    /// Three lessons -> the carousel loops 1 -> 2 -> 3 -> 1 ...
    static let sample: [HomeModel] = [
        HomeModel(lessonNumber: 1, title: "Center of Gravity", imageName: "island1", levelCount: 10),
        HomeModel(lessonNumber: 2, title: "Friction",          imageName: "island2", levelCount: 10),
        HomeModel(lessonNumber: 3, title: "Momentum",          imageName: "island2", levelCount: 10)
    ]
}
